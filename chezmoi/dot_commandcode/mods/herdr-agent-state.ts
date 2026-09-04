// herdr agent-state mod for Command Code
// Mirrors ~/code/ai-agents-configs/pi-extensions/herdr-agent-state.ts
// Transport, seq/queue/drain, and dedup logic are ported 1:1 from the pi
// extension. Event wiring is Command Code's ModApi (the `cmd` surface).
//
// Signals the state of THIS Command Code session to herdr's pane:
//   working  : between run_start and run_end
//   blocked  : three sources, in priority order —
//              1. Cooperative: ask-tools (socrates) emit herdr:blocked on the
//                 cross-mod bus (the reliable path, mirroring pi).
//              2. Builtin ask_user_question tool in flight (modal open during
//                 tool_running → tool_completed/tool_errored).
//              3. Best-effort heuristic: a permission-gated tool (shell/write)
//                 is queued awaiting run/deny. Noisy by design.
//   idle     : none of the above
//
// Managed by herdr via the standard mods surface. Import type only — jiti
// erases it at load; no build step.

import type {ModApi} from "@commandcode/harness";
import net from "node:net";

// ── Transport: herdr socket (ported verbatim from the pi extension) ─────────
const HERDR_ENV = process.env.HERDR_ENV;
const socketPath = process.env.HERDR_SOCKET_PATH;
const socketEndpoint =
  process.platform === "win32" && socketPath ? `\\\\.\\pipe\\${socketPath}` : socketPath;
const paneId = process.env.HERDR_PANE_ID;
const source = "custom:commandcode";
const agent = "commandcode";

// Permission-gated tools — the ones the model calling them actually blocks on
// a permission prompt for. Only these drive the best-effort `blocked` state.
const GATING_TOOLS = new Set(["shell_command", "write_file", "edit_file"]);

// The builtin question tool: auto-allowed (no permission wait), so its blocked
// window is DURING execution — tool_running (modal opens) → tool_completed /
// tool_errored (user answered). The opposite of the gating tools above.
const ASK_TOOL = "ask_user_question";

function enabled(): boolean {
  return HERDR_ENV === "1" && !!socketPath && !!paneId;
}

function sendRequestAttempt(request: unknown, timeoutMs: number): Promise<boolean> {
  if (!enabled()) {
    return Promise.resolve(true);
  }
  return new Promise((resolve) => {
    let done = false;
    let timeout: ReturnType<typeof setTimeout> | undefined;
    const finish = (delivered: boolean) => {
      if (done) return;
      done = true;
      if (timeout) clearTimeout(timeout);
      socket.destroy();
      resolve(delivered);
    };
    const socket = net.createConnection(socketEndpoint!);
    socket.on("error", () => finish(false));
    socket.on("connect", () => socket.write(`${JSON.stringify(request)}\n`));
    socket.on("data", () => finish(true));
    socket.on("end", () => finish(false));
    timeout = setTimeout(() => finish(false), timeoutMs);
    timeout.unref?.();
  });
}

async function sendRequest(request: unknown): Promise<void> {
  if (await sendRequestAttempt(request, 500)) return;
  await sendRequestAttempt(request, 1500);
}

type AgentState = "working" | "blocked" | "idle";

type QueuedState = {
  state: AgentState;
  message?: string;
  seq: number;
};

let reportSeq = Date.now() * 1000;
let currentAgentSessionId: string | undefined;

function nextReportSeq(): number {
  reportSeq += 1;
  return reportSeq;
}

function updateSessionRef(cmd: ModApi): void {
  try {
    const id = cmd.sessions.leafId();
    currentAgentSessionId = typeof id === "string" && id.length > 0 ? id : undefined;
  } catch {
    currentAgentSessionId = undefined;
  }
}

function withSessionRef(params: Record<string, unknown>): Record<string, unknown> {
  if (currentAgentSessionId) {
    return {...params, agent_session_id: currentAgentSessionId};
  }
  return params;
}

function currentSessionRef(): Record<string, unknown> | undefined {
  if (currentAgentSessionId) {
    return {agent_session_id: currentAgentSessionId};
  }
  return undefined;
}

function reportSession(sessionStartSource?: string): Promise<void> {
  const sessionRef = currentSessionRef();
  if (!sessionRef) return Promise.resolve();
  return sendRequest({
    id: `${source}:session:${Date.now()}:${Math.random().toString(36).slice(2)}`,
    method: "pane.report_agent_session",
    params: {
      pane_id: paneId,
      source,
      agent,
      seq: nextReportSeq(),
      session_start_source: sessionStartSource,
      ...sessionRef,
    },
  });
}

function sendState(state: AgentState, message?: string, seq = nextReportSeq()): Promise<void> {
  return sendRequest({
    id: `${source}:${Date.now()}:${Math.random().toString(36).slice(2)}`,
    method: "pane.report_agent",
    params: withSessionRef({
      pane_id: paneId,
      source,
      agent,
      state,
      message,
      seq,
    }),
  });
}

let sendInFlight = false;
let queuedState: QueuedState | undefined;

function queueState(state: AgentState, message?: string): void {
  queuedState = {state, message, seq: nextReportSeq()};
  if (!sendInFlight) void drainStateQueue();
}

async function drainStateQueue(): Promise<void> {
  if (sendInFlight) return;
  sendInFlight = true;
  try {
    while (queuedState) {
      const next = queuedState;
      queuedState = undefined;
      await sendState(next.state, next.message, next.seq);
    }
  } finally {
    sendInFlight = false;
    if (queuedState) void drainStateQueue();
  }
}

export default function (cmd: ModApi): void {
  if (!enabled()) return;

  let agentActive = false;
  // Cooperative blocked signal: ask-tools (socrates) emit herdr:blocked on the
  // cross-mod bus. Keyed by label so concurrent ask sites don't mis-clear.
  const blockedLabels = new Set<string>();
  // Builtin ask_user_question in flight (modal open, awaiting the user).
  const askInFlight = new Set<string>();
  // Gating calls pending approval, keyed by toolCallId (best-effort heuristic).
  const pendingApproval = new Set<string>();
  let lastState: AgentState | undefined;
  let lastMessage: string | undefined;
  let sessionReported = false;

  function desiredState(): {state: AgentState; message?: string} {
    if (blockedLabels.size > 0) {
      return {state: "blocked", message: `awaiting: ${[...blockedLabels].join(", ")}`};
    }
    if (askInFlight.size > 0) {
      return {state: "blocked", message: "awaiting answer"};
    }
    if (pendingApproval.size > 0) {
      return {state: "blocked", message: "waiting on approval"};
    }
    if (agentActive) {
      return {state: "working"};
    }
    return {state: "idle"};
  }

  function publishState(force = false): void {
    const next = desiredState();
    if (!force && next.state === lastState && next.message === lastMessage) return;
    lastState = next.state;
    lastMessage = next.message;
    queueState(next.state, next.message);
  }

  // Cooperative blocked channel: ask-tools (socrates) emit herdr:blocked via
  // the cross-mod bus. Mirror of pi's pi.events.on("herdr:blocked", ...).
  cmd.events.on("herdr:blocked", (data) => {
    const active = data?.active === true;
    const label = typeof data?.label === "string" && data.label.length > 0
      ? data.label
      : "user";
    if (active) {
      blockedLabels.add(label);
    } else {
      blockedLabels.delete(label);
    }
    publishState();
  });

  // Session bind / teardown.
  cmd.on("session_start", () => {
    updateSessionRef(cmd);
    if (!sessionReported) {
      sessionReported = true;
      void reportSession();
    }
    agentActive = false;
    publishState(true);
  });

  cmd.on("session_shutdown", () => {
    // Reset per-session state; a subsequent bind re-reports.
    sessionReported = false;
    currentAgentSessionId = undefined;
    blockedLabels.clear();
    askInFlight.clear();
    pendingApproval.clear();
  });

  // Working ↔ idle are run-bound.
  cmd.on("run_start", () => {
    agentActive = true;
    publishState();
  });

  cmd.on("run_end", () => {
    agentActive = false;
    publishState();
  });

  // Best-effort blocked: a gating tool was emitted for approval. Track by
  // toolCallId so parallel/interleaved tool events can't mis-clear.
  cmd.on("tool_queued", (payload) => {
    const toolName = payload?.toolName;
    const toolCallId = payload?.toolCallId;
    if (!toolName || !toolCallId || !GATING_TOOLS.has(toolName)) return;
    pendingApproval.add(toolCallId);
    publishState();
  });

  // The builtin ask_user_question is auto-allowed, so its blocked window is
  // DURING execution: tool_running (modal opens) → tool_completed/errored.
  cmd.on("tool_running", (payload) => {
    const toolName = payload?.toolName;
    const toolCallId = payload?.toolCallId;
    if (toolName === ASK_TOOL && toolCallId) {
      askInFlight.add(toolCallId);
      publishState();
      return;
    }
    // A gating tool that ran (approved) — clear just that id.
    if (toolCallId && pendingApproval.delete(toolCallId)) publishState();
  });

  cmd.on("tool_completed", (payload) => {
    const toolCallId = payload?.toolCallId;
    if (toolCallId && askInFlight.delete(toolCallId)) publishState();
  });

  cmd.on("tool_errored", (payload) => {
    const toolCallId = payload?.toolCallId;
    if (toolCallId && askInFlight.delete(toolCallId)) publishState();
  });

  // Denied / hook-blocked are terminal for their call. tool_denied fires per
  // denied call (batch aborts); tool_hook_blocked carries no id, so clear-all
  // is the conservative choice there (hook-blocked is terminal per call, but
  // we can't match an id — treat it as a full reset).
  cmd.on("tool_denied", (payload) => {
    const toolCallId = payload?.toolCallId;
    if (toolCallId) {
      if (pendingApproval.delete(toolCallId) || askInFlight.delete(toolCallId)) {
        publishState();
      }
      return;
    }
    if (pendingApproval.size > 0 || askInFlight.size > 0) {
      pendingApproval.clear();
      askInFlight.clear();
      publishState();
    }
  });
  cmd.on("tool_hook_blocked", () => {
    if (pendingApproval.size > 0 || askInFlight.size > 0) {
      pendingApproval.clear();
      askInFlight.clear();
      publishState();
    }
  });
}
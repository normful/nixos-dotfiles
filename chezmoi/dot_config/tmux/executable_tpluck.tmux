#!/usr/bin/env bash
#
# tpluck.tmux — three modes of operation:
#
#   Setup (no args)
#     Called by `run-shell` from tmux.conf on load.
#     Registers the keybinding (@tpluck-key) via `bind-key` → `run-shell`.
#
#   Open  (arg 1 = "open")
#     Fired by the keybinding. Runs outside the popup, in the context of the
#     pane that was active when you pressed the key. Captures #{pane_id} via
#     display-message -p, then opens the floating display-popup.
#
#   Popup (arg 1 = "popup", arg 2 = pane_id)
#     Runs inside the floating popup terminal. Captures the target pane's
#     visible content, pipes through tpluck TUI for interactive selection,
#     copies result to clipboard + tmux buffer.
#
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TPLUCK_CONF="${SCRIPT_DIR}/tpluck.toml"
readonly TPLUCK_BIN="tpluck"

# ── Open mode: called by run-shell bind → captures pane_id, opens popup ─────
if [ "${1:-}" = "open" ]; then
  target_pane="$(tmux display-message -p '#{pane_id}')"
  tmux display-popup -B -w 100% -h 100% -E \
    "${SCRIPT_DIR}/tpluck.tmux popup '${target_pane}'"
  exit 0
fi

# ── Popup mode: runs inside display-popup ────────────────────────────────────
if [ "${1:-}" = "popup" ]; then
  target_pane="${2:-}"
  if [ -z "${target_pane}" ]; then
    exit 1
  fi
  selection="$(tmux capture-pane -pt "${target_pane}" | "${TPLUCK_BIN}" -n -f "${TPLUCK_CONF}" || true)"
  if [ -n "${selection}" ]; then
    printf '%s' "${selection}" | pbcopy
    printf '%s' "${selection}" | tmux load-buffer -
    tmux display-message -d 3000 "${selection} copied to clipboard"
  fi
  exit 0
fi

# ── Setup mode: called by run-shell from tmux.conf ──────────────────────────
DEFAULT_TPLUCK_KEY=t
TPLUCK_KEY="$(tmux show-option -gqv @tpluck-key)"
TPLUCK_KEY=${TPLUCK_KEY:-$DEFAULT_TPLUCK_KEY}

tmux bind-key -T prefix "${TPLUCK_KEY}"           run-shell "${SCRIPT_DIR}/tpluck.tmux open"
tmux bind-key -T prefix "M-l"                        run-shell "${SCRIPT_DIR}/tpluck.tmux open"
tmux bind-key -T root  "F2"                          run-shell "${SCRIPT_DIR}/tpluck.tmux open"

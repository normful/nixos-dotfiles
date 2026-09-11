# lean-ctx shell hook — smart shell mode (track-by-default)
set -g _lean_ctx_cmds git gh cargo npm pnpm yarn bun bunx deno vite pip pip3 pytest mypy ruff go golangci-lint docker docker-compose kubectl helm aws terraform tofu eslint prettier tsc biome curl wget php composer dotnet bundle rake mix swift zig cmake make rg cat head tail ls find

function _lc_is_agent
	set -q LEAN_CTX_AGENT; or set -q CODEX_CLI_SESSION; or set -q CLAUDECODE; or set -q GEMINI_SESSION
end

function _lc
	if set -q LEAN_CTX_DISABLED; or set -q LEAN_CTX_NO_HOOK
		command $argv
		return
	end
	if not isatty stdout; and not _lc_is_agent
		command $argv
		return
	end
	command lean-ctx -t $argv
	set -l _lc_rc $status
	if test $_lc_rc -eq 127 -o $_lc_rc -eq 126
		command $argv
	else
		return $_lc_rc
	end
end

function _lc_compress
	if set -q LEAN_CTX_DISABLED; or set -q LEAN_CTX_NO_HOOK
		command $argv
		return
	end
	if not isatty stdout; and not _lc_is_agent
		command $argv
		return
	end
	command lean-ctx -c $argv
	set -l _lc_rc $status
	if test $_lc_rc -eq 127 -o $_lc_rc -eq 126
		command $argv
	else
		return $_lc_rc
	end
end

function lean-ctx-on
	for _lc_cmd in $_lean_ctx_cmds
		alias $_lc_cmd '_lc '$_lc_cmd
	end
	alias k '_lc kubectl'
	set -gx LEAN_CTX_ENABLED 1
	isatty stdout; and echo 'lean-ctx: ON (track mode — output unchanged, token savings recorded)'
end

function lean-ctx-off
	for _lc_cmd in $_lean_ctx_cmds
		functions --erase $_lc_cmd 2>/dev/null; true
	end
	functions --erase k 2>/dev/null; true
	set -e LEAN_CTX_ENABLED
	isatty stdout; and echo 'lean-ctx: OFF'
end

function lean-ctx-mode
	switch $argv[1]
		case compress
			for _lc_cmd in $_lean_ctx_cmds
				alias $_lc_cmd '_lc_compress '$_lc_cmd
				end
			alias k '_lc_compress kubectl'
			set -gx LEAN_CTX_ENABLED 1
			isatty stdout; and echo 'lean-ctx: COMPRESS mode (all output compressed)'
		case track
			lean-ctx-on
		case off
			lean-ctx-off
		case '*'
			echo 'Usage: lean-ctx-mode <track|compress|off>'
			echo '  track    — Full output, stats recorded (default)'
			echo '  compress — Compressed output for all commands'
			echo '  off      — No aliases, raw shell'
	end
end

function lean-ctx-raw
	set -lx LEAN_CTX_RAW 1
	command $argv
end

function lean-ctx-status
	if set -q LEAN_CTX_DISABLED
		isatty stdout; and echo 'lean-ctx: DISABLED (LEAN_CTX_DISABLED is set)'
	else if set -q LEAN_CTX_ENABLED
		isatty stdout; and echo 'lean-ctx: ON'
	else
		isatty stdout; and echo 'lean-ctx: OFF'
	end
end

function _lean_ctx_should_activate
	if set -q LEAN_CTX_ACTIVE; or set -q LEAN_CTX_DISABLED; or test (set -q LEAN_CTX_ENABLED; and echo $LEAN_CTX_ENABLED; or echo 1) = '0'
		return 1
	end
	set -l _lc_mode (set -q LEAN_CTX_SHELL_ACTIVATION; and echo $LEAN_CTX_SHELL_ACTIVATION; or echo 'always')
	switch $_lc_mode
		case off none manual
			return 1
		case 'agents-only' agents_only agentsonly
			if set -q LEAN_CTX_AGENT; or set -q CLAUDECODE; or set -q CODEX_CLI_SESSION; or set -q GEMINI_SESSION
				return 0
			end
			return 1
		case '*'
			return 0
	end
end

if _lean_ctx_should_activate
	if command -q lean-ctx
		lean-ctx-on
	end
end

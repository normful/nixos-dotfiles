#!/bin/bash
# move-mp3s-watch.sh - Watches ~/Downloads and runs move-mp3s.sh on changes
# Enhanced with logging, timestamps, and better error handling

set -euo pipefail

# Add NixOS system bin directory to PATH
export PATH="/run/current-system/sw/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="${XDG_RUNTIME_DIR:-$HOME/.local/log}/move-mp3s-watch.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function with timestamps
log() {
    local level="$1"
    shift
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $*" | tee -a "$LOG_FILE"
}

log_info()  { log "INFO"  "$@"; }
log_warn()  { log "WARN"  "$@"; }
log_error() { log "ERROR" "$@"; }

# Cleanup handler for clean shutdown
cleanup() {
    log_info "=== Watcher stopped ==="
    exit 0
}
trap cleanup SIGINT SIGTERM

log_info "=== Watcher started (PID: $$) ==="
log_info "Log file: $LOG_FILE"
log_info "Press Ctrl+C to stop"

# Check dependencies
for cmd in fswatch xargs; do
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command '$cmd' not found"
        exit 1
    fi
done

# Verify move-mp3s.sh exists
if [[ ! -x "$SCRIPT_DIR/move-mp3s.sh" ]]; then
    log_error "move-mp3s.sh not found or not executable at: $SCRIPT_DIR/move-mp3s.sh"
    exit 1
fi

WATCH_DIR="$HOME/Downloads"
if [[ ! -d "$WATCH_DIR" ]]; then
    log_error "Watch directory does not exist: $WATCH_DIR"
    exit 1
fi

log_info "Watching: $WATCH_DIR"

# Track statistics
EVENT_COUNT=0
PROCESSED_COUNT=0

# Run fswatch and process events
while true; do
    fswatch -o --latency 20.0 "$WATCH_DIR" | while read -r || true; do
        EVENT_COUNT=$((EVENT_COUNT + 1))
        log_info "Change detected (event #$EVENT_COUNT)"

    if RESULT=$("$SCRIPT_DIR/move-mp3s.sh" 2>&1); then
        if [[ -n "$RESULT" ]]; then
            echo "$RESULT" | while IFS= read -r line; do
                log_info "MOVED: $line"
            done
            PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
            log_info "Files moved successfully"
        else
            log_info "No files needed moving"
        fi
    else
        log_error "move-mp3s.sh failed with exit code: $?"
        log_error "Output: $RESULT"
    fi

    log_info "--- Summary: Events: $EVENT_COUNT | Files processed: $PROCESSED_COUNT ---"
    done
done

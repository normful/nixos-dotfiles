#!/bin/bash
# move-mp3s.sh - Moves large MP3s from ~/Downloads to ~/Music by month
# Enhanced with timestamps, summary logging, and better error handling

set -euo pipefail

# Add NixOS system bin directory to PATH
export PATH="/run/current-system/sw/bin:$PATH"

# Configuration
DEST_BASE="$HOME/Music"
DOWNLOADS="$HOME/Downloads"
MIN_SIZE_MB=30
LOG_FILE="${XDG_RUNTIME_DIR:-$HOME/.local/log}/move-mp3s.log"

# Logging
log() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $*" | tee -a "$LOG_FILE"
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log "=== Starting MP3 move process ==="

# Verify GNU stat is available
if ! stat -c "%Y" "$HOME" >/dev/null 2>&1; then
    log "ERROR: GNU stat (coreutils) is required. Install with: brew install coreutils"
    exit 1
fi

# Check directories exist
if [[ ! -d "$DOWNLOADS" ]]; then
    log "ERROR: Downloads directory does not exist: $DOWNLOADS"
    exit 1
fi

if [[ ! -d "$DEST_BASE" ]]; then
    log "WARN: Music directory does not exist, creating: $DEST_BASE"
    mkdir -p "$DEST_BASE"
fi

# Find files to process
log "Finding MP3 files >${MIN_SIZE_MB}MB in $DOWNLOADS..."
FILES_FOUND=0
MOVED_COUNT=0
ERROR_COUNT=0

while IFS= read -r -d '' file; do
    FILES_FOUND=$((FILES_FOUND + 1))
    filename=$(basename "$file")
    log "Processing: $filename"

    # Get modification date (GNU stat)
    mod_date=$(stat -c "%Y" "$file")
    year=$(date -d "@$mod_date" +%Y)
    month_num=$(date -d "@$mod_date" +%m)
    month=$(date -d "@$mod_date" +%B)

    # Create destination folder
    dest_dir="$DEST_BASE/Music-$year-$month_num-$month"
    mkdir -p "$dest_dir"

    dest_file="$dest_dir/$filename"

    # Handle filename collisions
    if [[ -e "$dest_file" ]]; then
        if [[ "$(stat -c "%Y" "$file")" -eq "$(stat -c "%Y" "$dest_file")" ]]; then
            log "  SKIP: Already exists: $dest_file"
            continue
        else
            timestamp=$(date '+%Y%m%d-%H%M%S')
            dest_file="${dest_dir}/${timestamp}_$filename"
            log "  RENAMED: Collision -> ${timestamp}_$filename"
        fi
    fi

    # Move the file
    if mv "$file" "$dest_file"; then
        file_size=$(du -h "$dest_file" | cut -f1)
        log "  → Moved: $dest_file ($file_size)"
        MOVED_COUNT=$((MOVED_COUNT + 1))
    else
        log "  ERROR: Failed to move $file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
done < <(find "$DOWNLOADS" -maxdepth 1 -type f -name "*.mp3" -size +${MIN_SIZE_MB}M -print0)

if [[ $FILES_FOUND -eq 0 ]]; then
    log "No MP3 files >${MIN_SIZE_MB}MB found"
    log "=== Done ==="
    exit 0
fi

log "=== Summary: Processed: $FILES_FOUND | Moved: $MOVED_COUNT | Errors: $ERROR_COUNT ==="

# Exit with error if any failures
if [[ $ERROR_COUNT -gt 0 ]]; then
    exit 1
fi
exit 0

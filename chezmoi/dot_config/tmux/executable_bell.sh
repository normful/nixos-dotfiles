#!/usr/bin/env bash
# Bell notification with grouping
# Groups rapid alerts together to prevent notification spam
#
# Flow:
#   Alert 1 ──mkdir lock──► Got lock? Append queue, sleep 2s
#   Alert 2 ──mkdir lock──► Lock held?  Append queue, exit (Alert 1 handles popup)
#
#   After sleep: sort -u (dedupe) → awk (group by session) → show popup → cleanup

SESSION="$1"
WINDOW="$2"

LOCK="/tmp/tmux-bell.lock"
QUEUE="/tmp/tmux-bell.queue"

# Prevent multiple instances from spawning popups
if ! mkdir "$LOCK" 2>/dev/null; then
    echo "$SESSION:$WINDOW" >> "$QUEUE"
    exit 0
fi

trap 'rmdir "$LOCK"; rm -f "$QUEUE"' EXIT

# Append current alert
echo "$SESSION:$WINDOW" >> "$QUEUE"

# Wait briefly for other alerts to group
sleep 2

# Dedupe and group by session
# Input:  main:1 main:3 dev:2
# Output: main:1,3 dev:2
ALERTS=$(sort -u "$QUEUE" | awk -F: '{s[$1]=s[$1]?s[$1]","$2:$2} END {for(k in s) printf "%s:%s ", k, s[k]}' | sed 's/ $//')
COUNT=$(wc -l < "$QUEUE")

if [ "$COUNT" -eq 1 ]; then
    tmux display-popup -k -b rounded -xP -yP -w40 -h3 -t. "echo '◎  $ALERTS'"
else
    tmux display-popup -k -b rounded -xP -yP -w50 -h3 -t. "echo '◎  $ALERTS'"
fi

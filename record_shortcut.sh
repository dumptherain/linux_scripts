#!/usr/bin/env bash
set -euo pipefail

PID_FILE="/tmp/record_shortcut_terminal.pid"
RECORD_SCRIPT="/home/mini2/linux_scripts/record.sh"
RECORD_DIR="$HOME/Videos/recording"
TERMINAL="x-terminal-emulator"

# If already recording, stop
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "🔴 Stopping recording..."
  notify-send "Recording stopped" "Saved to: $RECORD_DIR"
  kill "$(cat "$PID_FILE")" && rm -f "$PID_FILE"
  exit 0
fi

# Start recording
echo "🟢 Starting recording..."
notify-send "Recording started" "Press shortcut again to stop."

# Launch terminal and run record.sh
$TERMINAL -e bash -c "\"$RECORD_SCRIPT\" \"$RECORD_DIR\"" &

# Give it a second to launch
sleep 1

# Get the actual terminal PID running the script
TERMINAL_PID=$(pgrep -f "$TERMINAL.*$RECORD_SCRIPT" | head -n 1)

if [[ -n "$TERMINAL_PID" ]]; then
  echo "$TERMINAL_PID" > "$PID_FILE"
else
  echo "⚠️ Failed to find terminal PID. Cleanup may not work." >&2
fi


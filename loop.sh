#!/bin/bash
# loop.sh — repeat a video N times without re-encoding
# Usage: ./loop.sh -4 input.mp4  → input_loop4.mp4

set -euo pipefail

if [[ $# -lt 2 || ! "${1:-}" =~ ^-[0-9]+$ ]]; then
  echo "Usage: $0 -N inputfile"; exit 1
fi

COUNT="${1#-}"
INPUT="$2"
[[ -f "$INPUT" ]] || { echo "Input not found: $INPUT"; exit 1; }

# Absolute path to input (so FFmpeg resolves correctly from /tmp)
if command -v realpath >/dev/null 2>&1; then
  ABSIN="$(realpath -e "$INPUT")"
else
  ABSIN="$(python3 - <<'PY'
import os,sys; print(os.path.abspath(sys.argv[1]))
PY
  "$INPUT")"
fi

BASENAME="${INPUT%.*}"
EXT="${INPUT##*.}"
OUTPUT="${BASENAME}_loop${COUNT}.${EXT}"

TMPFILE="$(mktemp)"
trap 'rm -f "$TMPFILE"' EXIT

# Write concat list with absolute paths, correctly quoted
for ((i=1; i<=COUNT; i++)); do
  printf "file '%s'\n" "$ABSIN" >> "$TMPFILE"
done

# Concatenate without re-encoding
ffmpeg -y -f concat -safe 0 -i "$TMPFILE" -c copy "$OUTPUT"

echo "✅ Created: $OUTPUT"


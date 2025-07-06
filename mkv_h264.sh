#!/bin/bash
# Deploys scripts with `# @nemo` tag to Nemo's right-click menu

set -euo pipefail

# Check for input
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <input.mkv>"
  exit 1
fi

input="$1"
base="$(basename "${input%.*}")"
OUT_DIR="$(dirname "$input")/h264_output"
mkdir -p "$OUT_DIR"
output="${OUT_DIR}/${base}.mov"

echo "Converting (H.264 NVENC): $input → $output"

ffmpeg -hwaccel nvdec -i "$input" \
  -c:v h264_nvenc -preset p4 -profile:v high -b:v 25M \
  -c:a aac -b:a 192k \
  "$output"

notify-send "✅ H.264 Conversion Done" "$base → h264_output/"


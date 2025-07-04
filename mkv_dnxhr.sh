#!/bin/bash

set -euo pipefail

# Check for input
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <input.mkv>"
  exit 1
fi

input="$1"
base="$(basename "${input%.*}")"
OUT_DIR="$(dirname "$input")/dnxhr_output"
mkdir -p "$OUT_DIR"
output="${OUT_DIR}/${base}.mov"

echo "Converting: $input → $output"

ffmpeg -threads "$(nproc)" -i "$input" \
  -c:v dnxhd -profile:v dnxhr_hq -pix_fmt yuv422p \
  -c:a pcm_s16le \
  "$output"

notify-send "✅ DNxHR Conversion Done" "$base → dnxhr_output/"


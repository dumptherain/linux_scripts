#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <input-video>"
  exit 1
fi

input="$1"
if [[ ! -f "$input" ]]; then
  echo "Error: file '$input' not found."
  exit 2
fi

# derive output filename by replacing extension with .mov
base="${input%.*}"
output="${base}.mov"

# ffmpeg conversion:
# - video: Apple ProRes 422 (profile 3), 10-bit 4:2:2
# - audio: uncompressed PCM 48 kHz, 16-bit little-endian
ffmpeg -y -i "$input" \
  -c:v prores_ks \
  -profile:v 3 \
  -vendor ap10 \
  -pix_fmt yuv422p10le \
  -c:a pcm_s16le \
  -ar 48000 \
  "$output"

echo "Converted '$input' → '$output'"


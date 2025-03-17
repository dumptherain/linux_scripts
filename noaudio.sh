#!/bin/bash
# Check for input argument
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <input_video>"
  exit 1
fi

input="$1"

# Verify file exists
if [ ! -f "$input" ]; then
  echo "Error: File '$input' not found."
  exit 1
fi

# Extract base filename and extension
filename="${input%.*}"
extension="${input##*.}"

# Construct output filename with '_noaudio' suffix
output="${filename}_noaudio.${extension}"

# Remove audio stream and copy video stream without re-encoding
ffmpeg -i "$input" -c copy -an "$output"


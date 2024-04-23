#!/bin/bash

# Check if the input argument (filename) is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 filename.mp4"
    exit 1
fi

# Extract the filename without its extension
input_file="$1"
output_file="${input_file%.*}.wav"

# Use ffmpeg to extract audio and convert it to WAV format
ffmpeg -i "$input_file" -vn -ar 44100 -ac 2 -b:a 192k -f wav "$output_file"

echo "Extraction complete. Output file: $output_file"

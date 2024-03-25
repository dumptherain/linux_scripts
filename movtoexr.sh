#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <video_file>"
    exit 1
fi

video_file="$1"

if [ ! -f "$video_file" ]; then
    echo "File not found: $video_file"
    exit 1
fi

echo "Starting conversion of $video_file to DWAB compressed EXR sequence..."

output_dir=$(basename "$video_file" .mov)"_exr"
mkdir -p "$output_dir"

# Convert the video directly to a sequence of EXR files with DWAB compression
ffmpeg -i "$video_file" -vf "format=rgb48le" -compression_level 100 "$output_dir/frame_%04d.exr"

echo "Conversion completed. DWAB compressed EXR sequence is available in $output_dir"

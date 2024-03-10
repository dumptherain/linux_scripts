#!/bin/bash

# Check if an argument (video file name) is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <video file>"
    exit 1
fi

# Get the video file name from the argument
video_file="$1"

# Check if the file exists
if [ ! -f "$video_file" ]; then
    echo "File not found: $video_file"
    exit 1
fi

# Extract the filename without extension
filename=$(basename "$video_file" | cut -d. -f1)

# Create a directory for the PNG sequence
output_dir="${filename}_png"
mkdir -p "$output_dir"

# Convert the video to a PNG sequence
ffmpeg -i "$video_file" -vf fps=24 "$output_dir/${filename}_%04d.png"

echo "PNG sequence is saved in $output_dir"

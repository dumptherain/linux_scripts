#!/bin/bash

# Create the output directory if it doesn't already exist
mkdir -p mp4_web

# Function to process a single video file
convert_video() {
    local file=$1
    local filename=$(basename "$file")
    local extension="${filename##*.}"
    local filename_without_ext="${filename%.*}"

    # Define the output filename
    local output="mp4_web/${filename_without_ext}_web.mp4"

    # Execute FFmpeg command with the desired settings
    ffmpeg -i "$file" -vcodec libx264 -preset veryslow -crf 23 -vf "scale=-2:1080" -acodec aac -b:a 128k "$output"

    echo "Converted $file to $output"
}

# Check if specific filenames are provided as arguments
if [ $# -gt 0 ]; then
    # Process each file provided as an argument
    for file in "$@"; do
        if [ -f "$file" ]; then
            convert_video "$file"
        else
            echo "File $file not found."
        fi
    done
else
    # Process all video files in the current directory if no arguments are provided
    for file in *; do
        if [[ $(file --mime-type -b "$file") =~ ^video/ ]]; then
            convert_video "$file"
        fi
    done
fi

echo "Conversion completed."

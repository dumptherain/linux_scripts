#!/bin/bash

# Function to extract the first image of a video file
extract_thumbnail() {
    local file=$1
    local filename=$(basename "$file")
    local filename_without_ext="${filename%.*}"
    local output="${filename_without_ext}_thumbnail.jpg"

    # Execute FFmpeg command to extract the first frame
    ffmpeg -i "$file" -frames:v 1 "$output"

    echo "Extracted thumbnail for $file as $output"
}

# Check if specific filenames are provided as arguments
if [ $# -gt 0 ]; then
    # Process each file provided as an argument
    for file in "$@"; do
        if [ -f "$file" ]; then
            extract_thumbnail "$file"
        else
            echo "File $file not found."
        fi
    done
else
    # Process all video files in the current directory if no arguments are provided
    for file in *; do
        if [[ $(file --mime-type -b "$file") =~ ^video/ ]]; then
            extract_thumbnail "$file"
        fi
    done
fi

echo "Thumbnail extraction completed."

#!/bin/bash
# Deploys scripts with `# @nemo` tag to Nemo's right-click menu

# Create the output directory if it doesn't already exist
mkdir -p mp4_web

# Function to process a single video file
convert_video() {
    local file=$1
    local filename=$(basename "$file")
    local extension="${filename##*.}"
    local filename_without_ext="${filename%.*}"

    # Define the output filename
    local suffix="_web_small"
    local output="mp4_web/${filename_without_ext}${suffix}.mp4"

    # Set FFmpeg parameters for stronger compression
    local codec="-vcodec libx264"
    local preset="-preset superfast"
    local crf="-crf 28"

    # Execute FFmpeg command with the desired settings
    ffmpeg -i "$file" $codec $preset $crf -vf "scale=-2:1080" -acodec aac -b:a 128k "$output"

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

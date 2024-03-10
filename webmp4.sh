#!/bin/bash

# Create the output directory if it doesn't already exist
mkdir -p mp4_web

# Function to process a single video file
convert_video() {
    local file=$1
    local smaller=$2
    local filename=$(basename "$file")
    local extension="${filename##*.}"
    local filename_without_ext="${filename%.*}"

    # Define the output filename based on whether the -smaller flag is used
    local suffix="_web"
    if [ "$smaller" == "true" ]; then
        suffix="_web_small"
    fi
    local output="mp4_web/${filename_without_ext}${suffix}.mp4"

    # Set default FFmpeg parameters
    local codec="-vcodec libx264"
    local preset="-preset veryslow"
    local crf="-crf 23"

    # Adjust parameters for stronger compression if the -smaller flag is set
    if [ "$smaller" == "true" ]; then
        preset="-preset superfast"
        crf="-crf 28"
    fi

    # Execute FFmpeg command with the desired settings
    ffmpeg -i "$file" $codec $preset $crf -vf "scale=-2:1080" -acodec aac -b:a 128k "$output"

    echo "Converted $file to $output"
}

# Flag for stronger compression
smaller=false

# Check if the -smaller flag is provided
if [[ " $* " =~ " -smaller " ]]; then
    smaller=true
    set -- "${@/-smaller/}"
fi

# Check if specific filenames are provided as arguments
if [ $# -gt 0 ]; then
    # Process each file provided as an argument
    for file in "$@"; do
        if [ -f "$file" ]; then
            convert_video "$file" $smaller
        else
            echo "File $file not found."
        fi
    done
else
    # Process all video files in the current directory if no arguments are provided
    for file in *; do
        if [[ $(file --mime-type -b "$file") =~ ^video/ ]]; then
            convert_video "$file" $smaller
        fi
    done
fi

echo "Conversion completed."

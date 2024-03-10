#!/bin/bash

# Function to extract a frame from a video file
extract_frame() {
    local file=$1
    local frame=$2
    local filename=$(basename "$file")
    local filename_without_ext="${filename%.*}"
    local output="${filename_without_ext}_thumbnail.jpg"

    # Execute FFmpeg command to extract the specified frame
    ffmpeg -i "$file" -vf "select=eq(n\,${frame})" -vframes 1 "$output"

    echo "Extracted frame $frame for $file as $output"
}

# Default frame to extract (first frame)
frame=0

# Process command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -frame)
            frame=$2
            shift 2
            ;;
        *)
            # Check if file exists and is a video
            if [ -f "$1" ] && [[ $(file --mime-type -b "$1") =~ ^video/ ]]; then
                extract_frame "$1" $frame
            else
                echo "File $1 not found or is not a video."
            fi
            shift
            ;;
    esac
done

# If no files were specified, process all video files in the directory
if [ $# -eq 0 ]; then
    for file in *; do
        if [[ $(file --mime-type -b "$file") =~ ^video/ ]]; then
            extract_frame "$file" $frame
        fi
    done
fi

echo "Thumbnail extraction completed."

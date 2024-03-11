#!/bin/bash

# Function to extract frames from a video file
extract_frames() {
    local file=$1
    shift
    local frames=("$@")
    local filename=$(basename "$file")
    local filename_without_ext="${filename%.*}"

    # Loop through each frame number and extract it
    for frame in "${frames[@]}"; do
        local output="${filename_without_ext}_frame_${frame}.jpg"

        # Execute FFmpeg command to extract the specified frame
        ffmpeg -i "$file" -vf "select=eq(n\,${frame})" -vframes 1 "$output"

        echo "Extracted frame $frame for $file as $output"
    done
}

# Initialize variables
declare -a frames=(0)  # Default to extracting the first frame
video_file=""

# Process command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -frames)
            shift  # Move past the '-frames' argument
            frames=()  # Reset frames array to fill with new values
            while [[ "$1" =~ ^[0-9]+$ ]]; do
                frames+=("$1")
                shift
            done
            ;;
        *)
            if [ -f "$1" ] && [[ $(file --mime-type -b "$1") =~ ^video/ ]]; then
                video_file="$1"
            else
                echo "Warning: File $1 not found or is not a video."
            fi
            shift
            ;;
    esac
done

# Extract frames from the specified video file or all video files in the directory
if [ -n "$video_file" ]; then
    extract_frames "$video_file" "${frames[@]}"
else
    echo "No specific video file provided, extracting from all videos in the current directory."
    for file in *; do
        if [[ $(file --mime-type -b "$file") =~ ^video/ ]]; then
            extract_frames "$file" "${frames[@]}"
        fi
    done
fi

echo "Frame extraction completed."

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

# Array to hold frame numbers
declare -a frames

# Process command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -frame)
            while [[ "$2" =~ ^[0-9]+$ ]]; do
                frames+=("$2")
                shift
            done
            ;;
        *)
            # Check if file exists and is a video
            if [ -f "$1" ] && [[ $(file --mime-type -b "$1") =~ ^video/ ]]; then
                extract_frames "$1" "${frames[@]}"
                frames=() # Reset frames array for the next file
            else
                echo "File $1 not found or is not a video."
            fi
            shift
            ;;
    esac
done

# If no files were specified, process all video files in the directory
if [ ${#frames[@]} -eq 0 ]; then
    for file in *; do
        if [[ $(file --mime-type -b "$file") =~ ^video/ ]]; then
            extract_frames "$file" "${frames[@]}"
        fi
    done
fi

echo "Thumbnail extraction completed."

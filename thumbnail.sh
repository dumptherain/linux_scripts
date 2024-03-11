#!/bin/bash

# Function to extract frames from a video file
extract_frames() {
    local file=$1
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

# Initialize the frames array with 0 to extract the first frame by default
declare -a frames=(0)

# Process command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -frame)
            frames=() # Reset frames array to fill with new values
            while [[ "$2" =~ ^[0-9]+$ ]]; do
                frames+=("$2")
                shift
            done
            ;;
        *)
            # Check if file exists and is a video
            if [ -f "$1" ] && [[ $(file --mime-type -b "$1") =~ ^video/ ]]; then
                extract_frames "$1" "${frames[@]}"
                frames=(0) # Reset frames array to default value
            else
                echo "File $1 not found or is not a video."
            fi
            shift
            ;;
    esac
done

# If no specific video file was provided, process all video files in the directory
if [ ${#frames[@]} -eq 1 ] && [ ${frames[0]} -eq 0 ]; then
    for file in *; do
        if [[ $(file --mime-type -b "$file") =~ ^video/ ]]; then
            extract_frames "$file" "${frames[@]}"
        fi
    done
fi

echo "Frame extraction completed."

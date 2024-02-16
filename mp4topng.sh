#!/bin/bash

# Default zero padding
zero_padding=4

# Video file extensions to include
declare -a video_extensions=("mp4" "mkv" "mov" "avi" "flv" "wmv")

# Function to process video
process_video() {
    local video=$1
    local zero_padding=$2
    local base_name="${video%.*}"

    # Generate the format string for zero padding
    local format="%0${zero_padding}d"

    # Directory name for PNGs
    local dir_name="${base_name}_png"

    # Create directory for PNGs if it doesn't exist
    mkdir -p "$dir_name"

    # Extract frames without changing resolution
    ffmpeg -i "$video" -vsync 0 "${dir_name}/${base_name}_${format}.png"

    echo "Conversion completed: ${dir_name}/${base_name}_[frame_number].png with zero padding of $zero_padding"
}

# Process all video files if no specific file is provided
if [ "$#" -eq 0 ]; then
    for ext in "${video_extensions[@]}"; do
        for video in *.$ext; do
            [ -e "$video" ] || continue # Skip if no files found for this extension
            process_video "$video" $zero_padding
        done
    done
else
    # Parse command line arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -0pad) zero_padding="$2"; shift ;;
            *) video="$1" ;;
        esac
        shift
    done

    # Call process_video function with the specified video and zero padding
    process_video "$video" $zero_padding
fi

#!/bin/bash

# Function to process video and extract every nth frame
process_video_nth_frame() {
    local video=$1
    local target_frames=$2
    local base_name=$(basename "${video%.*}")

    # Get the total number of frames in the video
    total_frames=$(ffmpeg -i "$video" -map 0:v:0 -c copy -f null - 2>&1 | grep 'frame=' | awk '{print $2}')

    # Calculate the nth frame interval
    if [ "$total_frames" -le "$target_frames" ]; then
        nth_frame=1
    else
        nth_frame=$((total_frames / target_frames))
    fi

    # Directory name for PNGs
    local dir_name="${video%.*}_every_nth_frame"

    # Create directory for PNGs if it doesn't exist
    mkdir -p "$dir_name"

    # Extract every nth frame without changing resolution
    ffmpeg -i "$video" -vf "select=not(mod(n\,$nth_frame))" -vsync vfr "${dir_name}/${base_name}_%04d.png"

    echo "Conversion completed: ${dir_name}/${base_name}_%04d.png with every $nth_frame frames"
}

# Prompt user for video file
read -p "Enter the path to the video file: " video
if [ ! -f "$video" ]; then
    echo "File not found!"
    exit 1
fi

# Prompt user for target amount of frames
read -p "Enter the target amount of frames to extract: " target_frames
if ! [[ "$target_frames" =~ ^[0-9]+$ ]]; then
    echo "Invalid number of frames!"
    exit 1
fi

# Call process_video_nth_frame function with the provided video and target frames
process_video_nth_frame "$video" "$target_frames"


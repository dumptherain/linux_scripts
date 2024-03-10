#!/bin/bash

# Check for correct usage
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <directory_path>"
    exit 1
fi

# Root directory path
root_dir="$1"

# Find all video files and loop over them
find "$root_dir" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) | while read -r input_video; do
    # Extract the video filename without extension
    filename=$(basename -- "$input_video")
    filename_noext="${filename%.*}"
    
    # Get the directory of the current video
    video_dir=$(dirname "$input_video")
    
    # Create output directory specific to each video in the same folder as the video
    output_dir="$video_dir/frame_$filename_noext"
    mkdir -p "$output_dir"

    # Get the total duration of the video in seconds
    duration=$(ffprobe -i "$input_video" -show_entries format=duration -v quiet -of csv="p=0")

    # Interval at which to extract frames (you might want to adjust this)
    interval=5

    # Loop through the video and extract 3 frames at each specified interval
    for i in $(seq 0 $interval $(printf "%.0f\n" "$duration")); do
        for offset in -1 0 1; do  # Three frames: one before, one at, and one after the time i
            time_point=$((i + offset))
            if (( time_point >= 0 )); then
                ffmpeg -ss $time_point -i "$input_video" -vf "select='eq(n\,$time_point)'" -vframes 1 "$output_dir/frame_$(printf "%04d" $time_point).jpg"
            fi
        done
    done

    echo "Still frames for $input_video have been saved to $output_dir."
done

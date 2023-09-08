#!/bin/bash

# Check for correct usage
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_video_file>"
    exit 1
fi

# Input video file
input_video="$1"

# Create the output directory named "frames" if it doesn't exist
output_dir="frames"
mkdir -p "$output_dir"

# Get the total duration of the video in seconds
duration=$(ffprobe -i "$input_video" -show_entries format=duration -v quiet -of csv="p=0" -sexagesimal)

# Convert duration to seconds for easier arithmetic (this assumes that the duration is in the format hh:mm:ss)
IFS=: read -ra TIME <<< "$duration"
duration_seconds=$((${TIME[0]}*3600 + ${TIME[1]}*60 + ${TIME[2]%.*}))

# Interval at which to extract frames (you might want to adjust this)
interval=5

# Loop through the video and extract frames at the specified interval
for i in $(seq 0 $interval $duration_seconds); do
    ffmpeg -ss $i -i "$input_video" -vf "select='eq(n\,$i)'" -vframes 1 "$output_dir/frame_$(printf "%04d" $i).jpg"
done

echo "Still frames have been saved to $output_dir."

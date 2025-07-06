#!/bin/bash
# Deploys scripts with `# @nemo` tag to Nemo's right-click menu

# Default sensitivity level
sensitivity=7

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s)
            shift
            sensitivity=$1
            if ! [[ "$sensitivity" =~ ^[0-9]+$ ]] || [ "$sensitivity" -lt 0 ] || [ "$sensitivity" -gt 10 ]; then
                echo "Sensitivity must be a number between 0 and 10."
                exit 1
            fi
            ;;
        *)
            if [[ -z "$input_video" ]]; then
                input_video="$1"
            else
                echo "Unexpected argument: $1"
                exit 1
            fi
            ;;
    esac
    shift
done

if [[ -z "$input_video" ]]; then
    echo "Usage: $0 <input_video_file> [-s <sensitivity 0-10>]"
    exit 1
fi

# Create the output directory named "frames" if it doesn't exist
output_dir="frames"
mkdir -p "$output_dir"

# Get the total duration of the video in seconds
duration=$(ffprobe -i "$input_video" -show_entries format=duration -v quiet -of csv="p=0")
duration_seconds=$(printf "%.0f" "$duration")

# Define interval based on sensitivity
interval=$((10 - sensitivity + 1))

# Loop through the video and extract frames at the specified interval
for ((i=0; i<=duration_seconds; i+=interval)); do
    ffmpeg -ss $i -i "$input_video" -vframes 1 "$output_dir/frame_$(printf "%04d" $i).jpg"
done

echo "Still frames have been saved to $output_dir."


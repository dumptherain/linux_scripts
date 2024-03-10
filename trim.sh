#!/bin/bash

# Function to trim frames from the start and/or end of a video
trim_video() {
    local file=$1
    local start_trim=$2
    local end_trim=$3

    # Extract filename without extension
    local filename=$(basename -- "$file")
    local extension="${filename##*.}"
    local filename_without_ext="${filename%.*}"
    local output="${filename_without_ext}_trimmed.${extension}"

    # Get total number of frames in the video
    local total_frames=$(ffprobe -v error -select_streams v:0 -count_frames -show_entries stream=nb_read_frames -of default=nokey=1:noprint_wrappers=1 "$file")

    # Calculate the last frame to keep, subtracting the end trim value
    local end_frame=$((total_frames - end_trim))

    # Build the FFmpeg command
    local ffmpeg_cmd="ffmpeg -i \"$file\""

    # If start_trim is specified, add the trim command for the start
    if [ $start_trim -gt 0 ]; then
        ffmpeg_cmd+=" -vf \"select=gte(n\,$start_trim)\""
    fi

    # If end_trim is specified and less than total frames, add the trim command for the end
    if [ $end_trim -gt 0 ] && [ $end_frame -lt $total_frames ]; then
        ffmpeg_cmd+=" -to $(ffprobe -v error -select_streams v -show_entries stream=duration -of default=noprint_wrappers=1:nokey=1 \"$file\" | awk -v fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=nokey=1:noprint_wrappers=1 "$file" | awk -F '/' '{ print $1 / $2 }') -v frames=$end_frame 'BEGIN { getline; print frames / fps }')"
    fi

    ffmpeg_cmd+=" \"$output\""

    # Execute the FFmpeg command
    eval $ffmpeg_cmd

    echo "Trimmed video saved as $output"
}

# Default values for start and end frame trims
start_trim=0
end_trim=0

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -start)
            start_trim=$2
            shift 2
            ;;
        -end)
            end_trim=$2
            shift 2
            ;;
        *)
            # Process the video file with specified trim values
            if [ -f "$1" ]; then
                trim_video "$1" $start_trim $end_trim
            else
                echo "File $1 not found."
            fi
            exit 0
            ;;
    esac
done

if [ $# -eq 0 ]; then
    echo "Usage: $0 [-start frame_count] [-end frame_count] filename"
    exit 1
fi

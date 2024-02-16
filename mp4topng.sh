#!/bin/bash

# Default resolution and zero padding
res="1920x1080"
zero_padding=4

# Check if at least one argument is provided
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 [video.mp4] -res [WIDTHxHEIGHT] -0pad [NUMBER]"
  exit 1
fi

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -res) res="$2"; shift ;;
        -0pad) zero_padding="$2"; shift ;;
        *) video="$1" ;;
    esac
    shift
done

# Check if video file is provided
if [ -z "$video" ]; then
    echo "Error: No video file provided."
    exit 1
fi

# Generate the format string for zero padding
format="%0${zero_padding}d"

# Extract frames and resize
ffmpeg -i "$video" -vf "scale=$res" -vsync 0 "${video%.*}_${format}.png"

echo "Conversion completed: ${video%.*}_[frame_number].png at resolution $res with zero padding of $zero_padding"

#!/bin/bash

mkdir -p mp4

# Check if any arguments are provided
if [ "$#" -gt 0 ]; then
    # Process each file provided as an argument
    for i in "$@"; do
        ffmpeg -i "$i" \
        -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
        -c:v libx264 -pix_fmt yuv420p \
        "./mp4/${i%.*}.mp4"
    done
else
    # Process all files in the current directory
    for i in *.*; do
        ffmpeg -i "$i" \
        -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
        -c:v libx264 -pix_fmt yuv420p \
        "./mp4/${i%.*}.mp4"
    done
fi

exit

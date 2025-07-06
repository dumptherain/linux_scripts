#!/bin/bash
# Deploys scripts with `# @nemo` tag to Nemo's right-click menu

# Create the mp4 directory if it doesn't exist
mkdir -p mp4

# Check if any arguments are provided
if [ "$#" -gt 0 ]; then
    # Process each file provided as an argument
    for i in "$@"; do
        ffmpeg -i "$i" \
        -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
        -c:v libx264 -crf 18 -preset slow -pix_fmt yuv420p \
        "./mp4/$(basename "${i%.*}").mp4"
    done
else
    # Process all files in the current directory
    for i in *.*; do
        ffmpeg -i "$i" \
        -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" \
        -c:v libx264 -crf 18 -preset slow -pix_fmt yuv420p \
        "./mp4/$(basename "${i%.*}").mp4"
    done
fi

exit

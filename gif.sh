#!/bin/bash

# Create the gif directory if it doesn't exist
mkdir -p gif

# Set the desired frames per second for the GIF
FPS=15

# Check if any arguments are provided
if [ "$#" -gt 0 ]; then
    # Process each file provided as an argument
    for i in "$@"; do
        # Create a temporary palette file
        palette=$(mktemp /tmp/palette.XXXXXX.png)
        # Generate a palette from the input video
        ffmpeg -y -i "$i" -vf "fps=$FPS,scale=trunc(iw/2)*2:trunc(ih/2)*2,palettegen" "$palette"
        # Use the generated palette to create the GIF
        ffmpeg -y -i "$i" -i "$palette" -filter_complex "fps=$FPS,scale=trunc(iw/2)*2:trunc(ih/2)*2[x];[x][1:v]paletteuse" "./gif/$(basename "${i%.*}").gif"
        rm "$palette"
    done
else
    # Process all files in the current directory
    for i in *.*; do
        palette=$(mktemp /tmp/palette.XXXXXX.png)
        ffmpeg -y -i "$i" -vf "fps=$FPS,scale=trunc(iw/2)*2:trunc(ih/2)*2,palettegen" "$palette"
        ffmpeg -i "$i" -i "$palette" -filter_complex "fps=$FPS,scale=trunc(iw/2)*2:trunc(ih/2)*2[x];[x][1:v]paletteuse" "./gif/$(basename "${i%.*}").gif"
        rm "$palette"
    done
fi

exit


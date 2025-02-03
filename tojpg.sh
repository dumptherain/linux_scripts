#!/bin/bash

# Loop through all files in the current directory
for image in *; do

    # Check if the file is a regular file and has an image extension
    if [[ -f "$image" && ( "$image" == *.png || "$image" == *.gif || "$image" == *.bmp || "$image" == *.tiff || "$image" == *.jpeg ) && "$image"!= *.jpg ]]; then

        # Extract the filename without extension
        filename=$(basename "$image")
        filename="${filename%.*}"

        # Convert the image to JPG using mogrify
        mogrify -format jpg "$image"

        # Rename the original file by appending "_original" to the filename
        mv "$image" "${filename}_original.${image##*.}"

        # Rename the converted JPG file to the original filename
        mv "${filename}.jpg" "${filename}.jpg"
    fi
done

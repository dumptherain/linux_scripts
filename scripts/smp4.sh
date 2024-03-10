#!/bin/bash

# Loop over each argument passed to the script
for i in "$@"; do
  # Extract the filename without extension
  filename=$(basename -- "$i")
  extension="${filename##*.}"
  filename="${filename%.*}"
  
  # Convert the file and save it with '_small' appended to the original filename
  ffmpeg -i "$i" \
  -c:v libx264 -pix_fmt yuv420p \
  "${filename}_small.${extension}"
done

exit

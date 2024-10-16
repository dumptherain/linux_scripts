#!/bin/bash

# Output file name
output_file="output.mp4"

# Temporary file to store concatenated video
temp_file="temp_concat.mp4"

# Check if there are no input videos
if [ "$#" -eq 0 ]; then
    echo "No input videos provided."
    exit 1
fi

# Create a temporary list of input files
input_list=$(mktemp)
for video_file in "$@"; do
    echo "file '$(realpath "$video_file")'" >> "$input_list"
done

# Concatenate videos using ffmpeg
ffmpeg -f concat -safe 0 -i "$input_list" -c copy "$temp_file"

# Rename concatenated file to output name
mv "$temp_file" "$output_file"

# Remove the temporary input list file
rm "$input_list"

echo "Concatenation complete. Output file: $output_file"

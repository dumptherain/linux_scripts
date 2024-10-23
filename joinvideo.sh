#!/bin/bash

# Create an array to hold the input files
inputs=()

# Loop through all mp4 files in the current directory
for f in *.mp4; do
  # Add each file to the inputs array with the appropriate FFmpeg input flag
  inputs+=("-i" "$f")
done

# Count the number of input files
num_inputs=${#inputs[@]}

# Build the filter_complex string dynamically based on the number of inputs
filter_complex=""
for ((i=0; i<num_inputs; i+=2)); do
  filter_complex+="[$((i/2)):v:0]"
done
filter_complex+="concat=n=$((num_inputs/2)):v=1[outv]"

# Run FFmpeg with the constructed command, specifying codecs for encoding
ffmpeg "${inputs[@]}" -filter_complex "$filter_complex" -map "[outv]" -c:v libx264 -crf 23 -preset fast output.mp4


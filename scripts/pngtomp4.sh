#!/bin/bash

# Current directory where the PNG files are located
input_dir="."

# Frame rate
fps=24

# Find the first PNG file in the sequence in the current directory
first_png=$(ls ${input_dir}/*.png | sort | head -n 1)

# Check if PNG files are found
if [ -z "$first_png" ]; then
    echo "No PNG files found in the current directory."
    exit 1
fi

# Extract the base name from the first PNG file
# This assumes the naming convention is like "Heatmap2_00000.png"
base_name=$(basename "${first_png}")
base_name="${base_name%_*}"

# Output file name based on the first input frame
output_file="${base_name}.mp4"

# Find the resolution of the first PNG in the sequence
resolution=$(identify -format "%wx%h" "${first_png}")

# Use ffmpeg to convert the PNG sequence to MP4
ffmpeg -framerate ${fps} -pattern_type glob -i "${input_dir}/${base_name}_*.png" -s:v ${resolution} -c:v libx264 -pix_fmt yuv420p -crf 23 "${output_file}"

echo "Conversion completed: ${output_file}"

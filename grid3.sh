#!/bin/bash

# Directory where the grid videos will be stored
output_dir="grids"

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Get all MP4 files in the current directory
mp4files=($(ls *.mp4))

# Calculate how many videos will be created
num_files=${#mp4files[@]}
batches=$((num_files / 9))
remainder=$((num_files % 9))

# Process full 3x3 batches
for ((batch=0; batch<batches; batch++)); do
  filter_complex=""
  input_files=""

  for i in {0..8}; do
    file_index=$((batch * 9 + i))
    filename="${mp4files[$file_index]}"
    input_files+="-i '${filename}' "
    filter_complex+="[${i}:v]scale=640:640:force_original_aspect_ratio=decrease,pad=640:640:(ow-iw)/2:(oh-ih)/2[v$i];"
  done

  filter_complex+="[v0][v1][v2]hstack=inputs=3[top];"
  filter_complex+="[v3][v4][v5]hstack=inputs=3[middle];"
  filter_complex+="[v6][v7][v8]hstack=inputs=3[bottom];"
  filter_complex+="[top][middle][bottom]vstack=inputs=3[v]"

  output_file="${output_dir}/grid_$(printf "%02d" $((batch+1))).mp4"
  ffmpeg_cmd="ffmpeg $input_files -filter_complex \"$filter_complex\" -map \"[v]\" -c:v libx264 -crf 23 -preset veryfast \"$output_file\""
  eval "$ffmpeg_cmd"
  echo "3x3 grid video $((batch+1)) has been created as $output_file"
done

# Handle remaining files for a smaller grid
if [ $remainder -gt 0 ]; then
  filter_complex=""
  input_files=""
  start_index=$((batches * 9))

  for ((i=0; i<remainder; i++)); do
    filename="${mp4files[$((start_index + i))]}"
    input_files+="-i '${filename}' "
    filter_complex+="[${i}:v]scale=640:640:force_original_aspect_ratio=decrease,pad=640:640:(ow-iw)/2:(oh-ih)/2[v$i];"
  done

  # Adjust the filter_complex string based on the number of remaining files
  case $remainder in
    1)
      filter_complex+="[v0]null[v];"
      ;;
    2)
      filter_complex+="[v0][v1]hstack=inputs=2[v];"
      ;;
    3)
      filter_complex+="[v0][v1][v2]hstack=inputs=3[v];"
      ;;
    4)
      filter_complex+="[v0][v1]hstack=inputs=2[top];[v2][v3]hstack=inputs=2[bottom];[top][bottom]vstack=inputs=2[v];"
      ;;
    5)
      filter_complex+="[v0][v1][v2]hstack=inputs=3[top];[v3][v4]hstack=inputs=2[bottom];[top][bottom]vstack=inputs=2[v];"
      ;;
    6)
      filter_complex+="[v0][v1][v2]hstack=inputs=3[top];[v3][v4][v5]hstack=inputs=3[bottom];[top][bottom]vstack=inputs=2[v];"
      ;;
    7)
      filter_complex+="[v0][v1][v2]hstack=inputs=3[top];[v3][v4]hstack=inputs=2[middle];[v5][v6]hstack=inputs=2[bottom];[top][middle][bottom]vstack=inputs=3[v];"
      ;;
    8)
      filter_complex+="[v0][v1][v2]hstack=inputs=3[top];[v3][v4][v5]hstack=inputs=3[middle];[v6][v7]hstack=inputs=2[bottom];[top][middle][bottom]vstack=inputs=3[v];"
      ;;
  esac

  output_file="${output_dir}/grid_$(printf "%02d" $((batches+1))).mp4"
  ffmpeg_cmd="ffmpeg $input_files -filter_complex \"$filter_complex\" -map \"[v]\" -c:v libx264 -crf 23 -preset veryfast \"$output_file\""
  eval "$ffmpeg_cmd"
  echo "Smaller grid video $(($batches+1)) has been created as $output_file"
fi

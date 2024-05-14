#!/bin/bash

if [ "$#" -lt 2 ] || [ $(($# % 2)) -ne 0 ]; then
  kdialog --error "Please select an even number of video files."
  exit 1
fi

declare -A left_files
declare -A right_files

# Separate left and right files into respective associative arrays
for file in "$@"; do
  if [[ "$file" == *_left.mov ]]; then
    base_name="${file%_left.mov}"
    left_files["$base_name"]="$file"
  elif [[ "$file" == *_right.mov ]]; then
    base_name="${file%_right.mov}"
    right_files["$base_name"]="$file"
  else
    kdialog --error "Selected files do not match expected naming convention."
    exit 1
  fi
done

# Merge files
for base_name in "${!left_files[@]}"; do
  left="${left_files[$base_name]}"
  right="${right_files[$base_name]}"

  if [ -n "$right" ]; then
    output="${base_name}.mov"
    ffmpeg -i "$left" -i "$right" -filter_complex hstack -c:v prores_ks -profile:v 4 -pix_fmt yuv444p10le "$output"
    echo "Merged $left and $right into $output"
  else
    echo "No matching right file for $left"
  fi
done

kdialog --msgbox "Merge completed successfully."

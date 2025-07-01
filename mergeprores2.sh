#!/bin/bash

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
  echo "Error: ffmpeg is not installed. Please install it using 'sudo apt install ffmpeg'."
  exit 1
fi

# Check for even number of arguments
if [ "$#" -lt 2 ] || [ $(($# % 2)) -ne 0 ]; then
  echo "Error: Please select an even number of video files."
  exit 1
fi

declare -A left_files
declare -A right_files

# Separate left and right files into respective associative arrays
for file in "$@"; do
  if [[ "$file" =~ _left\.mov$ || "$file" =~ _l\.mov$ ]]; then
    base_name="${file%_*}"
    left_files["$base_name"]="$file"
  elif [[ "$file" =~ _right\.mov$ || "$file" =~ _r\.mov$ ]]; then
    base_name="${file%_*}"
    right_files["$base_name"]="$file"
  else
    echo "Error: Selected files do not match expected naming convention (_left.mov, _l.mov, _right.mov, _r.mov)."
    exit 1
  fi
done

# Merge files
for base_name in "${!left_files[@]}"; do
  left="${left_files[$base_name]}"
  right="${right_files[$base_name]}"

  if [ -n "$right" ]; then
    output="${base_name}.mov"
    ffmpeg -i "$left" -i "$right" -filter_complex hstack -c:v prores_ks -profile:v 4 -pix_fmt yuv444p10le "$output" || {
      echo "Error: Failed to merge $left and $right."
      exit 1
    }
    echo "Merged $left and $right into $output"
  else
    echo "Error: No matching right file for $left"
  fi
done

echo "Merge completed successfully."

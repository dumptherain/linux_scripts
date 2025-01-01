#!/bin/bash

source_dir="/home/mini/Videos/OBS"
dest_dir="/mnt/a/youtube/recordings"

# Get today's date in YYMMDD format
today=$(date +"%y%m%d")

# Construct destination subdirectory
dest_subdir="$dest_dir/$today"

# Create destination subdirectory if it doesn't exist
mkdir -p "$dest_subdir"

# inotifywait command (monitor for close_write event)
inotifywait -mrq --format "%w%f" -e close_write "$source_dir" | while IFS= read -r line; do
  # Extract file path from inotifywait output
  file_path="$line"

  # Copy the file to the destination subdirectory
  cp -p "$file_path" "$dest_subdir" 

  echo "Copied file '$file_path' to '$dest_subdir'"
done

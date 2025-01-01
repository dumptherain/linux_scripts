#!/bin/bash

source_dir="/home/mini/Videos/OBS"
dest_dir="/mnt/a/youtube/recordings"

# Function to copy files recursively
copy_files() {
  local src="$1"
  local dst="$2"

  rsync -av "$src" "$dst"
}

# inotifywait command (monitor for close_write event)
inotifywait -mrq --timefmt '%Y%m%d' -e close_write "$source_dir" | while IFS= read -r line; do
  # Extract file path from inotifywait output
  file_path=$(echo "$line" | awk '{print $NF}') 

  # Extract directory name from file path
  dir=$(dirname "$file_path")

  # Check if directory name matches expected format (YYYYMMDD)
  if [[ "$dir" =~ ^[0-9]{8}$ ]]; then
    # Construct destination directory path
    dest_subdir="$dest_dir/$dir"

    # Create destination directory if it doesn't exist
    mkdir -p "$dest_subdir"

    # Copy files recursively
    copy_files "$dir" "$dest_subdir"

    echo "Copied files from '$dir' to '$dest_subdir'"
  fi
done

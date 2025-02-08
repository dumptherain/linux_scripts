#!/bin/bash


# To run this script continuously on system startup (via systemd), follow these steps:
# 1. Make the script executable:
#      chmod +x /home/mini/linux_scripts/obs_copy.sh
# 2. Create a systemd service file:
#      sudo nano /etc/systemd/system/obs_copy.service
#    And add the following content (adjust 'User' and 'Group'):
#
#      [Unit]
#      Description=OBS Copy Service
#
#      [Service]
#      ExecStart=/home/mini/linux_scripts/obs_copy.sh
#      Restart=always
#      User=mini
#      Group=mini
#
#      [Install]
#      WantedBy=multi-user.target
#
# 3. Enable and start the service:
#      sudo systemctl daemon-reload
#      sudo systemctl enable obs_copy.service
#      sudo systemctl start obs_copy.service

source_dir="/home/mini/Videos/OBS"
dest_dir="/mnt/a/youtube/recordings"

# Function to get the current date's destination subdirectory
get_dest_subdir() {
  today=$(date +"%y%m%d")
  echo "$dest_dir/$today"
}

# Ensure the initial directory exists
mkdir -p "$(get_dest_subdir)"

# inotifywait command (monitor for close_write event)
inotifywait -mrq --format "%w%f" -e close_write "$source_dir" | while IFS= read -r line; do
  # Extract file path from inotifywait output
  file_path="$line"

  # Get the current destination subdirectory (recalculates date)
  dest_subdir=$(get_dest_subdir)

  # Create the directory if it doesn't exist (important for new days)
  mkdir -p "$dest_subdir"

  # Copy the file to the destination subdirectory
  cp -p "$file_path" "$dest_subdir"

  echo "Copied file '$file_path' to '$dest_subdir'"
done

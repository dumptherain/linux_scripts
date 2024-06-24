#!/bin/bash

# Check if script file is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 script_file.sh"
    exit 1
fi

# Get the script file and base name
script_file=$1
base_name=$(basename "$script_file" .sh)

# Prompt for the service name
read -p "Enter the service name: " service_name

# Define the desktop files folder
desktop_files_folder="./desktop_files"

# Create the desktop file content
desktop_file_content="[Desktop Entry]
Type=Service
ServiceTypes=KonqPopupMenu/Plugin
MimeType=video/x-msvideo;video/quicktime;video/mp4;video/x-matroska;video/x-flv;video/mpeg;video/x-ms-wmv;
Actions=convertToMp4
X-KDE-Priority=TopLevel

[Desktop Action convertToMp4]
Name=Convert to MP4
Exec=$script_file %F
Icon=video-x-generic"

# Save the desktop file
desktop_file_path="$desktop_files_folder/$base_name.desktop"
echo "$desktop_file_content" > "$desktop_file_path"

echo "Desktop file created at $desktop_file_path"

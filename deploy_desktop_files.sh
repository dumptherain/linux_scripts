#!/bin/bash

# Define source and destination directories
SOURCE_DIR="$HOME/linux_scripts/desktop_files"
DEST_DIR="$HOME/.local/share/kservices5/ServiceMenus"

# Ensure the destination directory exists
mkdir -p "$DEST_DIR"

# Copy .desktop files with the correct permissions
cp "$SOURCE_DIR"/*.desktop "$DEST_DIR/"

# Set permissions
chmod 644 "$DEST_DIR"/*.desktop

# Print completion message
echo "Deployment of .desktop files completed successfully."

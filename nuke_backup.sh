#!/bin/bash

# This script backs up or restores the .nuke folder from the current user's home directory.
# For backup: copies to a specified backup location inside a dated subfolder (YYMMDD).
# For restore: finds the latest dated subfolder and copies back to ~/.nuke.
# It uses rsync for efficient synchronization, preserving file permissions, timestamps, and handling updates.

# Source directory (universal: uses $HOME to work on any user's PC)
SOURCE="$HOME/.nuke"

# Default destination backup directory
DEFAULT_DEST="/mnt/r/program/nuke/setup"

# Prompt for backup location
echo "Default backup location: $DEFAULT_DEST"
echo "Enter a different backup location or press Enter to use the default:"
read USER_DEST

# Use user input if provided, otherwise default
DEST="${USER_DEST:-$DEFAULT_DEST}"

# Ask for action
echo "What do you want to do?"
echo "1: Backup"
echo "2: Restore from latest backup"
read ACTION

case $ACTION in
    1)
        # Backup mode

        # Create dated subfolder in YYMMDD format
        DATE_FOLDER=$(date +%y%m%d)
        BACKUP_DIR="$DEST/$DATE_FOLDER"

        # Check if source directory exists
        if [ ! -d "$SOURCE" ]; then
            echo "Error: Source directory $SOURCE does not exist."
            exit 1
        fi

        # Create backup directory if it doesn't exist
        if [ ! -d "$BACKUP_DIR" ]; then
            mkdir -p "$BACKUP_DIR"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to create backup directory $BACKUP_DIR."
                exit 1
            fi
        fi

        # Perform the backup using rsync
        rsync -av --progress "$SOURCE/" "$BACKUP_DIR/"

        if [ $? -eq 0 ]; then
            echo "Backup completed successfully from $SOURCE to $BACKUP_DIR."
        else
            echo "Backup failed."
            exit 1
        fi
        ;;
    2)
        # Restore mode

        # Find the latest dated folder (assuming YYMMDD format)
        LATEST=$(ls -d "$DEST"/[0-9][0-9][0-9][0-9][0-9][0-9] 2>/dev/null | sort -r | head -n 1)

        if [ -z "$LATEST" ]; then
            echo "Error: No backup folders found in $DEST."
            exit 1
        fi

        # Check if source directory exists, create if not
        if [ ! -d "$SOURCE" ]; then
            mkdir -p "$SOURCE"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to create source directory $SOURCE."
                exit 1
            fi
        fi

        # Perform the restore using rsync
        rsync -av --progress "$LATEST/" "$SOURCE/"

        if [ $? -eq 0 ]; then
            echo "Restore completed successfully from $LATEST to $SOURCE."
        else
            echo "Restore failed."
            exit 1
        fi
        ;;
    *)
        echo "Invalid option. Please choose 1 or 2."
        exit 1
        ;;
esac

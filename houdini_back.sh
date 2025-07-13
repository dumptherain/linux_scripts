#!/bin/bash

# This script backs up or restores Houdini configuration folders from the current user's home directory.
# It detects Houdini version folders (named like houdini20.5, houdini21) in $HOME.
# For backup: selects a folder, backs up to $DEST/$version/$dated_subfolder (YYMMDD).
# For restore: selects a backup version, lists available dated subfolders, selects one, then selects a target folder in $HOME to restore to.
# Uses rsync for efficient synchronization, preserving file permissions, timestamps, and handling updates.

# Default destination backup directory
DEFAULT_DEST="/mnt/r/program/houdini/setup"

# Prompt for backup location
echo "Default backup location: $DEFAULT_DEST"
echo "Enter a different backup location or press Enter to use the default:"
read USER_DEST

# Use user input if provided, otherwise default
DEST="${USER_DEST:-$DEFAULT_DEST}"

# Ask for action
echo "What do you want to do?"
echo "1: Backup"
echo "2: Restore"
read ACTION

case $ACTION in
    1)
        # Backup mode

        # Find Houdini folders in $HOME
        HOUDINI_FOLDERS=($(ls -d "$HOME"/houdini*/ 2>/dev/null | xargs -n1 basename))

        if [ ${#HOUDINI_FOLDERS[@]} -eq 0 ]; then
            echo "No Houdini folders found in $HOME."
            exit 1
        fi

        echo "Select which folder to backup:"
        for i in "${!HOUDINI_FOLDERS[@]}"; do
            VERSION=${HOUDINI_FOLDERS[$i]#houdini}
            echo "[$(($i+1))] houdini $VERSION found"
        done

        read SELECT
        if ! [[ "$SELECT" =~ ^[0-9]+$ ]] || [ $SELECT -lt 1 ] || [ $SELECT -gt ${#HOUDINI_FOLDERS[@]} ]; then
            echo "Invalid selection."
            exit 1
        fi

        SELECTED=${HOUDINI_FOLDERS[$(($SELECT-1))]}
        SOURCE="$HOME/$SELECTED"

        # Check if source directory exists
        if [ ! -d "$SOURCE" ]; then
            echo "Error: Source directory $SOURCE does not exist."
            exit 1
        fi

        # Create dated subfolder in YYMMDD format
        DATE_FOLDER=$(date +%y%m%d)
        BACKUP_DIR="$DEST/$SELECTED/$DATE_FOLDER"

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

        # Find available backup versions in $DEST
        BACKUP_VERSIONS=($(ls -d "$DEST"/houdini*/ 2>/dev/null | xargs -n1 basename))

        if [ ${#BACKUP_VERSIONS[@]} -eq 0 ]; then
            echo "No backup versions found in $DEST."
            exit 1
        fi

        echo "Select which backup version to restore from:"
        for i in "${!BACKUP_VERSIONS[@]}"; do
            VERSION=${BACKUP_VERSIONS[$i]#houdini}
            echo "[$(($i+1))] houdini $VERSION"
        done

        read SELECT_FROM
        if ! [[ "$SELECT_FROM" =~ ^[0-9]+$ ]] || [ $SELECT_FROM -lt 1 ] || [ $SELECT_FROM -gt ${#BACKUP_VERSIONS[@]} ]; then
            echo "Invalid selection."
            exit 1
        fi

        SELECTED_FROM=${BACKUP_VERSIONS[$(($SELECT_FROM-1))]}
        BACKUP_VERSION_DIR="$DEST/$SELECTED_FROM"

        # Find available dated folders (assuming YYMMDD format), sorted descending
        DATE_FOLDERS=($(ls -d "$BACKUP_VERSION_DIR"/[0-9][0-9][0-9][0-9][0-9][0-9] 2>/dev/null | sort -r))

        if [ ${#DATE_FOLDERS[@]} -eq 0 ]; then
            echo "Error: No backup date folders found for $SELECTED_FROM in $BACKUP_VERSION_DIR."
            exit 1
        fi

        echo "Select which date folder to restore from (latest first):"
        for i in "${!DATE_FOLDERS[@]}"; do
            echo "[$(($i+1))] ${DATE_FOLDERS[$i]##*/}"
        done

        read SELECT_DATE
        if ! [[ "$SELECT_DATE" =~ ^[0-9]+$ ]] || [ $SELECT_DATE -lt 1 ] || [ $SELECT_DATE -gt ${#DATE_FOLDERS[@]} ]; then
            echo "Invalid selection."
            exit 1
        fi

        SELECTED_DATE=${DATE_FOLDERS[$(($SELECT_DATE-1))]}

        # Find Houdini folders in $HOME to restore to
        HOUDINI_FOLDERS=($(ls -d "$HOME"/houdini*/ 2>/dev/null | xargs -n1 basename))

        if [ ${#HOUDINI_FOLDERS[@]} -eq 0 ]; then
            echo "No Houdini folders found in $HOME to restore to."
            exit 1
        fi

        echo "Select which folder to restore to:"
        for i in "${!HOUDINI_FOLDERS[@]}"; do
            VERSION=${HOUDINI_FOLDERS[$i]#houdini}
            echo "[$(($i+1))] houdini $VERSION found"
        done

        read SELECT_TO
        if ! [[ "$SELECT_TO" =~ ^[0-9]+$ ]] || [ $SELECT_TO -lt 1 ] || [ $SELECT_TO -gt ${#HOUDINI_FOLDERS[@]} ]; then
            echo "Invalid selection."
            exit 1
        fi

        SELECTED_TO=${HOUDINI_FOLDERS[$(($SELECT_TO-1))]}
        TARGET="$HOME/$SELECTED_TO"

        # Create target directory if it doesn't exist
        if [ ! -d "$TARGET" ]; then
            mkdir -p "$TARGET"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to create target directory $TARGET."
                exit 1
            fi
        fi

        # Perform the restore using rsync
        rsync -av --progress "$SELECTED_DATE/" "$TARGET/"

        if [ $? -eq 0 ]; then
            echo "Restore completed successfully from $SELECTED_DATE to $TARGET."
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

#!/bin/bash
path=$(xclip -o -selection clipboard | xargs)  # Get and trim clipboard content

# Function to check if any file in sequence exists
check_sequence_exists() {
    local pattern="$1"
    # Replace #### with * for globbing
    local glob_path="${pattern//####/[0-9][0-9][0-9][0-9]}"
    # Check if any file matches the pattern
    if compgen -G "$glob_path" > /dev/null; then
        return 0  # Success
    else
        return 1  # Failure
    fi
}

# Check if path is an image sequence
if [[ "$path" =~ \.(#+|[0-9]{4})\.(exr|png|jpg|jpeg|tif|tiff|dpx)$ ]] && check_sequence_exists "$path"; then
    /usr/local/DJV2/bin/djv.sh "$path"  # Open image sequences with DJV
# Check if path exists and is a file or directory
elif [ -e "$path" ]; then
    # If it's a file and has a video extension
    if [ -f "$path" ] && [[ "$path" =~ \.(mp4|mkv|avi|mov|wmv|flv|webm)$ ]]; then
        celluloid "$path"  # Open video files with Celluloid
    # If it's a directory or other file
    elif [ -d "$path" ] || [ -f "$path" ]; then
        nemo "$path"  # Open with Nemo file manager
    fi
else
    notify-send "Invalid path in clipboard: $path"
fi

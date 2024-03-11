#!/bin/bash

# Function to process a directory recursively
process_directory() {
    local root_dir="$1"
    local dir="$2"
    local original_dir=$(pwd)
    echo "Processing directory: $dir"

    cd "$dir" || return 1
    echo "Changing into directory $dir"

    # Check if there are any .exr files in the directory
    if ! ls *.exr >/dev/null 2>&1; then
        echo "No EXR files found in $dir, skipping..."
        cd "$original_dir" || return 1
        return
    fi

    echo "Executing exrtomp4.sh to convert EXR to MP4"
    if exrtomp4.sh; then
        echo "Conversion successful in $dir"
        # Move the .mp4 files to the root directory
        for mp4_file in *.mp4; do
            mv "$mp4_file" "$root_dir"
            echo "Moving $mp4_file to the original directory"
        done
    else
        echo "Conversion failed in $dir"
    fi

    # Recursively process subdirectories
    local subdirs=($(find . -mindepth 1 -maxdepth 1 -type d))
    for subdir in "${subdirs[@]}"; do
        process_directory "$root_dir" "$subdir"
    done

    cd "$original_dir" || return 1
    echo "Returning to the original directory"
}

# Main script starts here

# Get the list of directories to process
directories=($(find . -mindepth 1 -maxdepth 1 -type d))

# Process each directory
for dir in "${directories[@]}"; do
    process_directory "$(pwd)" "$dir"
done

echo "Processing complete."

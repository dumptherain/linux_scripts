#!/bin/bash

# Function to remove tmp directories recursively
remove_tmp_directories() {
    local dir="$1"
    echo "Processing directory: $dir"

    # Find and remove all tmp directories recursively
    find "$dir" -type d -name "tmp*" -exec rm -rf {} +

    echo "All tmp directories removed from $dir"
}

# Main script starts here

# Get the root directory
root_dir=$(pwd)

# Remove tmp directories starting from the root directory
remove_tmp_directories "$root_dir"

echo "All tmp directories have been removed recursively from the root directory."

#!/bin/bash

# The current directory is used as the search directory
search_dir="."

# The directory where the MP4 files will be copied to, also the current directory in this case
output_dir=$(pwd)

# Function to process each found directory
process_directory() {
    local dir=$1
    echo "Processing directory: $dir"

    # Change into the directory
    pushd "$dir" > /dev/null

    # Find the first EXR file to base the MP4 name on
    first_exr=$(ls *.exr | sort -V | head -n1)
    if [ -z "$first_exr" ]; then
        echo "No EXR files found in $dir, skipping..."
        popd > /dev/null
        return
    fi

    # Remove the file extension to get the base name
    base_name="${first_exr%.*}"

    # Execute the exrtomp4.sh script
    exrtomp4.sh

    # Check if the MP4 was generated
    if [ -f "./output.mp4" ]; then
        # Rename the MP4 file to match the first EXR file's base name
        mv "./output.mp4" "$output_dir/${base_name}.mp4"
    else
        echo "Conversion failed or no MP4 file was generated in $dir"
    fi

    # Return to the original directory
    popd > /dev/null
}

# Export the function so it can be used by find -exec
export -f process_directory
export output_dir

# Use tree -d to list directories
echo "List of directories:"
tree -d

# Read user input for folders to exclude
read -p "Enter folders to exclude (space-separated): " -a exclude_folders

# Create a find command to exclude specified folders
exclude_cmd=""
for folder in "${exclude_folders[@]}"; do
    exclude_cmd="$exclude_cmd -name $folder -prune -o"
done

# Find directories containing EXR files and process them, excluding user-specified folders
find "$search_dir" \( $exclude_cmd -type f -name "*.exr" -printf '%h\n' \) | sort -u | xargs -I {} bash -c 'process_directory "$@"' _ {}

# Prompt the user to create a new directory and move files
read -p "Do you want to move the processed files into a new directory? Enter the folder name (or press Enter to skip): " move_folder_name

if [ -n "$move_folder_name" ]; then
    # Create the new directory
    mkdir -p "$move_folder_name"

    # Move the processed files into the new directory
    mv *.mp4 "$move_folder_name/"
    echo "Processed files moved to $move_folder_name/"
fi

echo "Processing complete."

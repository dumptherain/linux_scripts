#!/bin/bash

# Function to process images and keep every nth frame
process_images_nth_frame() {
    local img_dir=$1
    local target_frames=$2
    local base_name=$(basename "$img_dir")

    # Get the total number of image files in the directory
    total_frames=$(ls "$img_dir" | grep -E "\.(png|jpg|jpeg|bmp|tiff)$" | wc -l)

    # Calculate the nth frame interval
    if [ "$total_frames" -le "$target_frames" ]; then
        nth_frame=1
    else
        nth_frame=$((total_frames / target_frames))
    fi

    # Directory name for the output images
    local dir_name="${img_dir%/}_every_nth_frame"

    # Create directory for output images if it doesn't exist
    mkdir -p "$dir_name"

    # Counter for frame extraction
    frame_counter=0

    # Process and copy every nth image
    for img in "$img_dir"/*.{png,jpg,jpeg,bmp,tiff}; do
        if [ -e "$img" ]; then
            if (( frame_counter % nth_frame == 0 )); then
                cp "$img" "$dir_name/"
            fi
            ((frame_counter++))
        fi
    done

    echo "Conversion completed: $dir_name with every $nth_frame frames"
}

# Prompt user for the directory containing images
read -p "Enter the path to the directory containing image files: " img_dir
if [ ! -d "$img_dir" ]; then
    echo "Directory not found!"
    exit 1
fi

# Prompt user for target amount of frames
read -p "Enter the target amount of frames to keep: " target_frames
if ! [[ "$target_frames" =~ ^[0-9]+$ ]]; then
    echo "Invalid number of frames!"
    exit 1
fi

# Call process_images_nth_frame function with the provided directory and target frames
process_images_nth_frame "$img_dir" "$target_frames"


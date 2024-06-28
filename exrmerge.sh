#!/bin/bash

# Function to display error and exit
function error_exit {
    kdialog --error "$1"
    exit 1
}

# Ensure oiiotool and parallel are available
command -v oiiotool &> /dev/null || error_exit "oiiotool could not be found. Please install OpenImageIO."
command -v parallel &> /dev/null || error_exit "parallel could not be found. Please install GNU Parallel."

# Create the merged directory if it doesn't exist
mkdir -p merged

# Find all _l.exr and _r.exr files in the current directory
left_files=($(find . -maxdepth 1 -name '*_l.exr' | sort))
right_files=($(find . -maxdepth 1 -name '*_r.exr' | sort))

# Check if the number of left and right files is the same
if [ "${#left_files[@]}" -ne "${#right_files[@]}" ]; then
    error_exit "The number of left and right EXR files does not match."
fi

# Create a function for merging
merge_images() {
    left_file="$1"
    right_file="$2"
    base_name="${left_file%_l.exr}"
    output_file="merged/${base_name##*/}.exr"
    oiiotool "$left_file" "$right_file" --mosaic 2x1 --compression dwaa -o "$output_file"
    echo "Merged $left_file and $right_file into $output_file"
}

export -f merge_images

# Pair the left and right files correctly
parallel --link merge_images ::: "${left_files[@]}" ::: "${right_files[@]}"

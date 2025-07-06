#!/bin/bash
# Deploys scripts with `# @nemo` tag to Nemo's right-click menu

# Function to process a directory recursively
process_directory() {
    local root_dir="$1"
    local dir="$2"
    local original_dir=$(pwd)
    local relative_dir="${dir#$root_dir/}"
    local prefix="${relative_dir//\//.}"
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
        # Move the .mp4 files to the root directory with unique names
        for mp4_file in *.mp4; do
            unique_name="${prefix}.${mp4_file}"
            mv "$mp4_file" "$root_dir/$unique_name"
            echo "Moving $mp4_file to the original directory as $unique_name"
        done
    else
        echo "Conversion failed in $dir"
    fi

    cd "$original_dir" || return 1
    echo "Returning to the original directory"
}

# Main script starts here

# Get the root directory
root_dir=$(pwd)

# Get the list of directories to process recursively, excluding the current directory (.)
directories=($(find "$root_dir" -type d | grep -v "^$root_dir\$"))

# Process each directory in parallel
for dir in "${directories[@]}"; do
    process_directory "$root_dir" "$dir" &
done

# Wait for all background processes to finish
wait

echo "Processing complete."

#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 input_file.txt"
    exit 1
fi

# Get the input filename and create the output filename
input_file="$1"
output_file="${input_file%.txt}_formatted.txt"

# Use sed to remove all occurrences of the timestamps (including brackets) and save the output to the new file
sed 's/\[[^]]*\]//g' "$input_file" > "$output_file"

# Inform the user that the file has been processed
echo "Formatted file saved as $output_file"

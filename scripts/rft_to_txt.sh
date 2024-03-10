#!/bin/bash

# Function to convert RTF to TXT
convert_rtf_to_txt() {
    input_file="$1"
    output_file="${input_file%.rtf}.txt"
    unrtf --text "$input_file" > "$output_file"
}

# Iterate through all RTF files in the folder and subfolders
find . -name "*.rtf" -type f | while read -r rtf_file; do
    echo "Converting $rtf_file..."
    convert_rtf_to_txt "$rtf_file"
done

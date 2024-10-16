#!/bin/bash

# Check if a file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 input.json"
    exit 1
fi

# Input JSON file
input_file="$1"

# Output file with "_formatted.txt" suffix
output_file="${input_file%.json}_formatted.txt"

# Extract text, remove timestamps and other info, and add line breaks
jq -r '.chunks[].text' "$input_file" > "$output_file"

echo "Formatted text has been saved to $output_file"

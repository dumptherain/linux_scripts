#!/bin/bash

# Check if an input file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 input.exr"
    exit 1
fi

# Input file
INPUT="$1"

# Check if input file exists
if [ ! -f "$INPUT" ]; then
    echo "Error: Input file '$INPUT' does not exist"
    exit 1
fi

# Check if input file has .exr extension
if [[ ! "$INPUT" =~ \.exr$ ]]; then
    echo "Error: Input file must have .exr extension"
    exit 1
fi

# Output file (replace .exr with .jpg)
OUTPUT="${INPUT%.exr}.jpg"

# Perform the conversion
oiiotool "$INPUT" --colorconvert "role_scene_linear" "out_srgb" -o "$OUTPUT"

# Check if conversion was successful
if [ $? -eq 0 ]; then
    echo "Successfully converted '$INPUT' to '$OUTPUT'"
else
    echo "Error: Conversion failed"
    exit 1
fi

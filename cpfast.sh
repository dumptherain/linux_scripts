#!/usr/bin/env bash

# Robust parallel copy for EXR sequences with digit-pattern placeholders

# Require at least one argument
if [ $# -lt 1 ]; then
    echo "Usage: $0 source_path_with_pattern"
    echo "Example: $0 /mnt/a/work/.../DUST SHOT 03/...####.exr"
    exit 1
fi

# Recombine all provided args into a single path (preserve spaces)
INPUT="$*"

# Extract the directory and filename pattern
SOURCE_DIR=$(dirname "$INPUT")
PATTERN=$(basename "$INPUT")

# Verify source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist."
    exit 1
fi

# Convert each '#' into a digit-matching glob ([0-9])
GLOB_PATTERN=${PATTERN//#/"[0-9]"}

# Use find and xargs -0 to handle arbitrary filenames, copy in parallel
find "$SOURCE_DIR" -name "$GLOB_PATTERN" -print0 | \
    xargs -0 -P 8 -I {} cp "{}" .


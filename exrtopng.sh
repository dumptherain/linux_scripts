#!/bin/bash
# Converts EXR → PNG using oiiotool
# Usage:
#   ./convert_exr_to_png.sh
#   ./convert_exr_to_png.sh file.exr
#   ./convert_exr_to_png.sh *.exr
#   ./convert_exr_to_png.sh -folder   (outputs into ./png/)

shopt -s nullglob

USE_FOLDER=0

# Parse -folder flag
if [[ "$1" == "-folder" ]]; then
    USE_FOLDER=1
    shift
fi

# Determine input files
if [ $# -eq 0 ]; then
    FILES=(*.exr)
    if [ ${#FILES[@]} -eq 0 ]; then
        echo "No .exr files found in current directory."
        exit 0
    fi
else
    FILES=("$@")
fi

# Make output folder if requested
if [ $USE_FOLDER -eq 1 ]; then
    mkdir -p png
fi

# Convert
for INPUT in "${FILES[@]}"; do
    [[ ! -f "$INPUT" ]] && echo "Skipping '$INPUT' (not a file)" && continue
    [[ ! "$INPUT" =~ \.exr$ ]] && echo "Skipping '$INPUT' (not an .exr file)" && continue

    OUTPUT="${INPUT%.exr}.png"
    if [ $USE_FOLDER -eq 1 ]; then
        OUTPUT="png/$(basename "$OUTPUT")"
    fi

    echo "Converting '$INPUT' → '$OUTPUT' ..."
    oiiotool "$INPUT" --colorconvert "role_scene_linear" "out_srgb" -o "$OUTPUT"

    if [ $? -eq 0 ]; then
        echo "✅ $INPUT"
    else
        echo "❌ Error converting '$INPUT'"
    fi
done


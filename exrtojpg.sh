#!/bin/bash
# Convert EXR → JPG. If no inputs, process all *.exr in current directory.
# -folder → place converted JPGs into ./jpg/

USE_FOLDER=0

# Parse -folder flag
if [ "$1" = "-folder" ]; then
    USE_FOLDER=1
    shift
fi

# If no input files passed, use all .exr in CWD
if [ $# -eq 0 ]; then
    set -- *.exr
fi

# If no .exr found
if [ "$1" = "*.exr" ]; then
    echo "No .exr files found."
    exit 1
fi

# Ensure output folder exists if flag is used
if [ $USE_FOLDER -eq 1 ]; then
    mkdir -p jpg
fi

convert_file() {
    local INPUT="$1"
    [[ ! -f "$INPUT" ]] && echo "Missing: $INPUT" && return 1
    [[ ! "$INPUT" =~ \.exr$ ]] && echo "Skip: $INPUT" && return 0

    local OUT="${INPUT%.exr}.jpg"

    if [ $USE_FOLDER -eq 1 ]; then
        OUT="jpg/$(basename "$OUT")"
    fi

    oiiotool "$INPUT" --colorconvert "role_scene_linear" "out_srgb" -o "$OUT"
    [[ $? -eq 0 ]] && echo "$INPUT → $OUT" || echo "Error on $INPUT"
}

EXIT=0
for f in "$@"; do
    convert_file "$f" || EXIT=1
done

exit $EXIT


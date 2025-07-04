#!/bin/bash

# Use the current working directory as the target
TARGET_DIR="."

# Debugging: Print the target directory
echo "Creating folder structure in: $TARGET_DIR"

# Create the folder structure
mkdir -p "${TARGET_DIR}/1-IN"
mkdir -p "${TARGET_DIR}/2-WORK/houdini"
mkdir -p "${TARGET_DIR}/2-WORK/nuke"
mkdir -p "${TARGET_DIR}/2-WORK/blender"
mkdir -p "${TARGET_DIR}/2-WORK/pureref"
mkdir -p "${TARGET_DIR}/3-DAILIES"
mkdir -p "${TARGET_DIR}/4-OUT/yymmdd"
mkdir -p "${TARGET_DIR}/5-CASE"

echo "Folder structure created in ${TARGET_DIR}"


#!/bin/bash

# The target directory is the argument passed to the script
TARGET_DIR="$1"

# Create the folder structure
mkdir -p "${TARGET_DIR}/1-IN"
mkdir -p "${TARGET_DIR}/2-WORK/houdini"
mkdir -p "${TARGET_DIR}/2-WORK/nuke"
mkdir -p "${TARGET_DIR}/2-WORK/blender"
mkdir -p "${TARGET_DIR}/2-WORK/pureref"
mkdir -p "${TARGET_DIR}/3-OUT/yymmdd"
mkdir -p "${TARGET_DIR}/4-CASE"

echo "Folder structure created in ${TARGET_DIR}"

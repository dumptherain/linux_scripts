#!/usr/bin/env bash
# Deploys scripts with `# @nemo` tag to Nemo's right-click menu
# exr_dailies_wrapper.sh - Wrapper for EXR conversion scripts that handles folder selection and dailies organization

set -euo pipefail

# ════════════════════════════════════════════════════════════════════════════════
# 🔧 CONFIGURATION - Change the conversion script here
# ════════════════════════════════════════════════════════════════════════════════

# Default conversion script - change this to switch between different converters
DEFAULT_CONVERSION_SCRIPT="exrtomp4.sh"

# Alternative scripts you can use:
# DEFAULT_CONVERSION_SCRIPT="exrtoprores422.sh"
# DEFAULT_CONVERSION_SCRIPT="exrtoavc.sh"
# DEFAULT_CONVERSION_SCRIPT="exrtodnx.sh"

# ════════════════════════════════════════════════════════════════════════════════

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to find the nearest dailies folder
find_dailies_folder() {
    local current_dir="$1"
    local original_dir="$current_dir"
    
    # Walk up the directory tree
    while [[ "$current_dir" != "/" ]]; do
        # Check for various dailies folder patterns
        for dailies_name in "3-DAILIES" "DAILIES" "dailies"; do
            local dailies_path="$current_dir/$dailies_name"
            if [[ -d "$dailies_path" ]]; then
                echo "$dailies_path"
                return 0
            fi
        done
        current_dir="$(dirname "$current_dir")"
    done
    
    echo "❌ Error: Could not find dailies folder starting from $original_dir"
    return 1
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] <exr_sequence_folder>"
    echo ""
    echo "OPTIONS:"
    echo "  -script <name>   Use specific conversion script (default: $DEFAULT_CONVERSION_SCRIPT)"
    echo "  -fps <number>    Set frame rate (default: 25)"
    echo "  -res <WxH>       Set resolution (default: auto-detect)"
    echo "  -j <number>      Set parallel jobs"
    echo "  -meta            Include metadata overlay"
    echo "  -h, --help       Show this help"
    echo ""
    echo "Available conversion scripts:"
    echo "  exrtomp4.sh      - Convert to MP4 (H.264)"
    echo "  exrtoprores422.sh - Convert to ProRes 422"
    echo "  exrtoavc.sh      - Convert to AVC"
    echo "  exrtodnx.sh      - Convert to DNxHD/DNxHR"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/exr/sequence/folder"
    echo "  $0 -fps 24 -meta /path/to/exr/sequence/folder"
    echo "  $0 -script exrtoprores422.sh -fps 25 /path/to/exr/sequence/folder"
}

# Parse command line arguments
CONVERSION_SCRIPT="$DEFAULT_CONVERSION_SCRIPT"
CONVERSION_ARGS=()
TARGET_FOLDER=""

while (( $# )); do
    case "$1" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -script)
            if [[ $# -lt 2 ]]; then
                echo "❌ Error: -script requires a script name"
                exit 1
            fi
            CONVERSION_SCRIPT="$2"
            shift 2
            ;;
        -fps|-res|-j)
            if [[ $# -lt 2 ]]; then
                echo "❌ Error: $1 requires a value"
                exit 1
            fi
            CONVERSION_ARGS+=("$1" "$2")
            shift 2
            ;;
        -meta)
            CONVERSION_ARGS+=("$1")
            shift
            ;;
        -*)
            echo "❌ Error: Unknown option $1"
            show_usage
            exit 1
            ;;
        *)
            if [[ -n "$TARGET_FOLDER" ]]; then
                echo "❌ Error: Multiple folders specified. Please provide only one folder."
                exit 1
            fi
            TARGET_FOLDER="$1"
            shift
            ;;
    esac
done

# Determine target folder - either from argument or current directory
if [[ -z "$TARGET_FOLDER" ]]; then
    # No folder specified, check if current directory contains EXR files
    if ls *.exr >/dev/null 2>&1; then
        TARGET_FOLDER="$(pwd)"
        echo "🔍 Using current directory as EXR sequence folder"
    else
        echo "❌ Error: No EXR sequence folder specified and current directory contains no EXR files"
        echo ""
        echo "Either:"
        echo "  1. Specify a folder path: $0 /path/to/exr/folder"
        echo "  2. Run from within an EXR sequence folder: cd /path/to/exr/folder && $0"
        exit 1
    fi
else
    echo "🔍 Using specified EXR sequence folder"
fi

# Build the full path to the conversion script
CONVERSION_SCRIPT_PATH="$SCRIPT_DIR/$CONVERSION_SCRIPT"

# Check if conversion script exists
if [[ ! -f "$CONVERSION_SCRIPT_PATH" ]]; then
    echo "❌ Error: Conversion script not found: $CONVERSION_SCRIPT_PATH"
    echo ""
    echo "Available scripts in $SCRIPT_DIR:"
    ls -1 "$SCRIPT_DIR"/*.sh 2>/dev/null | grep -E "(exrto|convert)" | sed 's|.*/||' || echo "  No conversion scripts found"
    exit 1
fi

# Convert to absolute path and verify it exists
TARGET_FOLDER="$(realpath "$TARGET_FOLDER")"
if [[ ! -d "$TARGET_FOLDER" ]]; then
    echo "❌ Error: Directory does not exist: $TARGET_FOLDER"
    exit 1
fi

# Check if the folder contains EXR files (double-check)
if ! ls "$TARGET_FOLDER"/*.exr >/dev/null 2>&1; then
    echo "❌ Error: No EXR files found in $TARGET_FOLDER"
    exit 1
fi

echo "🟢 Starting EXR conversion with $CONVERSION_SCRIPT..."
echo "📁 Target folder: $TARGET_FOLDER"

# Find the dailies folder
echo "🔍 Searching for dailies folder..."
DAILIES_FOLDER=$(find_dailies_folder "$TARGET_FOLDER")
if [[ $? -ne 0 ]]; then
    echo "$DAILIES_FOLDER"  # This will be the error message
    exit 1
fi

echo "📋 Found dailies folder: $DAILIES_FOLDER"

# Create date folder (YYMMDD format)
DATE_FOLDER=$(date +%y%m%d)
DAILIES_DATE_FOLDER="$DAILIES_FOLDER/$DATE_FOLDER"

echo "📅 Creating date folder: $DAILIES_DATE_FOLDER"
mkdir -p "$DAILIES_DATE_FOLDER"

# Change to the target folder and run the conversion
echo "🎬 Starting conversion using $CONVERSION_SCRIPT..."
cd "$TARGET_FOLDER"

# Run the conversion script with the provided arguments
if ! "$CONVERSION_SCRIPT_PATH" "${CONVERSION_ARGS[@]}"; then
    echo "❌ Error: Conversion failed"
    exit 1
fi

# Find the generated video files (multiple formats possible)
VIDEO_FILES=(*.mp4 *.mov *.mkv *.avi *.mxf)
FOUND_FILES=()

for pattern in "${VIDEO_FILES[@]}"; do
    if [[ -f "$pattern" ]]; then
        FOUND_FILES+=("$pattern")
    fi
done

if [[ ${#FOUND_FILES[@]} -eq 0 ]]; then
    echo "❌ Error: No video file was generated"
    exit 1
fi

if [[ ${#FOUND_FILES[@]} -gt 1 ]]; then
    echo "⚠️  Warning: Multiple video files found. Moving all of them."
fi

# Move video files to dailies folder
for video_file in "${FOUND_FILES[@]}"; do
    if [[ -f "$video_file" ]]; then
        echo "📦 Moving $video_file to dailies..."
        mv "$video_file" "$DAILIES_DATE_FOLDER/"
        echo "✅ Successfully moved: $DAILIES_DATE_FOLDER/$video_file"
    fi
done

echo "🎉 Conversion complete! Video files are in: $DAILIES_DATE_FOLDER"

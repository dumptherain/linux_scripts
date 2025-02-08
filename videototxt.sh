#!/bin/bash

# A wrapper script that converts a video (e.g. MKV) to MP3
# and then transcribes it using Whisper, finally copying
# the MP3 to a transcribes folder.

# Usage:
#   mkvtotxt.sh input.mkv [--language lang_code]

# 1) Parse command-line arguments
LANGUAGE="English"
VIDEO_INPUT=""

for arg in "$@"
do
    case $arg in
        --language)
            LANGUAGE="$2"
            shift    # Remove '--language'
            shift    # Remove lang_code
            ;;
        *)
            # Assume first non-flag argument is the input video file
            if [ -z "$VIDEO_INPUT" ]; then
                VIDEO_INPUT="$arg"
            fi
            shift
            ;;
    esac
done

# 2) Check if a video file was provided
if [ -z "$VIDEO_INPUT" ]; then
    echo "Usage: $0 <input_video> [--language lang_code]"
    exit 1
fi

# 3) Convert video to MP3
echo "Converting '$VIDEO_INPUT' to MP3..."
/home/mini/linux_scripts/videotomp3.sh "$VIDEO_INPUT"

# Build the MP3 filename from the input video name
MP3_FILE="${VIDEO_INPUT%.*}.mp3"

# Verify the MP3 was created
if [ ! -f "$MP3_FILE" ]; then
    echo "Error: MP3 file not created."
    exit 1
fi

# 4) Transcribe the MP3
echo "Transcribing '$MP3_FILE' with language '$LANGUAGE'..."
/home/mini/linux_scripts/transcribe.sh "$MP3_FILE" --language "$LANGUAGE"

# 5) Copy the MP3 to the 'transcribes' folder
echo "Copying MP3 to 'transcribes' folder..."
mkdir -p transcribes
mv "$MP3_FILE" transcribes/

echo "All done."


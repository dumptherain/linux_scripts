#!/bin/bash
# Deploys scripts with `# @nemo` tag to Nemo's right-click menu

# Ensure FFmpeg is installed
if ! command -v ffmpeg &> /dev/null
then
    echo "FFmpeg is not installed. Please install FFmpeg and try again."
    exit
fi

# Audio file
AUDIO_FILE="Timberland_NYC_bridge_Sound_V1.wav"

# Check if the audio file exists
if [ ! -f "$AUDIO_FILE" ]; then
    echo "Audio file '$AUDIO_FILE' not found!"
    exit 1
fi

# Loop through all video files in the current directory
for VIDEO_FILE in *.mp4 *.mov *.mkv *.avi *.flv; do
    if [ -f "$VIDEO_FILE" ]; then
        # Extract the filename without extension
        FILENAME="${VIDEO_FILE%.*}"

        # Generate output file name
        OUTPUT_FILE="${FILENAME}_with_audio.${VIDEO_FILE##*.}"

        echo "Processing $VIDEO_FILE..."

        # Add/replace audio track while preserving video settings
        ffmpeg -i "$VIDEO_FILE" -i "$AUDIO_FILE" -c:v copy -map 0:v:0 -map 1:a:0 -shortest -y "$OUTPUT_FILE"

        echo "Created $OUTPUT_FILE"
    fi
done

echo "All video files have been processed."

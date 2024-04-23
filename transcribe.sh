#!/bin/bash

# Initialize variables
LANGUAGE_ARG=""
AUDIO_FILE=""

# Function to get the full path of the directory of a file
get_full_dir() {
  echo "$(cd "$(dirname "$1")" && pwd)"
}

# Parse command-line arguments
for arg in "$@"
do
    case $arg in
        --language)
        LANGUAGE_ARG="--language $2"
        shift # Remove '--language'
        shift # Remove language code
        ;;
        *)
        # Assume it is the audio file path
        if [ -z "$AUDIO_FILE" ]; then
            AUDIO_FILE=$(realpath "$arg")
        fi
        shift # Remove generic argument
        ;;
    esac
done

# Check if an audio file was provided
if [ -z "$AUDIO_FILE" ]; then
    echo "Usage: $0 <audio_file> [--language lang_code]"
    exit 1
fi

# Check if the audio file exists
if [ ! -f "$AUDIO_FILE" ]; then
    echo "Error: Audio file '$AUDIO_FILE' not found."
    exit 1
fi

echo "Audio file located: $AUDIO_FILE"

# Get the full path of the directory where the audio file is located
AUDIO_DIR=$(get_full_dir "$AUDIO_FILE")
echo "Script will run in directory: $AUDIO_DIR"

# Navigate to the directory where Whisper is installed
echo "Navigating to Whisper directory..."
cd /home/pscale/whisper

# Activate the Python environment
echo "Activating Python environment..."
source /home/pscale/whisper/whisper/bin/activate

# Print the current directory and files to confirm the presence of the audio file
echo "Current directory: $(pwd)"
echo "Listing files in audio directory:"
ls -l "$AUDIO_DIR"

# Run Whisper with the audio file provided as an argument
echo "Running Whisper to transcribe audio with language flag $LANGUAGE_ARG..."
whisper "$AUDIO_FILE" $LANGUAGE_ARG > "$AUDIO_DIR/$(basename "$AUDIO_FILE" .wav).txt"

# Check if the output file was created
OUTPUT_FILE="$AUDIO_DIR/$(basename "$AUDIO_FILE" .wav).txt"
if [ -f "$OUTPUT_FILE" ]; then
    echo "Transcription complete: $OUTPUT_FILE"
else
    echo "Failed to create output file."
fi

# Deactivate the Python environment
echo "Deactivating Python environment..."
deactivate


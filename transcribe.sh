#!/bin/bash

# Capture the directory from which the script was launched
START_DIR="$(pwd)"

# Initialize variables with default language set to English
LANGUAGE_ARG="--language English"
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
cd /home/mini/whisper

# Activate the Python environment
echo "Activating Python environment..."
source /home/mini/whisper/whisper_env/bin/activate

# Print the current directory and files to confirm the presence of the audio file
echo "Current directory: $(pwd)"
echo "Listing files in audio directory:"
ls -l "$AUDIO_DIR"

# Run Whisper with the audio file provided as an argument
OUTPUT_FILE="$AUDIO_DIR/$(basename "$AUDIO_FILE" .wav).txt"
echo "Running Whisper to transcribe audio with language flag $LANGUAGE_ARG..."
whisper "$AUDIO_FILE" $LANGUAGE_ARG --device cuda > "$OUTPUT_FILE"

# Check if the output file was created
if [ -f "$OUTPUT_FILE" ]; then
    echo "Transcription complete: $OUTPUT_FILE"

    # ================================================
    #  Run formattxt.sh to format the transcription
    # ================================================
    echo "Running formattxt.sh to format the transcription..."
    # If formattxt.sh is in your PATH, you can just use:
    #   formattxt.sh "$OUTPUT_FILE"
    # Otherwise, provide the full path, e.g.:
    #   /home/mini/whisper/formattxt.sh "$OUTPUT_FILE"
    /home/mini/linux_scripts/formattxt.sh "$OUTPUT_FILE"

    # If formattxt.sh produces a new file, e.g.:
    FORMATTED_FILE="$AUDIO_DIR/$(basename "$AUDIO_FILE" .wav)_formatted.txt"

    # Create the 'transcribes' folder where this script was originally launched
    mkdir -p "$START_DIR/transcribes"

    # Move the original .txt file
    mv "$OUTPUT_FILE" "$START_DIR/transcribes/"
    echo "Moved original transcription to: $START_DIR/transcribes/"

    # If the formatted file exists, move that too
    if [ -f "$FORMATTED_FILE" ]; then
        mv "$FORMATTED_FILE" "$START_DIR/transcribes/"
        echo "Moved formatted transcription to: $START_DIR/transcribes/"
    else
        echo "No separate formatted file found."
    fi
else
    echo "Failed to create output file."
fi

# Deactivate the Python environment
echo "Deactivating Python environment..."
deactivate


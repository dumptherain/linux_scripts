#!/bin/bash

WATCH_DIR="/mnt/a/refs"
GIF_DIR="$WATCH_DIR/gif"
VIDEOS_DIR="$WATCH_DIR/videos"
FPS=24

# Create required directories
mkdir -p "$GIF_DIR" "$VIDEOS_DIR"

# Function to convert a video file if needed and move it
convert_video() {
    local file="$1"
    [ -f "$file" ] || return 1

    local base
    base=$(basename "${file%.*}")
    local gif_file="$GIF_DIR/${base}.gif"

    if [ -f "$gif_file" ]; then
        echo "GIF already exists for $file, moving video."
        mv "$file" "$VIDEOS_DIR"
        return 0
    fi

    echo "Converting $file..."
    local palette
    palette=$(mktemp /tmp/palette.XXXXXX.png)
    ffmpeg -y -i "$file" -vf "fps=$FPS,scale=trunc(iw/4)*2:trunc(ih/4)*2,palettegen=max_colors=64" "$palette"
    ffmpeg -y -i "$file" -i "$palette" -filter_complex "fps=$FPS,scale=trunc(iw/4)*2:trunc(ih/4)*2[x];[x][1:v]paletteuse" "$gif_file"
    rm "$palette"
    mv "$file" "$VIDEOS_DIR"
    echo "Converted and moved $file."
}

# Initial scan: process all video files in the base folder
for file in "$WATCH_DIR"/*; do
    case "$file" in
        *.mp4|*.mov|*.avi|*.mkv|*.flv|*.wmv)
            convert_video "$file"
            ;;
    esac
done

# Ensure inotifywait is installed
command -v inotifywait >/dev/null 2>&1 || { echo "inotifywait is required but not installed. Aborting." >&2; exit 1; }

# Monitor the base folder for new video files
inotifywait -m -e close_write --format '%w%f' "$WATCH_DIR" | while read NEWFILE; do
    case "$NEWFILE" in
        *.mp4|*.mov|*.avi|*.mkv|*.flv|*.wmv)
            convert_video "$NEWFILE"
            ;;
        *)
            echo "Ignoring non-video file: $NEWFILE"
            ;;
    esac
done


#!/bin/bash

WATCH_DIR="/mnt/a/refs"
VIDEOS_DIR="$WATCH_DIR/videos"

mkdir -p "$VIDEOS_DIR"

# Ensure inotifywait is installed
command -v inotifywait >/dev/null 2>&1 || { echo "inotifywait is required but not installed. Aborting." >&2; exit 1; }

inotifywait -m -e close_write --format '%w%f' "$WATCH_DIR" | while read NEWFILE; do
    # Skip directories and files already in the videos folder
    [ -d "$NEWFILE" ] && continue
    [[ "$NEWFILE" == "$VIDEOS_DIR/"* ]] && continue

    case "$NEWFILE" in
        *.mp4|*.mov|*.avi|*.mkv|*.flv|*.wmv)
            echo "Moving video file: $NEWFILE"
            mv "$NEWFILE" "$VIDEOS_DIR"
            ;;
        *)
            echo "Ignoring non-video file: $NEWFILE"
            ;;
    esac
done


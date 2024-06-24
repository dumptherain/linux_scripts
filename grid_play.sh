#!/bin/bash

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <video1> <video2> ... <videoN>"
    exit 1
fi

# Number of video files
NUM_VIDEOS=$#

# Calculate grid dimensions (rows and columns)
COLUMNS=$(echo "scale=0; sqrt($NUM_VIDEOS)" | bc)
if [ $(($COLUMNS * $COLUMNS)) -lt $NUM_VIDEOS ]; then
    COLUMNS=$(($COLUMNS + 1))
fi
ROWS=$(($NUM_VIDEOS / $COLUMNS))
if [ $(($ROWS * $COLUMNS)) -lt $NUM_VIDEOS ]; then
    ROWS=$(($ROWS + 1))
fi

# Get screen dimensions
SCREEN_WIDTH=$(xdpyinfo | awk '/dimensions:/ {print $2}' | cut -d'x' -f1)
SCREEN_HEIGHT=$(xdpyinfo | awk '/dimensions:/ {print $2}' | cut -d'x' -f2)

# Calculate window size
WINDOW_WIDTH=$((SCREEN_WIDTH / COLUMNS))
WINDOW_HEIGHT=$((SCREEN_HEIGHT / ROWS))

# Launch mpv instances
i=0
for video in "$@"; do
    ROW=$((i / COLUMNS))
    COL=$((i % COLUMNS))
    X=$((COL * WINDOW_WIDTH))
    Y=$((ROW * WINDOW_HEIGHT))

    mpv --geometry=${WINDOW_WIDTH}x${WINDOW_HEIGHT}+$X+$Y --autofit=$WINDOW_WIDTHx$WINDOW_HEIGHT --no-border "$video" &

    i=$((i + 1))
done

# Wait a bit to ensure all windows are open
sleep 5

# Get all mpv window IDs
MPV_WINDOW_IDS=$(wmctrl -l | grep -i mpv | awk '{print $1}')

# Group the windows using wmctrl
for WINDOW_ID in $MPV_WINDOW_IDS; do
    wmctrl -ir $WINDOW_ID -b add,maximized_vert,maximized_horz
done

wait

#!/usr/bin/env bash
set -euo pipefail

echo "Scanning for active video devices..."

VIDEO_DEV=""
for dev in /dev/video*; do
  if [[ -c "$dev" ]]; then
    if v4l2-ctl --device="$dev" --all &>/dev/null; then
      if v4l2-ctl --device="$dev" --list-formats-ext | grep -q "Size: Discrete"; then
        VIDEO_DEV="$dev"
        break
      fi
    fi
  fi
done

if [[ -z "$VIDEO_DEV" ]]; then
  echo "No active webcam found."
  exit 1
fi

echo "Found active webcam: $VIDEO_DEV"

# Try to get the first supported resolution
RES=$(v4l2-ctl --device="$VIDEO_DEV" --list-formats-ext 2>/dev/null | awk '
  /Size: Discrete/ && !found++ {
    match($0, /[0-9]+x[0-9]+/, res);
    print res[0];
    exit
  }
')

if [[ -z "$RES" ]]; then
  echo "Could not extract resolution. Falling back to 1920x1080 @ 30 FPS."
  RES="1920x1080"
fi

FPS="30"  # Default fallback

echo "Launching webcam feed: $VIDEO_DEV at $RES $FPS FPS"
exec mpv "av://v4l2:$VIDEO_DEV" --profile=low-latency --untimed \
  --demuxer-lavf-o=video_size=$RES --demuxer-lavf-o=framerate=$FPS


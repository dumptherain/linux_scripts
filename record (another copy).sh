#!/usr/bin/env bash
# record_dual_sync.sh — desktop 30 FPS + webcam + audio, remuxed to .mov

set -euo pipefail

###############################################################################
# CONFIGURATION
###############################################################################
WEBCAM_RES="3840x2160"
WEBCAM_FPS=30
WEBCAM_PIXFMT="yuyv422"

AUDIO_DEV="alsa_input.usb-ZOOM_Corporation_ZOOM_P4_Audio_000000000000-00.iec958-stereo"

NVENC_PRESET="p3"  # faster than p7, still great quality
DEFAULT_OUT_DIR="$HOME/Videos/recording"
MONITOR_FPS=30
###############################################################################

############################
# Parse args
############################
BASE_OUT_DIR="${1:-$DEFAULT_OUT_DIR}"

############################
# Make daily folder (YYYYMMDD)
############################
DAY_DIR="$(date +%Y%m%d)"
OUT_DIR="${BASE_OUT_DIR}/${DAY_DIR}"
mkdir -p "$OUT_DIR"

############################
# Detect primary monitor geometry
############################
primary_line=$(xrandr | grep ' connected primary')
MONITOR_GEOM=$(echo "$primary_line" | grep -o '[0-9]\+x[0-9]\++[0-9]\++[0-9]\+')
MONITOR_RES=$(echo "$MONITOR_GEOM" | cut -d'+' -f1)
MONITOR_XOFF=$(echo "$MONITOR_GEOM" | cut -d'+' -f2)
MONITOR_YOFF=$(echo "$MONITOR_GEOM" | cut -d'+' -f3)

############################
# Output paths
############################
ts=$(date +%Y%m%d_%H%M%S)
desktop_out="${OUT_DIR}/desktop_${ts}_30fps.mkv"
webcam_out="${OUT_DIR}/webcam_${ts}.mkv"

############################
# Find first working webcam
############################
WEBCAM_DEV=""
for dev in /dev/video*; do
  if ffmpeg -f v4l2 -video_size "$WEBCAM_RES" -framerate "$WEBCAM_FPS" \
           -pixel_format "$WEBCAM_PIXFMT" -t 1 -loglevel error \
           -i "$dev" -f null - 2>/dev/null; then
    WEBCAM_DEV="$dev"
    break
  fi
done

if [[ -n "$WEBCAM_DEV" ]]; then
  echo "🟢 Webcam available: $WEBCAM_DEV — will be recorded"
  USE_WEBCAM=true
else
  echo "🟡 No working webcam found — skipping webcam recording"
  USE_WEBCAM=false
fi

############################
# Info
############################
echo "▶︎ Monitor : ${MONITOR_RES}@${MONITOR_FPS} offset +${MONITOR_XOFF},${MONITOR_YOFF}"
echo "▶︎ Audio   : ${AUDIO_DEV}"
echo "▶︎ Desktop : ${desktop_out}"
$USE_WEBCAM && echo "▶︎ Webcam  : ${webcam_out}"
echo "(Press 'q' in the FFmpeg window to stop recording)"

############################
# Run FFmpeg
############################
ffmpeg \
  -thread_queue_size 1024 \
  -f x11grab -video_size "$MONITOR_RES" -framerate "$MONITOR_FPS" \
    -fflags nobuffer -flags low_delay \
    -use_wallclock_as_timestamps 1 -i ":0.0+${MONITOR_XOFF},${MONITOR_YOFF}" \
  $( $USE_WEBCAM && printf '%s ' \
    -thread_queue_size 1024 -f v4l2 -video_size "$WEBCAM_RES" \
    -framerate "$WEBCAM_FPS" -pixel_format "$WEBCAM_PIXFMT" \
    -use_wallclock_as_timestamps 1 -i "$WEBCAM_DEV" ) \
  -thread_queue_size 512 -f pulse -i "$AUDIO_DEV" \
  -copyts -start_at_zero -vsync vfr \
  \
  -map 0:v -map $( $USE_WEBCAM && echo "2" || echo "1" ):a \
    -c:v h264_nvenc -preset "$NVENC_PRESET" -rc constqp -qp 18 \
    -c:a aac -b:a 192k "$desktop_out" \
  \
  $( $USE_WEBCAM && printf '%s ' \
    -map 1:v -map 2:a -c:v h264_nvenc -preset "$NVENC_PRESET" \
    -qp 23 -c:a aac -b:a 192k "$webcam_out" )

############################
# Remux to .mov for Resolve
############################
echo "🔁 Remuxing to .mov with PCM audio for Resolve…"

# Remux desktop video
desktop_mov="${desktop_out%.mkv}.mov"
ffmpeg -y -i "$desktop_out" \
  -c:v copy \
  -c:a pcm_s16le -ar 48000 -ac 2 \
  -movflags +faststart \
  "$desktop_mov"

# Remux webcam video (if recorded)
if [[ "$USE_WEBCAM" == true ]]; then
  webcam_mov="${webcam_out%.mkv}.mov"
  ffmpeg -y -i "$webcam_out" \
    -c:v copy \
    -c:a pcm_s16le -ar 48000 -ac 2 \
    -movflags +faststart \
    "$webcam_mov"
fi

# Optional cleanup (uncomment to remove original MKVs)
# rm -f "$desktop_out"
# $USE_WEBCAM && rm -f "$webcam_out"

echo "✅ Done: Files saved to $OUT_DIR (mov + audio compatible with Resolve)"


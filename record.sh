#!/usr/bin/env bash
# record_dual_sync.sh — GPU desktop + webcam + audio recorder with mpv preview and smart detection

set -euo pipefail

###############################################################################
# CONFIGURATION
###############################################################################
WEBCAM_RES="1920x1080"
WEBCAM_FPS=30
WEBCAM_PIXFMT="yuyv422"

AUDIO_DEV="alsa_input.usb-ZOOM_Corporation_ZOOM_P4_Audio_000000000000-00.iec958-stereo"

NVENC_PRESET="p7"
DEFAULT_OUT_DIR="$HOME/Videos"
###############################################################################

############################
# Parse args
############################
PREVIEW=false
OUT_DIR="$DEFAULT_OUT_DIR"

for arg in "$@"; do
  case "$arg" in
    -preview) PREVIEW=true ;;
    *)        OUT_DIR="$arg" ;;
  esac
done

############################
# Detect primary monitor
############################
primary_line=$(xrandr | grep ' connected primary')
MONITOR_RES=$(echo "$primary_line" | grep -o '[0-9]\+x[0-9]\+')
MONITOR_OFFSET=$(echo "$primary_line" | grep -o '+[0-9]\++[0-9]\+')
MONITOR_FPS=60

############################
# Output paths
############################
ts=$(date +%Y%m%d_%H%M%S)
mkdir -p "$OUT_DIR"
desktop_out="${OUT_DIR}/desktop_${ts}.mkv"
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
echo "▶︎ Monitor : ${MONITOR_RES}@${MONITOR_FPS} offset ${MONITOR_OFFSET}"
echo "▶︎ Audio   : ${AUDIO_DEV}"
echo "▶︎ Desktop : ${desktop_out}"
$USE_WEBCAM && echo "▶︎ Webcam  : ${webcam_out}"
$PREVIEW && echo "▶︎ Previews: ENABLED (via mpv)"
echo "(Press 'q' in the FFmpeg window to stop recording)"

############################
# Live previews using mpv
############################
if $PREVIEW; then
  if ! command -v mpv >/dev/null; then
    echo "❌ mpv not installed, cannot show preview"
  else
    mpv --profile=low-latency --no-audio --no-osc --no-border --ontop \
        --geometry=50%:5% --title="Desktop Preview" \
        --window-scale=0.25 --vo=gpu \
        --demuxer-lavf-o=video_size=${MONITOR_RES},framerate=${MONITOR_FPS} \
        --fs=no "x11grab::0.0${MONITOR_OFFSET}" >/dev/null 2>&1 &
    PREVIEW_PIDS=($!)

    if $USE_WEBCAM; then
      mpv --profile=low-latency --no-audio --no-osc --no-border --ontop \
          --geometry=75%:5% --title="Webcam Preview" \
          --window-scale=0.25 --vo=gpu \
          --demuxer-lavf-o=video_size=${WEBCAM_RES},framerate=${WEBCAM_FPS},pixel_format=${WEBCAM_PIXFMT} \
          --fs=no "v4l2://${WEBCAM_DEV}" >/dev/null 2>&1 &
      PREVIEW_PIDS+=($!)
    fi
  fi
fi

############################
# Run FFmpeg
############################
ffmpeg \
  -thread_queue_size 1024 \
  -f x11grab -video_size "$MONITOR_RES" -framerate "$MONITOR_FPS" \
    -use_wallclock_as_timestamps 1 -i ":0.0${MONITOR_OFFSET}" \
  $( $USE_WEBCAM && printf '%s ' \
    -thread_queue_size 1024 -f v4l2 -video_size "$WEBCAM_RES" \
    -framerate "$WEBCAM_FPS" -pixel_format "$WEBCAM_PIXFMT" \
    -use_wallclock_as_timestamps 1 -i "$WEBCAM_DEV" ) \
  -thread_queue_size 512 -f pulse -i "$AUDIO_DEV" \
  -copyts -start_at_zero -vsync 0 \
  \
  -map 0:v -map $( $USE_WEBCAM && echo "2" || echo "1" ):a \
    -c:v h264_nvenc -preset "$NVENC_PRESET" -rc vbr -b:v 50M -maxrate 60M -bufsize 100M \
    -c:a aac -b:a 320k "$desktop_out" \
  \
  $( $USE_WEBCAM && printf '%s ' \
    -map 1:v -map 2:a -c:v h264_nvenc -preset "$NVENC_PRESET" \
    -qp 23 -c:a aac -b:a 320k "$webcam_out" )

############################
# Cleanup previews
############################
if $PREVIEW; then
  for pid in "${PREVIEW_PIDS[@]:-}"; do
    kill "$pid" 2>/dev/null || true
  done
fi


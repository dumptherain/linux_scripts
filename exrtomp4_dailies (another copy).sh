#!/bin/bash
export LC_NUMERIC=C
set -eEuo pipefail
trap 'echo "❌ Error on line $LINENO. Exiting."' ERR

echo "Starting EXR-to-MP4 script with parallel..."

# Get first EXR
first_exr=$(find . -maxdepth 1 -name "*.exr" | sort -V | head -n1)
first_exr=${first_exr#./}
if [ -z "$first_exr" ]; then
    echo "❌ No EXR files found in $(pwd)"
    exit 1
fi

# Extract resolution
res=$(identify -format "%wx%h" "$first_exr")
width=$(echo "$res" | cut -dx -f1)
height=$(echo "$res" | cut -dx -f2)
((width % 2 != 0)) && ((width--))
((height % 2 != 0)) && ((height--))
res="${width}x${height}"
echo "Using resolution: $res"

# Default FPS
fps=24

# Parse CLI args
while (( "$#" )); do
  case "$1" in
    -fps) fps=$2; shift 2 ;;
    -res) res=$2; shift 2 ;;
    --) shift; break ;;
    -*|--*=) echo "Unsupported flag $1" >&2; exit 1 ;;
  esac
done

# Create temp dir and copy EXRs
tmpdir=$(mktemp -d -p "./")
echo "Temporary dir: $tmpdir"
cp ./*.exr "$tmpdir"
pushd "$tmpdir" > /dev/null

#######################################
# Extract metadata per EXR in parallel
#######################################
echo "Extracting metadata in parallel..."
find . -maxdepth 1 -name '*.exr' | sort -V | parallel --halt soon,fail=1 '
  f={}
  info=$(oiiotool -info -v "$f")
  frame=$(echo "$info" | awk "/frame: / {print \$2}")
  fps_tag=$(echo "$info" | awk "/FramesPerSecond/ {print \$2}")
  software=$(echo "$info" | grep -oP "Software: \K.*")
  host=$(echo "$info" | grep -oP "HostComputer: \K.*")
  datetime=$(echo "$info" | grep -oP "DateTime: \K.*")
  mem=$(echo "$info" | grep -oP "renderMemory_s: \K.*")
  comp=$(echo "$info" | grep -oP "compression: \K.*")
  colorspace=$(echo "$info" | grep -oP "oiio:ColorSpace: \K.*")
  rth=$(echo "$info" | sed -n "s/.*renderTime_s: \"\(.*\)\"/\1/p")
  IFS=: read -r h m s <<< "${rth:-0:00:00}"
  rt=$(awk -v h="$h" -v m="$m" -v s="$s" "BEGIN { printf \"%.2f\", h*3600 + m*60 + s }")
  echo "$f|$frame|$fps_tag|$software|$host|$datetime|$mem|$comp|$colorspace|$rt|$rth"
' > metadata.txt

#######################################
# Sum total render time across all EXRs
#######################################
total_rendertime=$(awk -F'|' '{sum += $10} END {printf "%.4f\n", sum}' metadata.txt)
printf -v total_rendertime_hms '%02d:%02d:%05.2f' $(echo "$total_rendertime" | awk '{ h=int($1/3600); m=int(($1%3600)/60); s=$1%60; print h, m, s }')
echo "Total render time: $total_rendertime_hms"

#######################################
# Convert to JPGs with metadata burn-in
#######################################
echo "Converting frames with burn-in overlay..."
cat metadata.txt | sort -V | while IFS='|' read -r f frame fps_tag software host datetime mem comp colorspace rt rth; do
  echo "Processing $f..."
  oiiotool "$f" --ch "R,G,B" \
    --colorconvert "ACES - ACEScg" "Output - sRGB" \
    --text:x=40:y=40:size=28 "Frame: ${frame:-N/A}   FPS: ${fps_tag:-$fps}" \
    --text:x=40:y=80:size=28 "RenderTime: ${rth:-N/A}" \
    --text:x=40:y=120:size=28 "Software: ${software:-Unknown}" \
    --text:x=40:y=160:size=28 "Host: ${host:-Unknown}" \
    --text:x=40:y=200:size=28 "Mem: ${mem:-?}   Comp: ${comp:-?}" \
    --text:x=40:y=240:size=28 "ColorSpace: ${colorspace:-?}" \
    --text:x=40:y=280:size=28 "Date: ${datetime:-?}" \
    --text:x=40:y=320:size=28 "TotalRender: $total_rendertime_hms" \
    -o "${f%.exr}_converted.jpg"
done

#######################################
# Stitch to MP4
#######################################
echo "Stitching frames..."
ls *_converted.jpg | sort -V | sed 's/^/file /' > files.txt
output_filename=$(basename "$first_exr" .exr).mp4
ffmpeg -y -f concat -safe 0 -i files.txt -c:v libx264 -pix_fmt yuv420p -r "$fps" -s "$res" "$output_filename"

# Move result
popd > /dev/null
mv "$tmpdir/$output_filename" .
rm -r "$tmpdir"

echo "✅ Script completed successfully. Output: $output_filename"


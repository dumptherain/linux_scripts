#!/usr/bin/env bash
# exrtomp4_dailies.sh – fast EXR → burn-in JPG → MP4 dailies
# Requires: GNU parallel, oiiotool, ffmpeg, ImageMagick (identify)

################################################################################
#  CONFIG
################################################################################
export LC_NUMERIC=C          # ensure decimal point is “.”
set -euo pipefail            # fail fast, catch errors

PARALLEL_JOBS=""             # leave empty = let GNU parallel choose
DEFAULT_FPS=25               # change to taste
################################################################################

echo "🟢  Starting EXR-to-MP4 script …"

# ───────────────────────────── 1. Sanity checks ──────────────────────────────
command -v parallel >/dev/null || { echo "GNU parallel not found"; exit 1; }
command -v oiiotool  >/dev/null || { echo "oiiotool not found";  exit 1; }
command -v ffmpeg    >/dev/null || { echo "ffmpeg not found";    exit 1; }
command -v identify  >/dev/null || { echo "ImageMagick identify not found"; exit 1; }

shopt -s nullglob
exrs=( *.exr )
(( ${#exrs[@]} )) || { echo "No EXR files here. Exiting."; exit 1; }
first_exr=$(printf '%s\n' "${exrs[@]}" | sort -V | head -n1)
echo "First EXR : $first_exr"

# ───────────────────────────── 2. Resolution / FPS ───────────────────────────
res=$(identify -format "%wx%h" "$first_exr")
echo "Raw resolution: $res"

# ensure even dimensions
width=${res%x*}; height=${res#*x}
(( width  & 1 )) && ((width--))
(( height & 1 )) && ((height--))
res="${width}x${height}"
fps=$DEFAULT_FPS

# CLI flags
while (( $# )); do
  case "$1" in
    -fps) fps="$2"; shift 2 ;;
    -res) res="$2"; shift 2 ;;
    -j)   PARALLEL_JOBS="$2"; shift 2 ;;
    --)   shift; break ;;
    *)    echo "Unknown flag $1"; exit 1 ;;
  esac
done
echo "Using  FPS=$fps , final resolution $res"

# ───────────────────────────── 3. Temp workspace ─────────────────────────────
tmpdir=$(mktemp -d -p .)
echo "Temp dir: $tmpdir"
cp ./*.exr "$tmpdir/"
pushd "$tmpdir" >/dev/null

################################################################################
# 4. METADATA EXTRACTION  (parallel)
################################################################################
echo "🔍  Extracting metadata …"
find . -maxdepth 1 -name '*.exr' | sort -V | \
parallel ${PARALLEL_JOBS:+-j "$PARALLEL_JOBS"} --halt soon,fail=1 --line-buffer '
  f={}
  info=$(oiiotool -info -v "$f")
  printf "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s\n" \
    "$f" \
    "$(awk "/frame: /      {print \$2}" <<<"$info")" \
    "$(awk "/FramesPerSecond/ {print \$2}" <<<"$info")" \
    "$(grep -oP "Software: \K.*"       <<<"$info")" \
    "$(grep -oP "HostComputer: \K.*"   <<<"$info")" \
    "$(grep -oP "DateTime: \K.*"       <<<"$info")" \
    "$(grep -oP "renderMemory_s: \K.*" <<<"$info")" \
    "$(grep -oP "compression: \K.*"    <<<"$info")" \
    "$(grep -oP "oiio:ColorSpace: \K.*"<<<"$info")" \
    "$(grep -oP "renderTime: \K[0-9.]+"<<<"$info" || echo 0)" \
    "$(sed -n "s/.*renderTime_s: \"\(.*\)\"/\1/p" <<<"$info")"
' > metadata.txt

# cumulative render time → H:M:S
total_rt_sec=$(awk -F'|' '{sum+=$10} END{printf "%.4f",sum}' metadata.txt)
printf -v total_rt_hms '%02d:%02d:%05.2f' \
        $(awk -v t="$total_rt_sec" 'BEGIN{h=int(t/3600); m=int((t%3600)/60); s=t%60; print h,m,s}')

echo "⏱  Total render time: $total_rt_hms"

################################################################################
# 5. EXR ➜ JPG WITH BURN-INS  (parallel)
################################################################################
echo "🎨  Converting EXR → JPG with burn-ins …"
cat metadata.txt | sort -V | \
parallel ${PARALLEL_JOBS:+-j "$PARALLEL_JOBS"} --colsep '\|' --halt soon,fail=1 --line-buffer '
  f={1}; frame={2}; fps_tag={3}; software={4}; host={5}; datetime={6};
  mem={7}; comp={8}; colorspace={9}; rth={11};

  oiiotool "$f" --ch "R,G,B" \
    --colorconvert "ACES - ACEScg" "Output - sRGB" \
    --text:x=40:y=40:size=28 "Frame: ${frame:-N/A}   FPS: ${fps_tag:-'"$fps"'}" \
    --text:x=40:y=80:size=28  "RenderTime: ${rth:-N/A}" \
    --text:x=40:y=120:size=28 "Software: ${software:-Unknown}" \
    --text:x=40:y=160:size=28 "Host: ${host:-Unknown}" \
    --text:x=40:y=200:size=28 "Mem: ${mem:-?}   Comp: ${comp:-?}" \
    --text:x=40:y=240:size=28 "ColorSpace: ${colorspace:-?}" \
    --text:x=40:y=280:size=28 "Date: ${datetime:-?}" \
    --text:x=40:y=320:size=28 "TotalRender: '"$total_rt_hms"'" \
    -o "${f%.exr}_converted.jpg"
'

################################################################################
# 6. ASSEMBLE MP4
################################################################################
echo "📜  Preparing list for FFmpeg …"
ls *_converted.jpg | sort -V | sed "s|^|file \'|" | sed "s|$|\'|" > files.txt
out_base=$(basename "$first_exr" .exr | sed -E 's/\.[0-9]+$//')
out_mp4="${out_base}.mp4"
echo "🎞  Encoding MP4 → $out_mp4"
ffmpeg -y -loglevel error -f concat -safe 0 -i files.txt \
       -c:v libx264 -pix_fmt yuv420p -r "$fps" -s "$res" "$out_mp4"

################################################################################
# 7. CLEAN-UP
################################################################################
popd >/dev/null
mv "$tmpdir/$out_mp4" .
rm -rf "$tmpdir"
echo "✅  Done – output is $out_mp4"


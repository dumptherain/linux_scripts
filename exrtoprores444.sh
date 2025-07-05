#!/usr/bin/env bash

# exrtoprores444.sh – fast EXR → PNG → ProRes444 MOV converter with optional metadata overlay

export LC_NUMERIC=C
set -euo pipefail

PARALLEL_JOBS=""
DEFAULT_FPS=25
INCLUDE_META=false

echo "🟢  Starting EXR-to-MOV script …"

# ──────────────────────── 1. Check tools and arguments ─────────────────────
for tool in parallel oiiotool ffmpeg identify; do
  command -v "$tool" >/dev/null || { echo "$tool not found"; exit 1; }
done

fps=$DEFAULT_FPS
while (( $# )); do
  case "$1" in
    -fps)  fps="$2"; shift 2 ;;
    -res)  res="$2"; shift 2 ;;
    -j)    PARALLEL_JOBS="$2"; shift 2 ;;
    -meta) INCLUDE_META=true; shift ;;
    --)    shift; break ;;
    *)     echo "Unknown flag $1"; exit 1 ;;
  esac
done

# ──────────────────────── 2. EXR discovery ─────────────────────────────
shopt -s nullglob
exrs=( *.exr )
(( ${#exrs[@]} )) || { echo "No EXR files found. Exiting."; exit 1; }

first_exr=$(printf '%s\n' "${exrs[@]}" | sort -V | head -n1)
if [ -z "${res-}" ]; then
  res=$(identify -format "%wx%h" "$first_exr")
fi
width=${res%x*}; height=${res#*x}
(( width  &= ~1 ))
(( height &= ~1 ))
res="${width}x${height}"

echo "First EXR: $first_exr"
echo "Using FPS=$fps , Resolution=$res"
echo "Metadata overlay: $INCLUDE_META"

# ───────────────────────── 3. Temp workspace ─────────────────────────────
tmpdir=$(mktemp -d -p .)
tmpdir=$(cd "$tmpdir" && pwd)  # absolute path
export tmpdir
echo "Temp dir: $tmpdir"

# ───────────────────────── 4. Optional Metadata ──────────────────────────
if $INCLUDE_META; then
  echo "🔍 Extracting metadata …"
  find . -maxdepth 1 -name '*.exr' | sort -V | \
  parallel ${PARALLEL_JOBS:+-j "$PARALLEL_JOBS"} --halt soon,fail=1 --line-buffer '
    f={}
    info=$(oiiotool -info -v "$f")

    frame=$(awk "/^    frame:/            {print \$2; exit}" <<<"$info")
    fps_tag=$(awk "/^    FramesPerSecond:/  {print \$2; exit}" <<<"$info")
    software=$(grep -oP "^    Software: \"\K.*(?=\")"       <<<"$info")
    host=$(grep -oP "^    HostComputer: \"\K.*(?=\")"     <<<"$info")
    datetime=$(grep -oP "^    DateTime: \"\K.*(?=\")"      <<<"$info")
    mem=$(grep -oP "^    renderMemory_s: \"\K.*(?=\")"     <<<"$info")
    comp=$(grep -oP "^    compression: \"\K.*(?=\")"       <<<"$info")
    colorspace=$(grep -oP "^    oiio:ColorSpace: \"\K.*(?=\")" <<<"$info")
    rt_sec=$(grep -oP "^    renderTime: \K[0-9.]+"         <<<"$info" || echo 0)
    rt_hms=$(grep -oP "^    renderTime_s: \"\K.*(?=\")"    <<<"$info")

    gpu_label=$(grep -oP "\"xpu_device_label\":\"\K[^\"]+"    <<<"$info" | sed -n 1p)
    gpu_pct=$(grep -oP "\"xpu_device_contrib\":\K[0-9.]+" <<<"$info" | sed -n 1p)
    cpu_label=$(grep -oP "\"xpu_device_label\":\"\K[^\"]+"    <<<"$info" | sed -n 2p)
    cpu_pct=$(grep -oP "\"xpu_device_contrib\":\K[0-9.]+" <<<"$info" | sed -n 2p)

    printf "%s|%s|%s|\"%s\"|\"%s\"|\"%s\"|\"%s\"|\"%s\"|\"%s\"|%s|%s|\"%s\"|%s|\"%s\"|%s\n" \
      "$f" "$frame" "$fps_tag" \
      "$software" "$host" "$datetime" \
      "$mem" "$comp" "$colorspace" \
      "$rt_sec" "$rt_hms" \
      "$gpu_label" "$gpu_pct" \
      "$cpu_label" "$cpu_pct"
  ' > "$tmpdir/metadata.txt"

  total_rt_sec=$(awk -F'|' '{sum+=$10} END{printf "%.4f",sum}' "$tmpdir/metadata.txt")
  printf -v total_rt_hms '%02d:%02d:%05.2f' \
          $(awk -v t="$total_rt_sec" 'BEGIN{h=int(t/3600); m=int((t%3600)/60); s=t%60; print h,m,s}')
  echo "⏱  Total render time: $total_rt_hms"
fi

# ──────────────────── 5. EXR → PNG Conversion ───────────────────────────
echo "🎨 Converting ${#exrs[@]} EXRs to PNGs …"
PAR_CMD=( parallel --halt soon,fail=1 --line-buffer )
[ -n "$PARALLEL_JOBS" ] && PAR_CMD+=( -j "$PARALLEL_JOBS" )

if $INCLUDE_META; then
  cat "$tmpdir/metadata.txt" | sort -V | \
  "${PAR_CMD[@]}" --colsep '\|' '
    f={1}; frame={2}; fps_tag={3}; software={4}; host={5}; datetime={6};
    mem={7}; comp={8}; colorspace={9}; rt_sec={10}; rt_hms={11};
    gpu_label={12}; gpu_pct={13}; cpu_label={14}; cpu_pct={15};
    
    name=${f##*/}; base=${name%.exr}
    out="'"$tmpdir"'/${base}_converted.png"
    
    oiiotool "$f" --ch "R,G,B" --colorconvert "ACES - ACEScg" "Output - sRGB" \
      --text:x=40:y=40:size=28 "Frame: ${frame:-N/A}   FPS: ${fps_tag:-'"$fps"'}" \
      --text:x=40:y=80:size=28  "RenderTime: ${rt_hms:-N/A}" \
      --text:x=40:y=120:size=28 "Software: ${software:-Unknown}" \
      --text:x=40:y=160:size=28 "Host: ${host:-Unknown}" \
      --text:x=40:y=200:size=28 "Mem: ${mem:-?}   Comp: ${comp:-?}" \
      --text:x=40:y=240:size=28 "ColorSpace: ${colorspace:-?}" \
      --text:x=40:y=280:size=28 "Date: ${datetime:-?}" \
      --text:x=40:y=320:size=28 "GPU: ${gpu_label:-N/A} (${gpu_pct:-0}%)" \
      --text:x=40:y=360:size=28 "CPU: ${cpu_label:-N/A} (${cpu_pct:-0}%)" \
      --text:x=40:y=400:size=28 "TotalRender: '"$total_rt_hms"'" \
      -o "$out"
  '
else
  printf "%s\n" "${exrs[@]}" | sort -V | \
  "${PAR_CMD[@]}" '
    f={}; name=${f##*/}; base=${name%.exr}
    oiiotool "$f" --ch "R,G,B" --colorconvert "ACES - ACEScg" "Output - sRGB" \
      -o "'"$tmpdir"'/""${base}_converted.png"
  '
fi

# ───────────────────────── 6. Assemble MOV ────────────────────────────────
pushd "$tmpdir" >/dev/null
echo "📜  Preparing list for FFmpeg …"
printf "file '%s'\n" *_converted.png | sort -V > files.txt

out_base=$(basename "$first_exr" .exr | sed -E 's/\.[0-9]+$//')
out_mov="${out_base}_prores444.mov"
echo "🎞  Encoding ProRes 444 MOV → $out_mov"

ffmpeg -y -loglevel error \
       -r "$fps" \
       -f concat -safe 0 -i files.txt \
       -c:v prores_ks -profile:v 4 -pix_fmt yuv444p10le \
       -s "$res" \
       "$out_mov" || { echo "ERROR: FFmpeg failed"; exit 1; }

popd >/dev/null

# ───────────────────────── 7. Cleanup ────────────────────────────────────
mv "$tmpdir/$out_mov" .
rm -rf "$tmpdir"
echo "✅  Done – output is $out_mov"


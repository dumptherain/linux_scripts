#!/bin/bash

echo "Starting script..."

# Get the resolution of the first .exr file in the directory
first_exr=$(ls *.exr | sort -V | head -n1)
echo "First EXR file: $first_exr"

if [ -z "$first_exr" ]; then
    echo "No EXR files found. Exiting."
    exit 1
fi

res=$(identify -format "%wx%h" "$first_exr")
echo "Resolution: $res"

# Adjust resolution to be divisible by 2
width=$(echo $res | cut -d 'x' -f 1)
height=$(echo $res | cut -d 'x' -f 2)

if ((width % 2 != 0)); then ((width--)); fi
if ((height % 2 != 0)); then ((height--)); fi

res="${width}x${height}"
echo "Adjusted resolution: $res"

# Default values
fps=24

# Parse command-line arguments
while (( "$#" )); do
  case "$1" in
    -fps)
      fps=$2
      shift 2
      ;;
    -res)
      res=$2
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*|--*=)
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
  esac
done

echo "Creating temporary directory..."
tmpdir=$(mktemp -d -p "./")
echo "Temporary directory created at $tmpdir"

echo "Copying .exr files to temporary directory..."
cp *.exr "$tmpdir" || { echo "Copying .exr files failed"; exit 1; }

echo "Changing into temporary directory $tmpdir"
pushd "$tmpdir" || { echo "Changing directory failed"; exit 1; }

#######################################
# Pass 1: Accumulate total render time
#######################################
total_rendertime=0
for f in $(ls *.exr | sort -V); do
  rt=$(oiiotool -info -v "$f" | awk '$1=="renderTime:" {print $2}')
  if [[ "$rt" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    total_rendertime=$(awk -v total="$total_rendertime" -v rt="$rt" 'BEGIN { printf "%.4f", total + rt }')
  else
    echo "⚠️ Warning: skipping invalid renderTime for $f ($rt)"
  fi
done

printf -v total_hms '%02d:%02d:%05.2f' $(echo "$total_rendertime" | awk '{ h=int($1/3600); m=int(($1%3600)/60); s=$1%60; print h, m, s }')
echo "Total render time: $total_hms"

#######################################
# Pass 2: Convert EXRs with overlay
#######################################
echo "Converting .exr files to .jpg with metadata overlay..."

for f in $(ls *.exr | sort -V); do
  echo "Processing $f..."

  frame=$(oiiotool -info -v "$f" | awk '/frame:/{print $2}')
  fps_tag=$(oiiotool -info -v "$f" | awk '/FramesPerSecond/{print $2}')
  software=$(oiiotool -info -v "$f" | sed -n 's/.*Software: "\(.*\)"/\1/p')
  datetime=$(oiiotool -info -v "$f" | sed -n 's/.*DateTime: "\(.*\)"/\1/p')
  rt_human=$(oiiotool -info -v "$f" | sed -n 's/.*renderTime_s: "\(.*\)"/\1/p')
  host=$(oiiotool -info -v "$f" | sed -n 's/.*HostComputer: "\(.*\)"/\1/p')
  mem=$(oiiotool -info -v "$f" | sed -n 's/.*renderMemory_s: "\(.*\)"/\1/p')
  comp=$(oiiotool -info -v "$f" | awk '/compression:/{print $2}')
  cspace=$(oiiotool -info -v "$f" | sed -n 's/.*oiio:ColorSpace: "\(.*\)"/\1/p')

  oiiotool "$f" --ch R,G,B \
    --colorconvert "ACES - ACEScg" "Output - sRGB" \
    --text:x=40:y=40:size=28 "Frame: ${frame:-N/A}   FPS: ${fps_tag:-$fps}" \
    --text:x=40:y=80:size=28 "RenderTime: ${rt_human:-N/A}" \
    --text:x=40:y=120:size=28 "Software: ${software:-Unknown}" \
    --text:x=40:y=160:size=28 "Host: ${host:-Unknown}" \
    --text:x=40:y=200:size=28 "Mem: ${mem:-N/A}   Comp: ${comp:-N/A}" \
    --text:x=40:y=240:size=28 "ColorSpace: ${cspace:-N/A}" \
    --text:x=40:y=280:size=28 "Date: ${datetime:-Unknown}" \
    --text:x=40:y=320:size=28 "TotalRender: $total_hms" \
    -o "${f%.exr}_converted.jpg"
done

echo "Generating list of .jpg files..."
ls *_converted.jpg | sort -V | sed 's/^/file /' > files.txt

output_filename=$(basename "$first_exr" .exr).mp4
echo "Output filename will be $output_filename"

echo "Stitching .jpg files into video $output_filename"
ffmpeg -f concat -safe 0 -i files.txt -c:v libx264 -pix_fmt yuv420p -r $fps -s $res "$output_filename" || { echo "FFmpeg processing failed"; exit 1; }

echo "Returning to the original directory"
popd

echo "Moving $output_filename to the original directory"
mv "$tmpdir/$output_filename" . || { echo "Moving output file failed"; exit 1; }

echo "Removing temporary directory $tmpdir"
rm -r "$tmpdir"

echo "Script completed successfully."


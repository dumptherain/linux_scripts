#!/bin/bash

echo "Starting script..."

# Get the resolution of the first.exr file in the directory
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

if (( width % 2 != 0 )); then
    ((width--))
fi

if (( height % 2 != 0 )); then
    ((height--))
fi

res="${width}x${height}"
echo "Adjusted resolution: $res"

# Default values
fps=25

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
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
  esac
done

echo "Creating temporary directory..."
tmpdir=$(mktemp -d -p "./")
echo "Temporary directory created at $tmpdir"

echo "Copying.exr files to temporary directory..."
cp *.exr "$tmpdir" || { echo "Copying.exr files failed"; exit 1; }

echo "Changing into temporary directory $tmpdir"
pushd "$tmpdir" || { echo "Changing directory failed"; exit 1; }

echo "Converting .exr files to lossless PNG..."
ls *.exr | parallel -v 'oiiotool --ch "R,G,B" --colorconvert "ACES - ACEScg" "Output - sRGB" {} -o {/.}_converted.png'

echo "Generating list of PNG files..."
ls *_converted.png | sort -V | sed 's/^/file /' > files.txt

# Refined filename generation:
base=$(basename "$first_exr" .exr)
output_base=$(echo "$base" | sed -E 's/\.[0-9]+$//')
output_filename="${output_base}_prores444.mov"
echo "Output filename will be $output_filename"

echo "Stitching PNG files into video $output_filename"
ffmpeg -framerate $fps -pattern_type glob -i '*_converted.png' -c:v prores_ks -profile:v 4 -pix_fmt yuv444p10le -s $res "$output_filename" || { echo "FFmpeg processing failed"; exit 1; }

echo "Returning to the original directory"
popd

echo "Moving $tmpdir/$output_filename to the original directory"
mv "$tmpdir/$output_filename" . || { echo "Moving output file failed"; exit 1; }

echo "Removing temporary directory $tmpdir"
rm -r "$tmpdir"

echo "Script completed successfully."

#!/bin/bash

# Get the resolution of the first .exr file in the directory
first_exr=$(ls *.exr | sort -V | head -n1)
res=$(identify -format "%wx%h" "$first_exr")

# Adjust resolution to be divisible by 2
width=$(echo $res | cut -d 'x' -f 1)
height=$(echo $res | cut -d 'x' -f 2)

if ((width % 2 != 0)); then
    ((width--))
fi

if ((height % 2 != 0)); then
    ((height--))
fi

res="${width}x${height}"

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

# Create a new temporary directory
tmpdir=$(mktemp -d -p "./")

# Copy .exr files to the temporary directory
cp *.exr "$tmpdir"

# Navigate to the temporary directory
pushd "$tmpdir"

# Convert .exr files to .jpg files, ignoring alpha channel
ls *.exr | parallel -v 'oiiotool --ch "R,G,B" --colorconvert "ACES - ACEScg" "Output - sRGB" {} -o {/.}_converted.jpg'

# Generate a list of .jpg files with the 'file' keyword before each filename
ls *_converted.jpg | sort -V | sed 's/^/file /' > files.txt

# Use the base name of the first EXR file for the MP4 file name, removing the file extension
output_filename=$(basename "$first_exr" .exr).mp4

# Stitch .jpg files into a video
ffmpeg -f concat -safe 0 -i files.txt -c:v libx264 -pix_fmt yuv420p -r $fps -s $res "$output_filename"

# Navigate back to the original directory
popd

# Move the output video to the original directory
mv "$tmpdir/$output_filename" .

# Remove the temporary directory
rm -r "$tmpdir"

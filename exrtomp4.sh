#!/bin/bash

# Default values
fps=24
res="1920x1080"

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
tmpdir=$(mktemp -d)

# Copy .exr files to the temporary directory
cp *.exr "$tmpdir"

# Navigate to the temporary directory
pushd "$tmpdir"

# Convert .exr files to .jpg files, ignoring alpha channel
ls *.exr | parallel -v 'oiiotool --ch "R,G,B" --colorconvert "ACES - ACEScg" "Output - sRGB" {} -o {/.}_converted.jpg'

# Generate a list of .jpg files with the 'file' keyword before each filename
ls *_converted.jpg | sort -V | sed 's/^/file /' > files.txt

# Stitch .jpg files into a video
ffmpeg -f concat -safe 0 -i files.txt -c:v libx264 -pix_fmt yuv420p -r $fps -s $res output.mp4

# Navigate back to the original directory
popd

# Move the output video to the original directory
mv "$tmpdir/output.mp4" .

# Remove the temporary directory
rm -r "$tmpdir"
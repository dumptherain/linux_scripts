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
tmpdir=$(mktemp -d -p "./")

# Copy .exr files to the temporary directory
cp *.exr "$tmpdir"

# Navigate to the temporary directory
pushd "$tmpdir"

# Convert .exr files to .png files, keeping alpha channel
ls *.exr | parallel -v 'oiiotool --ch "R,G,B,A" --colorconvert "ACES - ACEScg" "Output - sRGB" {} -o {/.}_converted.png'

# Generate a list of .png files with the 'file' keyword before each filename
ls *_converted.png | sort -V | sed 's/^/file /' > files.txt

# Stitch .png files into a video
ffmpeg -f concat -safe 0 -i files.txt -c:v prores_ks -profile:v 4 -pix_fmt yuva444p10le -r $fps -s $res output.mov

# Navigate back to the original directory
popd

# Move the output video to the original directory
mv "$tmpdir/output.mov" .

# Remove the temporary directory
rm -r "$tmpdir"

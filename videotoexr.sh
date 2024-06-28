#!/bin/bash

echo "Starting video to EXR conversion script..."

# Check if ffmpeg and oiiotool are installed
if ! command -v ffmpeg &> /dev/null; then
    echo "ffmpeg could not be found. Please install ffmpeg."
    exit 1
fi

if ! command -v oiiotool &> /dev/null; then
    echo "oiiotool could not be found. Please install oiiotool."
    exit 1
fi

# Default values
input_file=""
output_dir=""
fps=24

# Parse command-line arguments
while (( "$#" )); do
  case "$1" in
    -i|--input)
      input_file=$2
      shift 2
      ;;
    -o|--output)
      output_dir=$2
      shift 2
      ;;
    -fps)
      fps=$2
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

# Check if input file is provided
if [ -z "$input_file" ]; then
    echo "Error: Input file not provided. Use -i or --input to specify the input video file."
    exit 1
fi

# Check if output directory is provided
if [ -z "$output_dir" ]; then
    echo "Error: Output directory not provided. Use -o or --output to specify the output directory."
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Extract frames from video directly to EXR
echo "Extracting frames from $input_file..."
ffmpeg -i "$input_file" -vf "fps=$fps" "$output_dir/frame_%04d.exr" || { echo "Frame extraction failed"; exit 1; }

# Convert frames to ACEScg color space
echo "Converting frames to ACEScg color space..."
find "$output_dir" -name "frame_*.exr" | sort -V | parallel -v 'oiiotool {} --colorconvert "Output - sRGB" "ACES - ACEScg" -o {.}_acescg.exr'

# Remove original EXR frames
echo "Cleaning up original EXR frames..."
rm "$output_dir"/frame_*.exr

echo "Renaming converted frames..."
find "$output_dir" -name "frame_*_acescg.exr" | while read file; do
    mv "$file" "${file/_acescg/}"
done

echo "Script completed successfully."

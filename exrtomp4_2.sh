#!/bin/bash

echo "Starting script..."

# Default values
fps=24
input_dir="."          # Directory containing EXR files
output_file="output.mp4"
tmpdir=$(mktemp -d -p "./")  # Temporary directory for processing

# Parse command-line arguments
while (( "$#" )); do
  case "$1" in
    -fps)
      fps=$2
      shift 2
      ;;
    -input)
      input_dir=$2
      shift 2
      ;;
    -output)
      output_file=$2
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

# Check if input directory exists
if [ ! -d "$input_dir" ]; then
  echo "Input directory not found: $input_dir"
  exit 1
fi

# Get the first .exr file in the directory
first_exr=$(ls "$input_dir"/*.exr 2>/dev/null | sort -V | head -n1)
if [ -z "$first_exr" ]; then
  echo "No EXR files found in $input_dir"
  exit 1
fi

echo "First EXR file: $first_exr"

# Get the resolution of the first .exr file
res=$(identify -format "%wx%h" "$first_exr")
echo "Resolution: $res"

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
echo "Adjusted resolution: $res"

# Generate LUT for color space conversion (ACEScg to sRGB)
echo "Generating LUT for ACEScg to sRGB conversion..."
ociobakelut --format cubefile --inputspace "ACEScg" --outputspace "Output - sRGB" --cubesize 32 "$tmpdir/acescg_to_srgb.cube" || {
  echo "Failed to generate LUT. Ensure OpenColorIO is installed."
  exit 1
}

# Copy EXR files to the temporary directory
echo "Copying .exr files to temporary directory..."
cp "$input_dir"/*.exr "$tmpdir" || {
  echo "Failed to copy EXR files to temporary directory."
  exit 1
}

# Change to the temporary directory
echo "Changing into temporary directory $tmpdir"
pushd "$tmpdir" > /dev/null || {
  echo "Failed to change into temporary directory."
  exit 1
}

# Convert EXR sequence to MP4 using ffmpeg and the generated LUT
echo "Converting EXR sequence to MP4..."
ffmpeg -y -framerate $fps -i "frame%04d.exr" -vf "lut3d=$tmpdir/acescg_to_srgb.cube" -c:v libx264 -crf 18 -preset slow -pix_fmt yuv420p -s $res "$output_file" || {
  echo "FFmpeg processing failed."
  popd > /dev/null
  exit 1
}

# Return to the original directory
echo "Returning to the original directory"
popd > /dev/null

# Move the output file to the original directory
echo "Moving $output_file to the original directory"
mv "$tmpdir/$output_file" . || {
  echo "Failed to move output file."
  exit 1
}

# Clean up temporary directory
echo "Removing temporary directory $tmpdir"
rm -rf "$tmpdir"

echo "Script completed successfully. Output file: $output_file"

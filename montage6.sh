#!/bin/bash
# Deploys scripts with `# @nemo` tag to Nemo's right-click menu

OUTPUT="final_image.exr"

# Build row-major order (left to right, top to bottom)
FILES=""
for row in {0..1}; do
  for col in {0..1}; do
    idx=$((row * 2 + col + 1))
    FILES+=" $(printf "%02d.exr" "$idx")"
  done
done

oiiotool $FILES --mosaic 2x2 -o "$OUTPUT"

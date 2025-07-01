#!/bin/bash

OUTPUT="final_image.exr"

# Build row-major order (left to right, top to bottom)
FILES=""
for row in {0..5}; do
  for col in {1..6}; do
    idx=$((row * 6 + col))
    FILES+=" $(printf "%02d.exr" "$idx")"
  done
done

oiiotool $FILES --mosaic 6x6 -o "$OUTPUT"

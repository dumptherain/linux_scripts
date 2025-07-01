#!/bin/bash

OUTPUT="final_image.exr"
ROWS=2
COLS=2
FILES=""

# Build a 2×2 mosaic in row-major order (left→right, top→bottom)
for (( row=0; row<ROWS; row++ )); do
  for (( col=0; col<COLS; col++ )); do
    idx=$(( row * COLS + col + 1 ))
    FILES+=" $(printf "%02d.exr" "$idx")"
  done
done

oiiotool $FILES --mosaic ${COLS}x${ROWS} -o "$OUTPUT"


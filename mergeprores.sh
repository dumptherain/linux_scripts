#!/bin/bash

for left in *_left.mov
do
  right="${left%_left.mov}_right.mov"
  if [ -f "$right" ]; then
    output="${left%_left.mov}_output.mov"
    ffmpeg -i "$left" -i "$right" -filter_complex hstack -c:v prores_ks -profile:v 4 -pix_fmt yuv444p10le "$output"
  fi
done

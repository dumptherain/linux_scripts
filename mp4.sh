#!/bin/bash

mkdir mp4
for i in *.*; do ffmpeg -i "$i" \
-c:v libx264 -pix_fmt yuv420p \
./mp4/"${i%.*}.mp4"; done

exit

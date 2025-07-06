#!/bin/bash
# Deploys scripts with `# @nemo` tag to Nemo's right-click menu

mkdir -p prores444
for i in *.*; do
  ffmpeg -i "$i" \
    -c:v prores_ks \
    -profile:v 3 \
    -pix_fmt yuv444p10le \
    -color_range pc \
    -colorspace bt709 \
    -color_trc bt709 \
    -color_primaries bt709 \
    -c:a pcm_s16le \
    ./prores444/"${i%.*}.mov"
done

exit

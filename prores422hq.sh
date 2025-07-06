#!/bin/bash
# Deploys scripts with `# @nemo` tag to Nemo's right-click menu

mkdir prores422hq
for i in *.*; do ffmpeg -i "$i" -c:v prores_ks \
-profile:v 3 \
-vendor apl0 \
-bits_per_mb 8000 \
-pix_fmt yuv422p10le \
./prores422hq/"${i%.*}.mov"; done

exit



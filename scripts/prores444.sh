#!/bin/bash

mkdir prores444
for i in *.*; do ffmpeg -i "$i" -c:v prores_ks \
-profile:v 4 \
-vendor apl0 \
-bits_per_mb 8000 \
-pix_fmt yuva444p10le \
./prores444/"${i%.*}.mov"; done

exit

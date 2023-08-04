#!/bin/bash

# Store the current directory
start_dir=$(pwd)

# create a temporary directory
temp_dir=$(mktemp -d)

# convert exr to png in parallel and store in temp dir
ls *.exr | parallel -v 'convert {} -colorspace sRGB '$temp_dir'/{/.}.png'

# change to the temp directory
cd $temp_dir

# create a sequence of symlinks to the png images
ls *.png | cat -n | while read n f; do ln -s "$f" "$(printf "%04d.png" $n)"; done

# convert png to mp4
ffmpeg -r 30 -f image2 -s 1920x1080 -i %04d.png -vcodec libx264 -crf 25  -pix_fmt yuv420p output.mp4

# change back to the original directory
cd $start_dir

# move the video to the original directory
mv $temp_dir/output.mp4 ./

# remove the temporary directory
rm -r $temp_dir

#!/bin/bash

# Check if the current mode is greyscale
current_mode=$(xrandr --verbose | grep -m 1 -o "0.33:0.33:0.33")

if [ "$current_mode" == "0.33:0.33:0.33" ]; then
    # Disable greyscale (set gamma to normal)
    for output in $(xrandr --listmonitors | grep "+" | awk '{print $4}'); do
        xrandr --output $output --gamma 1:1:1
    done
else
    # Enable greyscale
    for output in $(xrandr --listmonitors | grep "+" | awk '{print $4}'); do
        xrandr --output $output --gamma 0.33:0.33:0.33
    done
fi

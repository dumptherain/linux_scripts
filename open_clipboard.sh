#!/bin/bash
path=$(xclip -o -selection clipboard | xargs)  # Get and trim clipboard content
if [ -d "$path" ] || [ -f "$path" ]; then
    nemo "$path"  # Open with Nemo file manager
else
    notify-send "Invalid path in clipboard: $path"
fi


#!/bin/bash

# Check if the 'play' process is already running
if pgrep -x "play" > /dev/null; then
  # If running, kill the process
  pkill -f "play -n synth sine 852" > /dev/null 2>&1 
else
  # If not running, start the sine wave
  play -n synth sine 852 &
fi

#!/bin/bash

# Check if the tmux session already exists
tmux has-session -t monitoring 2>/dev/null

if [ $? != 0 ]; then
  # Start a new tmux session and detach it immediately
  tmux new-session -d -s monitoring

  # Split the window horizontally
  tmux split-window -h

  # Start btop in the first pane (pane 0)
  tmux send-keys -t monitoring:0.0 'btop' C-m

  # Start nvtop in the second pane (pane 1)
  tmux send-keys -t monitoring:0.1 'nvtop' C-m

  # Create a new window
  tmux new-window -t monitoring

  # Start watch sensors in the new window (window 1, pane 0)
  tmux send-keys -t monitoring:1.0 'watch sensors' C-m
fi

# Attach the session to the current terminal
tmux attach-session -t monitoring

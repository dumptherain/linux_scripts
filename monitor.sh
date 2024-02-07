#!/bin/bash
# Start a new tmux session and detach it immediately
tmux new-session -d -s monitoring

# Split the window horizontally
tmux split-window -h

# Start btm in the first pane (pane 0)
tmux send-keys -t 0 'btm' C-m

# Start nvtop in the second pane (pane 1)
tmux send-keys -t 1 'nvtop' C-m

# Attach the session to the current terminal
tmux attach-session -t monitoring

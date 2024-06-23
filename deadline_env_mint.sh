#!/bin/bash

# Set the custom LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

# Run the Deadline Monitor
/opt/Thinkbox/Deadline10/bin/deadlinelauncher -monitor

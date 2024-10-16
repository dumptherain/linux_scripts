#!/bin/bash

# Connect using the full SSH command and execute monitor.sh from the correct path
ssh -t mini@192.168.8.138 'bash -ic "/home/mini/linux_scripts/monitor.sh; exec bash"'

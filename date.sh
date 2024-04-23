#!/bin/bash
# Get the current date in the format YYYY-MM-DD
DATE=$(date +'%Y-%m-%d')
# Create a new directory with the current date as its name
mkdir -p "$1/$DATE"

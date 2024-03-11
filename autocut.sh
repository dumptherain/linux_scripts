#!/bin/bash

# Set default cut threshold
cut_threshold=0.03

# Function to process a single video file
process_video() {
    local file=$1
    local cut_threshold=$2
    local filename=$(basename -- "$file")
    local extension="${filename##*.}"
    local filename_without_ext="${filename%.*}"
    local output_dir="${filename_without_ext}_clips"

    # Create directory for clips if it doesn't exist
    mkdir -p "$output_dir"

    echo "Processing $file with cut threshold $cut_threshold..."

    # Generate a list of cut points in the video
    ffmpeg -i "$file" -filter:v "select='gt(scene,${cut_threshold})',showinfo" -f null - 2> ffout.log

    # Parse the output log file to get the frame numbers of scene changes
    grep showinfo ffout.log | grep pts_time: | sed -n 's/.*pts_time:\([^ ]*\).*/\1/p' > cuts.txt

    # Add end time of the video to the cuts list
    ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" >> cuts.txt

    local start_time=0
    local count=1

    # Read the cut times and extract clips
    while read end_time; do
        if (( $(echo "$end_time > $start_time" | bc -l) )); then
            local output_file="${output_dir}/${filename_without_ext}_clip_$(printf "%02d" $count).${extension}"

            # Extract the clip using the start and end times
            ffmpeg -i "$file" -ss $start_time -to $end_time -c copy "$output_file"

            start_time=$end_time
            ((count++))
        fi
    done < cuts.txt

    # Cleanup
    rm ffout.log cuts.txt

    echo "Clips extracted to $output_dir"
}

# Process command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -threshold)
            cut_threshold=$2
            shift 2
            ;;
        *)
            # Check if file exists and is a video
            if [ -f "$1" ] && [[ $(file --mime-type -b "$1") =~ ^video/ ]]; then
                process_video "$1" $cut_threshold
            else
                echo "File $1 not found or is not a video."
            fi
            shift
            ;;
    esac
done

# If no files were specified, process all video files in the directory
if [ $# -eq 0 ]; then
    for file in *; do
        if [[ $(file --mime-type -b "$file") =~ ^video/ ]]; then
            process_video "$file" $cut_threshold
        fi
    done
fi

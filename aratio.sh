#!/bin/bash
# Deploys scripts with `# @nemo` tag to Nemo's right-click menu

# Check if a file was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_video_file>"
    exit 1
fi

input_file="$1"
base_name=$(basename -- "$input_file")
extension="${base_name##*.}"
filename="${base_name%.*}"

# Function to crop video to a specific aspect ratio
crop_video() {
    local input="$1"
    local output="$2"
    local ratio="$3"

    # Get video dimensions
    width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$input")
    height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$input")

    # Calculate new dimensions based on aspect ratio
    IFS=: read -r w_ratio h_ratio <<< "$ratio"
    target_width=$(( height * w_ratio / h_ratio ))
    target_height=$(( width * h_ratio / w_ratio ))

    if [ "$target_width" -le "$width" ]; then
        final_width="$target_width"
        final_height="$height"
    else
        final_width="$width"
        final_height="$target_height"
    fi

    # Calculate offsets for centering
    x_offset=$(( (width - final_width) / 2 ))
    y_offset=$(( (height - final_height) / 2 ))

    # Crop video
    ffmpeg -i "$input" -vf "crop=$final_width:$final_height:$x_offset:$y_offset" -c:a copy "$output"
}

# Crop to different aspect ratios
crop_video "$input_file" "${filename}_16_9.$extension" "16:9"
crop_video "$input_file" "${filename}_1_1.$extension" "1:1"
crop_video "$input_file" "${filename}_9_16.$extension" "9:16"
crop_video "$input_file" "${filename}_4_5.$extension" "4:5"

echo "Processing complete!"

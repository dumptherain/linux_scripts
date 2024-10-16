#!/bin/bash

# Change to the correct directory
cd /home/pscale/DiffusionLight

# Source the .bashrc file to get the conda setup
source ~/.bashrc

# Activate the conda environment
conda activate diffusionlight

# Check if natsort is installed, install if not
if ! python -c "import natsort" &> /dev/null; then
    echo "Installing natsort..."
    conda install -y natsort
fi

# Run the commands
python inpaint.py --dataset ./input --output_dir ./output/
python ball2envmap.py --ball_dir ./output/square --envmap_dir ./output/envmap
python exposure2hdr.py --input_dir ./output/envmap --output_dir ./output/hdr

# Deactivate the conda environment
conda deactivate

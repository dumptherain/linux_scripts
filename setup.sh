#!/bin/bash

# setup_linux_scripts.sh - Install dependencies and guide through setup for the provided scripts

set -uo pipefail  # Removed -e to allow continuation on errors

# Define the scripts directory (assuming it's cloned or placed at ~/linux_scripts)
SCRIPTS_DIR="$HOME/linux_scripts"

# Function to add SCRIPTS_DIR to PATH in .bashrc if not already present
add_to_path() {
    if ! grep -q "export PATH=\"\$HOME/linux_scripts:\$PATH\"" ~/.bashrc; then
        echo "Adding $SCRIPTS_DIR to PATH in ~/.bashrc..."
        echo "" >> ~/.bashrc
        echo "# Added by setup_linux_scripts.sh for script accessibility" >> ~/.bashrc
        echo "export PATH=\"\$HOME/linux_scripts:\$PATH\"" >> ~/.bashrc
        echo "Added successfully. Sourcing .bashrc..."
        source ~/.bashrc
    else
        echo "$SCRIPTS_DIR is already in PATH in ~/.bashrc. Skipping."
    fi
}

# Function to install dependencies (assuming Ubuntu/Debian-based system)
install_dependencies() {
    echo "Updating package list..."
    sudo apt update -y || echo "Warning: Failed to update package list, continuing anyway."

    echo "Installing required packages..."
    packages=(
        ffmpeg
        v4l-utils
        mpv
        curl
        jq
        openimageio-tools
        parallel
        imagemagick
        yad
        nemo
        xserver-xorg-input-wacom
        sox
        xclip
        libnotify-bin
        unrtf
        inotify-tools
        rsync
        x11-utils
    )

    for pkg in "${packages[@]}"; do
        sudo apt install -y "$pkg" && echo "Installed $pkg successfully." || echo "Warning: Failed to install $pkg, continuing with next packages."
    done

    # Additional checks or installs if needed
    if ! command -v whisper &> /dev/null; then
        echo "Whisper (transcription tool) not found globally. Will guide through manual setup later."
    fi

    echo "Dependencies installation attempted for all packages."
}

# Function to guide through manual setup procedures
guide_manual_setup() {
    echo ""
    echo "============================================================"
    echo "Manual Setup Procedures:"
    echo "============================================================"
    echo "1. Deploy Nemo right-click menu scripts:"
    echo "   - Run: $SCRIPTS_DIR/deploy_nemo_script.sh"
    echo "   - This will deploy scripts tagged with '# @nemo' to Nemo's scripts folder."
    echo "   - Restart Nemo if necessary: nemo -q && nemo &"
    echo ""
    read -p "Press Enter to continue..."

    echo "2. Deploy KDE desktop files (for Konqueror/Dolphin right-click menus):"
    echo "   - First, ensure .desktop files are created if needed (e.g., via create_desktop.sh)."
    echo "   - Then run: $SCRIPTS_DIR/deploy_desktop_files.sh"
    echo "   - This copies .desktop files to ~/.local/share/kservices5/ServiceMenus."
    echo ""
    read -p "Press Enter to continue..."

    echo "3. Setup for Whisper transcription (used in transcribe.sh, videototxt.sh):"
    echo "   - If not already installed, clone and set up OpenAI Whisper:"
    echo "     git clone https://github.com/openai/whisper.git ~/whisper"
    echo "     cd ~/whisper"
    echo "     python3 -m venv whisper_env"
    echo "     source whisper_env/bin/activate"
    echo "     pip install --upgrade pip"
    echo "     pip install -r requirements.txt"
    echo "     pip install openai-whisper"
    echo "   - Also install PyTorch with CUDA if available: pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118"
    echo "   - Test: whisper --help"
    echo "   - Note: Scripts assume Whisper in ~/whisper; adjust paths if different."
    echo ""
    read -p "Press Enter to continue..."

    echo "4. Wacom Tablet Configuration (for set_wacom.sh, wacom1.sh, etc.):"
    echo "   - Ensure your Wacom device is connected."
    echo "   - Run xsetwacom --list to verify devices."
    echo "   - Customize mapping in the scripts (e.g., MapToOutput values) based on your monitor setup (use xrandr to check)."
    echo "   - You can add a startup script or alias to run your preferred wacom script (e.g., wacom1.sh)."
    echo ""
    read -p "Press Enter to continue..."

    echo "5. Recording Scripts (record.sh, record_shortcut.sh, etc.):"
    echo "   - Edit audio device in scripts (e.g., AUDIO_DEV='hw:1,0' for ALSA devices)."
    echo "   - List devices: arecord -l"
    echo "   - For webcam: Ensure /dev/video* permissions; add user to 'video' group if needed: sudo usermod -aG video $USER"
    echo "   - Test: Run record.sh and check output in ~/Videos/recording."
    echo "   - For shortcut: Bind record_shortcut.sh to a key combo in your DE settings."
    echo ""
    read -p "Press Enter to continue..."

    echo "6. Other Optional Setups:"
    echo "   - For Deadline (deadline_env_mint.sh): Ensure Deadline is installed at /opt/Thinkbox/Deadline10."
    echo "   - For OBS copy (obs_copy.sh): Set up as systemd service per script comments."
    echo "   - For watch_* scripts: Run them in background or via systemd for persistent monitoring."
    echo "   - Blender/Nuke sync/backup: Adjust IP/paths in syncblender.sh, nuke_backup.sh."
    echo "   - Ensure NVIDIA drivers for NVENC in recording scripts if using GPU encoding."
    echo ""
    echo "Setup guidance complete. Review scripts for any user-specific paths (e.g., /home/mini to $HOME)."
    echo "Log out and back in for PATH changes, or run: source ~/.bashrc"
}

# Main execution
echo "Starting setup for linux_scripts..."
add_to_path
install_dependencies
guide_manual_setup

echo "Setup complete!"

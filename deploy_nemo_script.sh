#!/usr/bin/env bash
# Deploys `# @nemo` scripts to categorized subfolders in ~/.local/share/nemo/scripts

SOURCE_DIR="$HOME/linux_scripts"
TARGET_BASE="$HOME/.local/share/nemo/scripts"

echo "🧹 Cleaning target subfolders (except root)..."
find "$TARGET_BASE" -mindepth 1 -type d -exec rm -rf {} +

mkdir -p "$TARGET_BASE"

# Scripts that must stay together in root due to interdependencies
KEEP_IN_ROOT=(
  dailies.sh
  dailies_gui.sh
  exrtomp4.sh
  exrtomp4_dailies.sh
  exrtoprores422.sh
  exrtoprores444.sh
)

# Loop over all .sh files tagged with # @nemo
find "$SOURCE_DIR" -maxdepth 1 -type f -name "*.sh" | while read -r script; do
    name=$(basename "$script")

    if head -n 10 "$script" | grep -q '# @nemo'; then
        # Determine target folder
        if [[ " ${KEEP_IN_ROOT[*]} " == *" $name "* ]]; then
            target_dir="$TARGET_BASE"
        else
            case "$name" in
                *applyaudio*|*mp4*|*webmp4*|*joinvideo*|*mkv*|*prores*)
                    target_dir="$TARGET_BASE/video" ;;
                *exrtojpg*|*exrtotiff*|*merge*|*extract*|*archive*)
                    target_dir="$TARGET_BASE/image" ;;
                *montage*|*aratio*)
                    target_dir="$TARGET_BASE/layout" ;;
                *project*|*folder*|*date*)
                    target_dir="$TARGET_BASE/project" ;;
                *)
                    target_dir="$TARGET_BASE/misc" ;;
            esac
        fi

        mkdir -p "$target_dir"
        cp "$script" "$target_dir/"
        chmod +x "$target_dir/$name"
        echo "✅ $name → $(realpath --relative-to="$TARGET_BASE" "$target_dir")"
    fi
done

echo "🎉 Deployment complete."


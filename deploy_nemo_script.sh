#!/usr/bin/env bash
# Deploys `# @nemo` scripts into categorized subfolders, with some kept in root

SOURCE_DIR="$HOME/linux_scripts"
TARGET_BASE="$HOME/.local/share/nemo/scripts"

echo "📦 Scanning for # @nemo-tagged scripts in $SOURCE_DIR..."

mkdir -p "$TARGET_BASE"

# Scripts that must stay together in the top-level folder
KEEP_IN_ROOT=(
  dailies.sh
  dailies_gui.sh
  exrtomp4.sh
  exrtoprores422.sh
  exrtoprores444.sh
)

find "$SOURCE_DIR" -maxdepth 1 -type f -name "*.sh" | while read -r script; do
    name=$(basename "$script")

    # Only process files tagged with # @nemo
    if head -n 10 "$script" | grep -q '# @nemo'; then

        # Stay in top-level if in KEEP_IN_ROOT
        if [[ " ${KEEP_IN_ROOT[*]} " == *" $name "* ]]; then
            target_dir="$TARGET_BASE"
        else
            # Categorize
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


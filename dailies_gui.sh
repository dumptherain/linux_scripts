#!/usr/bin/env bash
# Deploys scripts with `# @nemo` tag to Nemo's right-click menu
# gui_exr_dailies_wrapper.sh - GUI wrapper for dailies.sh using yad (minimal fields)
set -euo pipefail

# ════════════════════════════════════════════════════════════════════════════════
# 🔧 CONFIGURATION
# Location of the main “dailies” script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/dailies.sh"
# ════════════════════════════════════════════════════════════════════════════════

# Function: find the nearest “dailies” folder above a given directory
find_dailies_folder() {
    local dir="$1"
    while [[ "$dir" != "/" ]]; do
        for name in "3-DAILIES" "DAILIES" "dailies"; do
            [[ -d "$dir/$name" ]] && { echo "$dir/$name"; return 0; }
        done
        dir="$(dirname "$dir")"
    done
    return 1
}

if [[ -n "${DISPLAY:-}" ]] && command -v yad &>/dev/null; then

    TARGET_FOLDER="${1:-$(pwd)}"

    # ensure EXRs exist
    if [[ ! -d "$TARGET_FOLDER" ]] || ! ls "$TARGET_FOLDER"/*.exr &>/dev/null; then
        yad --error --title="Error" --text="No EXR files found in:\n$TARGET_FOLDER"
        exit 1
    fi

    # build conversion form
    FORM=$(yad --form \
        --title="EXR → Video" \
        --text="Choose options:" \
        --field="Script:CB" "exrtomp4.sh!exrtoprores422.sh!exrtoavc.sh!exrtodnx.sh" \
        --field="FPS" "25" \
        --field="Metadata:CHK" FALSE \
        --field="Verbose:CHK" FALSE \
        --field="Overwrite:CHK" FALSE \
        --field="Preview:CHK" FALSE \
        --field="Custom Script:FL" "" \
        --button="Convert:0" --button="Cancel:1" \
        --width=600 --height=400)
    [[ $? -ne 0 ]] && { yad --info --title="Cancelled" --text="Conversion cancelled."; exit 0; }

    IFS="|" read -r SCRIPT_NAME FPS META V_FLAG F_FLAG P_FLAG CUSTOM <<<"$FORM"

    # build args array
    ARGS=()
    if [[ -n "$CUSTOM" ]]; then
        ARGS+=("-script" "$CUSTOM")
    elif [[ "$SCRIPT_NAME" != "exrtomp4.sh" ]]; then
        ARGS+=("-script" "$SCRIPT_NAME")
    fi
    ARGS+=("-fps" "$FPS")
    $META  && ARGS+=("-meta")
    $V_FLAG && ARGS+=("-v")
    $F_FLAG && ARGS+=("-f")
    $P_FLAG && ARGS+=("-preview")
    ARGS+=("$TARGET_FOLDER")

    # confirm
    CMD="dailies.sh ${ARGS[*]}"
    yad --question --title="Confirm" --text="<tt>$CMD</tt>" --width=600
    [[ $? -ne 0 ]] && { yad --info --title="Cancelled" --text="Conversion cancelled."; exit 0; }

    # ensure main script exists
    [[ ! -f "$MAIN_SCRIPT" ]] && { yad --error --title="Error" --text="Cannot find:\n$MAIN_SCRIPT"; exit 1; }
    chmod +x "$MAIN_SCRIPT" || true

    # notify and run
    yad --notification --text="Starting conversion…" &
    "$MAIN_SCRIPT" "${ARGS[@]}"
    RETCODE=$?

    # final dialog
    if [[ $RETCODE -eq 0 ]]; then
        yad --question \
            --title="Done" \
            --text="✓ Conversion complete!\n\nOpen dailies folder?" \
            --button="Open:0" --button="OK:1" --width=400
        if [[ $? -eq 0 ]]; then
            # locate and open today’s dailies subfolder
            DAILIES_ROOT=$(find_dailies_folder "$TARGET_FOLDER") || {
                yad --error --title="Error" --text="Could not locate dailies folder."
                exit 1
            }
            DATE_DIR="$DAILIES_ROOT/$(date +%y%m%d)"
            [[ -d "$DATE_DIR" ]] || {
                yad --error --title="Error" --text="Expected folder not found:\n$DATE_DIR"
                exit 1
            }
            command -v nemo &>/dev/null && nemo "$DATE_DIR" || xdg-open "$DATE_DIR"
        fi
    else
        yad --error --title="Error" --text="✗ Conversion failed! See terminal."
        exit $RETCODE
    fi

else
    # fallback: no GUI
    exec "$MAIN_SCRIPT" "$@"
fi


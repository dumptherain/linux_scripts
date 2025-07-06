#!/usr/bin/env bash
# Deploys scripts with `# @nemo` tag to Nemo's right-click menu
# gui_exr_dailies_wrapper.sh - GUI wrapper for dailies.sh using yad (minimal fields)
set -euo pipefail

# Locate main script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/dailies.sh"

# GUI mode if DISPLAY and yad exist
if [[ -n "${DISPLAY:-}" ]] && command -v yad >/dev/null 2>&1; then

    TARGET_FOLDER="${1:-$(pwd)}"

    # Ensure EXR files exist
    if [[ ! -d "$TARGET_FOLDER" ]] || ! ls "$TARGET_FOLDER"/*.exr >/dev/null 2>&1; then
        yad --error --title="Error" --text="No EXR files found in:\n$TARGET_FOLDER"
        exit 1
    fi

    # Single-form dialog with only your fields
    FORM_DATA=$(yad --form \
        --title="EXR to Video Conversion" \
        --text="Configure conversion options:" \
        --field="Script:CB" "exrtomp4.sh!exrtoprores422.sh!exrtoavc.sh!exrtodnx.sh" \
        --field="FPS" "25" \
        --field="Metadata:CHK" FALSE \
        --field="Verbose:CHK" FALSE \
        --field="Overwrite:CHK" FALSE \
        --field="Preview:CHK" FALSE \
        --field="Custom Script Path:FL" "" \
        --button="Convert":0 --button="Cancel":1 \
        --width=600 --height=400)
    RET=$?

    # Cancelled?
    if [[ $RET -ne 0 ]]; then
        yad --info --title="Cancelled" --text="Conversion cancelled."
        exit 0
    fi

    # Parse fields
    IFS="|" read -r SCRIPT_NAME FPS META_FLAG V_FLAG F_FLAG P_FLAG CUSTOM_PATH <<< "$FORM_DATA"

    # Build args
    ARGS=()
    if [[ -n "$CUSTOM_PATH" ]]; then
        ARGS+=("-script" "$CUSTOM_PATH")
    elif [[ "$SCRIPT_NAME" != "exrtomp4.sh" ]]; then
        ARGS+=("-script" "$SCRIPT_NAME")
    fi
    [[ -n "$FPS"          ]] && ARGS+=("-fps" "$FPS")
    [[ $META_FLAG == "TRUE" ]] && ARGS+=("-meta")
    [[ $V_FLAG    == "TRUE" ]] && ARGS+=("-v")
    [[ $F_FLAG    == "TRUE" ]] && ARGS+=("-f")
    [[ $P_FLAG    == "TRUE" ]] && ARGS+=("-preview")
    ARGS+=("$TARGET_FOLDER")

    # Confirmation
    CMD="dailies.sh ${ARGS[*]}"
    yad --question --title="Confirm" --text="<tt>$CMD</tt>" --width=600
    if [[ $? -ne 0 ]]; then
        yad --info --title="Cancelled" --text="Conversion cancelled."
        exit 0
    fi

    # Ensure main script exists
    if [[ ! -f "$MAIN_SCRIPT" ]]; then
        yad --error --title="Error" --text="Main script not found:\n$MAIN_SCRIPT"
        exit 1
    fi
    chmod +x "$MAIN_SCRIPT" 2>/dev/null || true

    # Notify start
    yad --notification --text="Starting EXR conversion…" &

    # Create a temporary wrapper for terminal output
    TEMP_SCRIPT=$(mktemp)
    cat > "$TEMP_SCRIPT" << 'EOF'
#!/usr/bin/env bash
MAIN_SCRIPT="$1"; shift
ARGS=("$@")
echo "=== EXR to Video Conversion ==="
echo "Command: dailies.sh ${ARGS[*]}"
echo ""
if "$MAIN_SCRIPT" "${ARGS[@]}"; then
    echo -e "\n✓ Conversion completed successfully!"
    exit_code=0
else
    echo -e "\n✗ Conversion failed!"
    exit_code=1
fi
echo -e "\nPress Enter to close…"; read
exit $exit_code
EOF
    chmod +x "$TEMP_SCRIPT"

    # Launch in terminal or fallback to progress dialog
    if command -v gnome-terminal >/dev/null 2>&1; then
        gnome-terminal --wait -- "$TEMP_SCRIPT" "$MAIN_SCRIPT" "${ARGS[@]}"
        RETCODE=$?
    elif command -v xfce4-terminal >/dev/null 2>&1; then
        xfce4-terminal --hold --command="$TEMP_SCRIPT $MAIN_SCRIPT ${ARGS[*]}"
        RETCODE=$?
    elif command -v konsole >/dev/null 2>&1; then
        konsole --hold -e "$TEMP_SCRIPT" "$MAIN_SCRIPT" "${ARGS[@]}"
        RETCODE=$?
    else
        if "$MAIN_SCRIPT" "${ARGS[@]}" 2>&1 | yad --progress --title="Converting…" --text="Working…" --pulsate --auto-close; then
            RETCODE=0
        else
            RETCODE=1
        fi
    fi

    rm -f "$TEMP_SCRIPT"

    # Final result
    if [[ $RETCODE -eq 0 ]]; then
        yad --info --title="Done" --text="✓ Conversion completed successfully!"
    else
        yad --error --title="Error" --text="✗ Conversion failed! Check output."
    fi

else
    # no GUI or no yad → pass through to main script
    exec "$MAIN_SCRIPT" "$@"
fi


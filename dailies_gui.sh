#!/usr/bin/env bash
# gui_exr_dailies_wrapper.sh - GUI (yad) front-end + terminal progress (single window)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/dailies.sh"

find_dailies_folder() {
    local dir="$1"
    while [[ "$dir" != "/" ]]; do
        for name in 3-DAILIES DAILIES dailies; do
            [[ -d "$dir/$name" ]] && { echo "$dir/$name"; return 0; }
        done
        dir="$(dirname "$dir")"
    done
    return 1
}

open_folder() {
    local p="$1"
    if command -v nemo &>/dev/null; then
        nohup nemo "$p" >/dev/null 2>&1 &
    else
        nohup xdg-open "$p" >/dev/null 2>&1 &
    fi
}

pick_terminal() {
    for t in gnome-terminal xfce4-terminal mate-terminal konsole tilix kitty alacritty lxterminal xterm; do
        command -v "$t" &>/dev/null && { echo "$t"; return 0; }
    done
    return 1
}

if [[ -n "${DISPLAY:-}" ]] && command -v yad &>/dev/null; then
    TARGET_FOLDER="${1:-$(pwd)}"
    if [[ ! -d "$TARGET_FOLDER" ]] || ! ls "$TARGET_FOLDER"/*.exr &>/dev/null; then
        yad --error --title="Error" --text="No EXR files found in:\n$TARGET_FOLDER"
        exit 1
    fi

    FORM=$(yad --form \
        --title="EXR → Video" \
        --text="Choose options:" \
        --field="Script:CB" "exrtomp4.sh!exrtoprores422.sh!exrtoavc.sh!exrtodnx.sh" \
        --field="FPS" "25" \
        --field="Metadata:CHK" FALSE \
        --field="Verbose (-v):CHK" FALSE \
        --field="Overwrite (-f):CHK" FALSE \
        --field="Preview (-preview):CHK" FALSE \
        --field="Custom Script:FL" "" \
        --button="Convert:0" --button="Cancel:1" \
        --width=600 --height=400) || { yad --info --title="Cancelled" --text="Conversion cancelled."; exit 0; }

    IFS="|" read -r SCRIPT_NAME FPS META V_FLAG F_FLAG P_FLAG CUSTOM <<<"$FORM"
    for v in META V_FLAG F_FLAG P_FLAG; do eval "$v=\${!v^^}"; done

    ARGS=()
    if [[ -n "$CUSTOM" ]]; then
        ARGS+=("-script" "$CUSTOM")
    elif [[ "$SCRIPT_NAME" != "exrtomp4.sh" ]]; then
        ARGS+=("-script" "$SCRIPT_NAME")
    fi
    ARGS+=("-fps" "$FPS")
    [[ "$META"   == "TRUE" ]] && ARGS+=("-meta")
    [[ "$V_FLAG" == "TRUE" ]] && ARGS+=("-v")
    [[ "$F_FLAG" == "TRUE" ]] && ARGS+=("-f")
    [[ "$P_FLAG" == "TRUE" ]] && ARGS+=("-preview")
    ARGS+=("$TARGET_FOLDER")

    CMD_PRETTY="dailies.sh ${ARGS[*]}"
    yad --question --title="Confirm" --text="<tt>$CMD_PRETTY</tt>" --width=600 \
        || { yad --info --title="Cancelled" --text="Conversion cancelled."; exit 0; }

    [[ -f "$MAIN_SCRIPT" ]] || { yad --error --title="Error" --text="Cannot find:\n$MAIN_SCRIPT"; exit 1; }
    chmod +x "$MAIN_SCRIPT" || true

    LOGFILE=$(mktemp /tmp/dailies_gui_log.XXXXXX)

    # Launch inside terminal (single window)
    TERM=$(pick_terminal) || { yad --error --title="Error" --text="No terminal emulator found."; exit 1; }

    # Create a wrapper script that captures exit code and keeps terminal open
    WRAPPER_SCRIPT=$(mktemp /tmp/dailies_wrapper.XXXXXX.sh)
    cat > "$WRAPPER_SCRIPT" << EOF
#!/bin/bash
set -euo pipefail
echo "🎬 Starting conversion..."
"$MAIN_SCRIPT" "\${@}" 2>&1 | tee "$LOGFILE"
EXIT_CODE=\${PIPESTATUS[0]}
echo "EXIT_CODE:\$EXIT_CODE" >> "$LOGFILE"
echo ""
echo "Process completed with exit code: \$EXIT_CODE"
if [[ \$EXIT_CODE -eq 0 ]]; then
    echo "✅ Conversion successful!"
else
    echo "❌ Conversion failed!"
fi
echo "Press Enter to close..."
read -r
exit \$EXIT_CODE
EOF
    chmod +x "$WRAPPER_SCRIPT"

    # Run with live tee to log
    case "$TERM" in
        gnome-terminal|mate-terminal|tilix)
            "$TERM" -- "$WRAPPER_SCRIPT" "${ARGS[@]}"
            ;;
        xfce4-terminal)
            "$TERM" --hold -e "$WRAPPER_SCRIPT" "${ARGS[@]}"
            ;;
        konsole)
            "$TERM" --noclose -e "$WRAPPER_SCRIPT" "${ARGS[@]}"
            ;;
        *)
            # generic
            "$TERM" -e "$WRAPPER_SCRIPT" "${ARGS[@]}"
            ;;
    esac
    
    # Wait for the process to complete and log file to be updated
    while [[ ! -f "$LOGFILE" ]] || ! grep -q "EXIT_CODE:" "$LOGFILE" 2>/dev/null; do
        sleep 0.5
    done
    
    # Extract exit code from log
    EXIT=$(grep -oP '^EXIT_CODE:\K.*' "$LOGFILE" | tail -1 || echo "1")
    
    # Clean up wrapper script
    rm -f "$WRAPPER_SCRIPT" 2>/dev/null || true

    # Extract dailies path (requires echo "DAILIES_PATH:...") in main script
    DAILIES_PATH=$(grep -oP '^DAILIES_PATH:\K.*' "$LOGFILE" | tail -1 || true)
    if [[ -z "$DAILIES_PATH" ]]; then
        ROOT=$(find_dailies_folder "$TARGET_FOLDER" || true)
        [[ -n "$ROOT" ]] && DAILIES_PATH="$ROOT/$(date +%y%m%d)"
    fi

    if [[ $EXIT -eq 0 ]]; then
        if [[ -d "${DAILIES_PATH:-/__missing__}" ]]; then
            # Automatically open the folder after successful conversion
            open_folder "$DAILIES_PATH"
            
            yad --question --title="Done" \
                --text="✓ Conversion complete.\n🗂️ Folder opened automatically.\nOpen folder again?\n<tt>$DAILIES_PATH</tt>" \
                --button="Open:0" --button="OK:1" --width=420
            [[ $? -eq 0 ]] && open_folder "$DAILIES_PATH"
        else
            yad --text-info --title="Done (Folder not found)" \
                --filename=<(echo "Success but folder not found.\nLog:\n"; cat "$LOGFILE") \
                --button="OK:0" --width=800 --height=500
        fi
    else
        yad --text-info --title="Conversion Failed" \
            --filename=<(echo "Exit code: $EXIT\n\nLog:\n"; cat "$LOGFILE") \
            --button="OK:0" --width=800 --height=500
        exit $EXIT
    fi
    exit 0
else
    # No GUI available, run in CLI mode
    exec "$MAIN_SCRIPT" "$@"
fi

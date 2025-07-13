#!/usr/bin/env bash
# @nemo
# Extract EXR metadata into metadata.txt in the selected folder

set -euo pipefail

# 1. Figure out the folder you clicked on
if [[ $# -ge 1 && -d "$1" ]]; then
  SEQ_FOLDER="$1"
elif [[ $# -ge 1 && -f "$1" ]]; then
  SEQ_FOLDER="$(dirname "$1")"
else
  SEQ_FOLDER="$PWD"
fi

# 2. Gather EXR list
mapfile -t EXRS < <(find "$SEQ_FOLDER" -maxdepth 1 -type f -iname '*.exr' | sort)
if (( ${#EXRS[@]} == 0 )); then
  notify-send "Extract EXR metadata" "No .exr files found in $SEQ_FOLDER"
  exit 1
fi

# 3. Write metadata.txt
OUT="$SEQ_FOLDER/metadata.txt"
{
  echo "Metadata extracted: $(date --iso-8601=seconds)"
  echo "────────────────────────────────────────────"
  for EXR in "${EXRS[@]}"; do
    echo
    echo "File: $(basename "$EXR")"
    echo "------------------------"
    exrheader "$EXR" 2>&1 || echo "⚠️  Failed on $EXR"
  done
} > "$OUT"

# 4. Notify
notify-send "Extract EXR metadata" "Wrote ${#EXRS[@]} files’ headers to $(basename "$OUT")"


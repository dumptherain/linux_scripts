#!/usr/bin/env bash
set -euo pipefail

#─── CONFIGURATION ──────────────────────────────────────────────────────────
MAX_WIDTH=1920   # maximum width in pixels
MAX_HEIGHT=1080  # maximum height in pixels
QUALITY=80       # WebP quality (0–100)

#─── CHECK DEPENDENCIES ──────────────────────────────────────────────────────
if ! command -v convert >/dev/null 2>&1; then
  echo "Error: ImageMagick 'convert' not found. Install it with 'sudo apt install imagemagick'."
  exit 1
fi

#─── GATHER FILE LIST ─────────────────────────────────────────────────────────
if [ "$#" -gt 0 ]; then
  FILES=( "$@" )
else
  # find common image types in current directory
  mapfile -t FILES < <(find . -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" \) -print)
fi

if [ "${#FILES[@]}" -eq 0 ]; then
  echo "No images found to convert."
  exit 0
fi

#─── PROCESS EACH IMAGE ──────────────────────────────────────────────────────
for SRC in "${FILES[@]}"; do
  [ -f "$SRC" ] || continue
  BASENAME="${SRC##*/}"
  NAME="${BASENAME%.*}"
  DEST="${NAME}.webp"

  echo "Converting '$SRC' → '$DEST'..."

  # resize only if larger than MAX_WIDTH×MAX_HEIGHT (the “>” flag)
  convert "$SRC" -resize "${MAX_WIDTH}x${MAX_HEIGHT}>" -quality "$QUALITY" "$DEST"
done

echo "All done!"


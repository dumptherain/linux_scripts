#!/bin/bash
# imagepack (parallel): convert all *.exr in CWD to JPG/PNG/TIFF using your scripts,
# and package results into ./package/{jpg,png,tiff,exr}.
# Parallelism defaults to the number of CPU cores; override with: JOBS=8 imagepack

set -euo pipefail
shopt -s nullglob

# --- paths to converters (use $HOME) ---
JPG_SCRIPT="$HOME/linux_scripts/exrtojpg.sh"
PNG_SCRIPT="$HOME/linux_scripts/exrtopng.sh"
TIFF_SCRIPT="$HOME/linux_scripts/exrtotiff.sh"

# --- sanity checks ---
for s in "$JPG_SCRIPT" "$PNG_SCRIPT" "$TIFF_SCRIPT"; do
  [[ -x "$s" ]] || { echo "Error: not executable: $s (chmod +x)"; exit 1; }
done

EXRS=( *.exr )
if (( ${#EXRS[@]} == 0 )); then
  echo "No .exr files found in current directory."
  exit 0
fi

# --- prepare package folders ---
PKG_DIR="package"
mkdir -p "$PKG_DIR"/{jpg,png,tiff,exr}

# Copy originals first (idempotent)
for f in "${EXRS[@]}"; do
  cp -n -- "$f" "$PKG_DIR/exr/"
done

# --- parallel convert: one file per job, all three formats per job ---
JOBS="${JOBS:-$(nproc)}"

# Export scripts so subshells see them
export JPG_SCRIPT PNG_SCRIPT TIFF_SCRIPT

# Run from inside package so -folder outputs land in ./jpg ./png ./tiff
pushd "$PKG_DIR" >/dev/null

# Feed parent-path EXRs to xargs; handle spaces safely
printf '%s\0' "${EXRS[@]}" | \
xargs -0 -n 1 -P "$JOBS" bash -c '
  set -e
  f="$1"
  echo "→ Converting: $f"
  "$JPG_SCRIPT"  -folder "../$f" >/dev/null
  "$PNG_SCRIPT"  -folder "../$f" >/dev/null
  "$TIFF_SCRIPT" -folder "../$f" >/dev/null
' _

popd >/dev/null

echo "Done. See ./package/{jpg,png,tiff,exr}"


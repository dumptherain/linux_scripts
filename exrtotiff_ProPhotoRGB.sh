#!/bin/bash

# Converts a scene-linear EXR into a 16-bit, gamma-encoded ProPhoto RGB TIFF
# (with embedded ProPhoto ICC) so GIMP will display it correctly.

if [ $# -ne 1 ]; then
    echo "Usage: $0 input.exr"
    exit 1
fi

INPUT="$1"

# Verify input exists and has .exr extension
if [ ! -f "$INPUT" ]; then
    echo "Error: '$INPUT' does not exist"
    exit 1
fi
if [[ ! "$INPUT" =~ \.exr$ ]]; then
    echo "Error: Input file must have .exr extension"
    exit 1
fi

# Paths to ICC profiles (adjust if yours live elsewhere)
SRGB_ICC="/usr/share/color/icc/sRGB.icc"
PROPHOTO_ICC="/usr/share/color/icc/ProPhoto.icc"

# Verify ICC profiles exist
if [ ! -f "$SRGB_ICC" ] || [ ! -f "$PROPHOTO_ICC" ]; then
    echo "Error: Cannot find one or more ICC profiles:"
    echo "  sRGB ICC:     $SRGB_ICC"
    echo "  ProPhoto ICC: $PROPHOTO_ICC"
    exit 1
fi

# Derive output filename (basename + _ProPhoto.tiff)
BASENAME="${INPUT%.exr}"
OUTPUT="${BASENAME}_ProPhoto.tiff"

# Pipeline:
# 1) role_scene_linear → out_srgb   (apply sRGB gamma)
# 2) --iccread sRGB.icc             (tag buffer as sRGB)
# 3) --colorconvert sRGB.icc→ProPhoto.icc
# 4) --iccwrite ProPhoto.icc        (embed ProPhoto tag)
# 5) -d uint16                      (force 16-bit)
# 6) -o OUTPUT
oiiotool "$INPUT" \
    --colorconvert role_scene_linear out_srgb \
    --iccread "$SRGB_ICC" \
    --colorconvert "$SRGB_ICC" "$PROPHOTO_ICC" \
    --iccwrite "$PROPHOTO_ICC" \
    -d uint16 \
    -o "$OUTPUT"

if [ $? -eq 0 ]; then
    echo "✅ Converted '$INPUT' → ProPhoto RGB (gamma-encoded, 16-bit) TIFF: '$OUTPUT'"
else
    echo "❌ Conversion failed"
    exit 1
fi


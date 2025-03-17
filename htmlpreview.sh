#!/bin/bash

# Check if at least one file is provided
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 file1 [file2 ...]"
    exit 1
fi

# Create the preview subfolder if it doesn't exist
PREVIEW_DIR="preview"
mkdir -p "$PREVIEW_DIR"

# Copy input files into the preview directory
for file in "$@"; do
    cp "$file" "$PREVIEW_DIR/"
done

# Define the output HTML file (inside the preview folder)
OUTPUT="$PREVIEW_DIR/gallery.html"

# Write the HTML header, title, and CSS styling into the output file
cat << 'EOF' > "$OUTPUT"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>References</title>
  <style>
    body {
      font-family: sans-serif;
      margin: 0;
      padding: 20px;
      background: #f0f0f0;
    }
    h1 {
      text-align: center;
    }
    .gallery {
      display: block;
      max-width: 1000px;
      margin: 0 auto;
    }
    .gallery img,
    .gallery video {
      width: 100%;
      max-width: 100%;
      height: auto;
      display: block;
      margin-bottom: 20px;
      object-fit: contain;
    }
  </style>
</head>
<body>
<h1>References</h1>
<div class="gallery">
EOF

# Append an element for each file based on its type
for file in "$@"; do
    base=$(basename "$file")
    ext="${base##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    case "$ext" in
        jpg|jpeg|png|gif|bmp|tiff)
            echo "  <img src=\"$base\" alt=\"$base\">" >> "$OUTPUT"
            ;;
        mp4|mov|avi|mkv|webm|flv|wmv)
            echo "  <video src=\"$base\" autoplay loop muted playsinline></video>" >> "$OUTPUT"
            ;;
        *)
            # For unrecognized file types, just create a link
            echo "  <p><a href=\"$base\">$base</a></p>" >> "$OUTPUT"
            ;;
    esac
done

# Write the closing HTML tags
cat << 'EOF' >> "$OUTPUT"
</div>
</body>
</html>
EOF

echo "Gallery created in $OUTPUT"


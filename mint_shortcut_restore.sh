#!/usr/bin/env bash
set -euo pipefail

# Usage: ./restore-mint-shortcuts.sh [backup-directory]
BACKUP_DIR="${1:-mint-shortcuts-backup}"

# Check backup directory exists
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "Error: Backup directory '$BACKUP_DIR' not found." >&2
  exit 1
fi

# Helper: load if file exists
load_dconf() {
  local path="$1"
  local file="$2"
  if [[ -s "$BACKUP_DIR/$file" ]]; then
    echo "Restoring $path from $file…"
    dconf load "$path" < "$BACKUP_DIR/$file"
  else
    echo "Skipping $file (empty or missing)."
  fi
}

# Ensure dconf is available
if ! command -v dconf >/dev/null 2>&1; then
  echo "Error: 'dconf' command not found. Install dconf-cli and try again." >&2
  exit 1
fi

# Load each schema
load_dconf /org/cinnamon/desktop/keybindings/               "cinnamon-keybindings.dconf"
load_dconf /org/cinnamon/desktop/wm/keybindings/            "cinnamon-wm-keybindings.dconf"
load_dconf /org/cinnamon/desktop/keybindings/custom-keybindings/ "cinnamon-custom-keybindings.dconf"
load_dconf /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ "gnome-media-custom.dconf"

echo
echo "Done. You may need to open Settings → Keyboard → Shortcuts and click 'Apply' to see changes."


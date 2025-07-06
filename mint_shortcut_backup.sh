#!/usr/bin/env bash
set -euo pipefail

# Where to put the backup (default: ./mint-shortcuts-backup)
BACKUP_DIR="${1:-mint-shortcuts-backup}"

# Ensure dconf is installed
if ! command -v dconf >/dev/null 2>&1; then
  echo "Error: dconf not found. Please install dconf-cli." >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR"

echo "Dumping Cinnamon desktop keybindings…"
dconf dump /org/cinnamon/desktop/keybindings/ \
  > "$BACKUP_DIR/cinnamon-keybindings.dconf"

echo "Dumping Cinnamon window-manager keybindings…"
dconf dump /org/cinnamon/desktop/wm/keybindings/ \
  > "$BACKUP_DIR/cinnamon-wm-keybindings.dconf"

echo "Dumping any custom-keybindings schema (if used)…"
dconf dump /org/cinnamon/desktop/keybindings/custom-keybindings/ \
  > "$BACKUP_DIR/cinnamon-custom-keybindings.dconf" || true

echo "Dumping GNOME media-keys custom bindings (if you’ve set any)…"
dconf dump /org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/ \
  > "$BACKUP_DIR/gnome-media-custom.dconf" || true

echo
echo "Backup complete! Files in '$BACKUP_DIR':"
ls -1 "$BACKUP_DIR"


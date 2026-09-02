#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Uninstaller for GNOME Matugen Material You Themer
# ==============================================================================

BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gnome-matugen"
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
THEME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/themes/Material-You"

echo "🗑️ Uninstalling GNOME Matugen Themer..."

# 1. Stop and disable systemd service
if systemctl --user is-active --quiet matugen-gnome.service 2>/dev/null; then
  echo "⏹️ Stopping systemd service..."
  systemctl --user stop matugen-gnome.service || true
  systemctl --user disable matugen-gnome.service || true
fi

rm -f "$SYSTEMD_USER_DIR/matugen-gnome.service"
systemctl --user daemon-reload || true

# 2. Reset GNOME settings to defaults
echo "🔄 Resetting GNOME theme settings..."
gsettings set org.gnome.shell.extensions.user-theme name '' 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true

# 3. Clean CSS files generated
rm -f "$HOME/.config/gtk-3.0/gtk.css"
rm -f "$HOME/.config/gtk-4.0/gtk.css"
rm -rf "$THEME_DIR"
rm -rf "$CONFIG_DIR"
rm -f "$BIN_DIR/gnome-matugen-apply"
rm -f "$BIN_DIR/gnome-matugen-daemon"

echo "✅ Uninstallation complete."

#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Installer for GNOME Matugen Material You Themer
# Tested on Debian 13 (Trixie), Ubuntu, and other GNOME-based Linux distributions
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gnome-matugen"
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
THEMES_USER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/themes"

echo "=========================================================="
echo " 🎨  GNOME Matugen Material You - Installer for Debian 13"
echo "=========================================================="
echo ""

# 1. Install System Dependencies via APT
echo "📦 Step 1: Installing system dependencies..."
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y \
    sassc \
    gnome-shell-extensions \
    gnome-tweaks \
    qt5ct \
    qt6ct \
    inotify-tools \
    libjxl-tools \
    imagemagick \
    curl \
    tar \
    xz-utils
else
  echo "⚠️ apt-get not found. Please ensure sassc, gnome-shell-extensions, qt5ct, qt6ct, and inotify-tools are installed."
fi

mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$SYSTEMD_USER_DIR" "$THEMES_USER_DIR"

# 2. Install Matugen
echo ""
echo "🚀 Step 2: Checking Matugen installation..."
if ! command -v matugen >/dev/null 2>&1 && [[ ! -x "$BIN_DIR/matugen" ]]; then
  echo "📥 Downloading Matugen binary (Linux x86_64)..."
  TMP_DIR="$(mktemp -d)"
  
  if curl -sL -o "$TMP_DIR/matugen.tar.gz" https://github.com/InioX/matugen/releases/download/v4.2.0/matugen-4.2.0-x86_64.tar.gz; then
    tar -xzf "$TMP_DIR/matugen.tar.gz" -C "$TMP_DIR"
    cp "$TMP_DIR/matugen" "$BIN_DIR/matugen"
    chmod +x "$BIN_DIR/matugen"
    echo "✅ Matugen installed to $BIN_DIR/matugen"
  else
    echo "❌ Failed to download Matugen automatically. Please install Matugen manually." >&2
    exit 1
  fi
  rm -rf "$TMP_DIR"
else
  echo "✅ Matugen is already installed."
fi

# 3. Install adw-gtk3 theme for legacy GTK3 applications
echo ""
echo "🎨 Step 3: Checking adw-gtk3 (GTK3 libadwaita theme)..."
if [[ ! -d "/usr/share/themes/adw-gtk3" && ! -d "$THEMES_USER_DIR/adw-gtk3" ]]; then
  echo "📥 Installing adw-gtk3 theme..."
  TMP_ADW="$(mktemp -d)"
  if curl -sL -o "$TMP_ADW/adw-gtk3.tar.xz" "https://github.com/lassekongo83/adw-gtk3/releases/download/v5.3/adw-gtk3v5.3.tar.xz" 2>/dev/null || \
     curl -sL -o "$TMP_ADW/adw-gtk3.tar.xz" "https://github.com/lassekongo83/adw-gtk3/releases/download/v5.2/adw-gtk3v5.2.tar.xz" 2>/dev/null; then
    tar -xf "$TMP_ADW/adw-gtk3.tar.xz" -C "$THEMES_USER_DIR"
    echo "✅ adw-gtk3 installed to $THEMES_USER_DIR"
  else
    echo "⚠️ Could not download pre-built adw-gtk3. GTK3 legacy apps might need adw-gtk3 manually installed."
  fi
  rm -rf "$TMP_ADW"
else
  echo "✅ adw-gtk3 theme found."
fi

# 4. Copy Templates
echo ""
echo "📁 Step 4: Installing Matugen templates..."
rm -rf "$CONFIG_DIR/templates"
cp -r "$SCRIPT_DIR/templates" "$CONFIG_DIR/templates"
echo "✅ Templates installed to $CONFIG_DIR/templates"

# 5. Install Executables
echo ""
echo "⚙️ Step 5: Installing executables..."
cp "$SCRIPT_DIR/bin/gnome-matugen-apply" "$BIN_DIR/gnome-matugen-apply"
cp "$SCRIPT_DIR/bin/gnome-matugen-daemon" "$BIN_DIR/gnome-matugen-daemon"
chmod +x "$BIN_DIR/gnome-matugen-apply" "$BIN_DIR/gnome-matugen-daemon"
echo "✅ Installed gnome-matugen-apply & gnome-matugen-daemon in $BIN_DIR"

# 6. Enable GNOME User Theme Extension
echo ""
echo "🧩 Step 6: Enabling GNOME Shell User Themes extension..."
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true

# 7. Configure Systemd Service
echo ""
echo "🔄 Step 7: Configuring Systemd user service..."
cp "$SCRIPT_DIR/systemd/matugen-gnome.service" "$SYSTEMD_USER_DIR/matugen-gnome.service"
systemctl --user daemon-reload
systemctl --user enable --now matugen-gnome.service
echo "✅ Systemd service enabled and started."

# 8. Add ~/.local/bin to PATH in bashrc if needed
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  if ! grep -q 'PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "ℹ️ Added ~/.local/bin to ~/.bashrc"
  fi
fi

# 9. Apply theme for the first time
echo ""
echo "✨ Step 8: Generating initial theme..."
export PATH="$BIN_DIR:$PATH"
"$BIN_DIR/gnome-matugen-apply" || true

echo ""
echo "=========================================================="
echo " 🎉 Installation Complete!"
echo " GNOME is now dynamically themed with Material You."
echo ""
echo " Useful Commands:"
echo "   - Apply theme manually: gnome-matugen-apply"
echo "   - Service status:       systemctl --user status matugen-gnome.service"
echo "   - Service logs:         journalctl --user -u matugen-gnome.service -f"
echo "=========================================================="

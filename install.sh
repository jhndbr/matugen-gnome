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

# 1. Install System Dependencies
echo "📦 Step 1: Installing system dependencies..."
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y \
    sassc \
    gnome-shell-extensions \
    gnome-tweaks \
    qt5ct \
    qt6ct \
    qt5-style-kvantum \
    inotify-tools \
    libjxl-tools \
    imagemagick \
    python3-gi \
    gir1.2-glib-2.0 \
    curl \
    wget \
    tar \
    xz-utils
  # Install Qt6 Kvantum plugin (available on Debian 13 Trixie / Ubuntu 24.04+)
  sudo apt-get install -y qt6-style-kvantum 2>/dev/null || true
elif command -v pacman >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm \
    sassc \
    gnome-shell-extensions \
    gnome-tweaks \
    qt5ct \
    qt6ct \
    kvantum \
    kvantum-qt5 \
    inotify-tools \
    libjxl \
    imagemagick \
    python-gobject \
    curl \
    wget \
    tar \
    xz
else
  echo "⚠️ Package manager not recognized. Please ensure dependencies (including Kvantum & qt5ct/qt6ct) are installed manually."
fi

mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$SYSTEMD_USER_DIR" "$THEMES_USER_DIR" "${XDG_CONFIG_HOME:-$HOME/.config}/environment.d"

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
echo "✅ Installed binaries in $BIN_DIR"

# 6. Enable GNOME User Theme Extension
echo ""
echo "🧩 Step 6: Enabling GNOME Shell User Themes extension..."

# Enable user extensions globally in GNOME
gsettings set org.gnome.shell disable-user-extensions false 2>/dev/null || true

# Add user-theme to enabled-extensions directly in dconf
python3 -c "
try:
    import gi
    from gi.repository import Gio
    s = Gio.Settings.new('org.gnome.shell')
    s.set_boolean('disable-user-extensions', False)
    current = list(s.get_strv('enabled-extensions'))
    ext = 'user-theme@gnome-shell-extensions.gcampax.github.com'
    if ext not in current:
        current.append(ext)
        s.set_strv('enabled-extensions', current)
except Exception:
    pass
" 2>/dev/null || true

# Enable via CLI & D-Bus call
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com 2>/dev/null || true
busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions EnableExtension s "user-theme@gnome-shell-extensions.gcampax.github.com" 2>/dev/null || true
echo "✅ user-theme extension enabled automatically."

# 7. Configure Qt / Kvantum Environment for GNOME
echo ""
echo "🪟 Step 7: Configuring Qt5/Qt6 & Kvantum environment for GNOME..."
ENV_D_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d"
mkdir -p "$ENV_D_DIR"
cat > "$ENV_D_DIR/90-matugen-qt.conf" << 'EOF'
QT_QPA_PLATFORMTHEME=qt5ct
QT_STYLE_OVERRIDE=kvantum
QT_QPA_PLATFORM=xcb
EOF

# Also add to ~/.profile for X11 / display manager login sessions
if ! grep -q 'QT_STYLE_OVERRIDE=kvantum' "$HOME/.profile" 2>/dev/null; then
  cat >> "$HOME/.profile" << 'EOF'

# GNOME Matugen Qt / Kvantum integration
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=kvantum
export QT_QPA_PLATFORM=xcb
EOF
fi

systemctl --user set-environment \
  QT_QPA_PLATFORMTHEME=qt5ct \
  QT_STYLE_OVERRIDE=kvantum \
  QT_QPA_PLATFORM=xcb 2>/dev/null || true

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
  dbus-update-activation-environment --systemd \
    QT_QPA_PLATFORMTHEME=qt5ct \
    QT_STYLE_OVERRIDE=kvantum \
    QT_QPA_PLATFORM=xcb 2>/dev/null || true
fi
echo "✅ Kvantum & native GNOME Qt titlebars configured."

# 8. Configure Systemd Service
echo ""
echo "🔄 Step 8: Configuring Systemd user service..."
cp "$SCRIPT_DIR/systemd/matugen-gnome.service" "$SYSTEMD_USER_DIR/matugen-gnome.service"
systemctl --user daemon-reload
systemctl --user enable --now matugen-gnome.service
echo "✅ Systemd service enabled and started."

# 9. Add ~/.local/bin to PATH in bashrc if needed
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  if ! grep -q 'PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "ℹ️ Added ~/.local/bin to ~/.bashrc"
  fi
fi

# 10. Apply theme for the first time
echo ""
echo "✨ Step 9: Generating initial theme..."
export PATH="$BIN_DIR:$PATH"
"$BIN_DIR/gnome-matugen-apply" || true

echo ""
echo "=========================================================="
echo " 🎉 Installation Complete!"
echo " GNOME & Qt (Kvantum) are now dynamically themed with Material You."
echo ""
echo " Useful Commands:"
echo "   - Apply theme manually: gnome-matugen-apply"
echo "   - Service status:       systemctl --user status matugen-gnome.service"
echo "   - Service logs:         journalctl --user -u matugen-gnome.service -f"
echo "=========================================================="

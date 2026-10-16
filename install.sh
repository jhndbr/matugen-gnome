#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Installer for GNOME Matugen Material You Themer
# Tested on Debian 13 (Trixie), Ubuntu, Arch Linux, and Fedora
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gnome-matugen"
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
THEMES_USER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/themes"
ICONS_USER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"

echo "=========================================================="
echo " 🎨  GNOME Matugen Material You - Complete Installer"
echo "=========================================================="
echo ""

install_apt_pkgs() {
  if ! sudo apt-get install -y "$@" 2>/dev/null; then
    for pkg in "$@"; do
      sudo apt-get install -y "$pkg" 2>/dev/null || echo "ℹ️ Optional/transitional package '$pkg' skipped."
    done
  fi
}

install_pacman_pkgs() {
  if ! sudo pacman -S --needed --noconfirm "$@" 2>/dev/null; then
    for pkg in "$@"; do
      sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null || echo "ℹ️ Optional package '$pkg' skipped."
    done
  fi
}

install_dnf_pkgs() {
  if ! sudo dnf install -y "$@" 2>/dev/null; then
    for pkg in "$@"; do
      sudo dnf install -y "$pkg" 2>/dev/null || echo "ℹ️ Optional package '$pkg' skipped."
    done
  fi
}

# 1. Install System & Qt/Kvantum Dependencies
echo "📦 Step 1: Installing system, GTK, Icon, and Qt5/Qt6 + Kvantum dependencies..."
if command -v apt-get >/dev/null 2>&1; then
  # Comment out active cdrom entries on fresh Debian installs so apt-get update does not fail
  if grep -q '^deb cdrom:' /etc/apt/sources.list 2>/dev/null; then
    sudo sed -i '/^deb cdrom:/s/^/# /' /etc/apt/sources.list 2>/dev/null || true
  fi
  sudo apt-get update || true

  echo "  -> Installing core GNOME, Matugen & Papirus dependencies..."
  install_apt_pkgs \
    sassc \
    gnome-shell-extensions \
    gnome-shell-extension-prefs \
    gnome-tweaks \
    inotify-tools \
    libjxl-tools \
    imagemagick \
    librsvg2-bin \
    papirus-icon-theme \
    libgtk-3-bin \
    gtk-update-icon-cache \
    python3 \
    python3-gi \
    python3-pil \
    gir1.2-glib-2.0 \
    gir1.2-gdkpixbuf-2.0 \
    curl \
    wget \
    tar \
    xz-utils \
    dbus-x11

  echo "  -> Installing Qt5ct, Qt6ct & Kvantum style engines..."
  install_apt_pkgs \
    qt5ct \
    qt6ct \
    qt-style-kvantum \
    qt5-style-kvantum \
    qt6-style-kvantum \
    qt-style-kvantum-themes \
    qt5-style-kvantum-themes \
    libqt5svg5 \
    libqt6svg6 \
    libxcb-cursor0 \
    qtwayland5 \
    qt6-wayland

elif command -v pacman >/dev/null 2>&1; then
  echo "  -> Installing packages via pacman (Arch Linux)..."
  install_pacman_pkgs \
    sassc \
    gnome-shell-extensions \
    gnome-tweaks \
    qt5ct \
    qt6ct \
    kvantum \
    kvantum-qt5 \
    qt5-wayland \
    qt6-wayland \
    qt5-svg \
    qt6-svg \
    papirus-icon-theme \
    gtk-update-icon-cache \
    inotify-tools \
    libjxl \
    imagemagick \
    librsvg \
    python-gobject \
    python-pillow \
    curl \
    wget \
    tar \
    xz

elif command -v dnf >/dev/null 2>&1; then
  echo "  -> Installing packages via dnf (Fedora)..."
  install_dnf_pkgs \
    sassc \
    gnome-shell-extensions \
    gnome-tweaks \
    qt5ct \
    qt6ct \
    kvantum \
    qt5-qtwayland \
    qt6-qtwayland \
    qt5-qtsvg \
    qt6-qtsvg \
    papirus-icon-theme \
    gtk-update-icon-cache \
    inotify-tools \
    libjxl-tools \
    ImageMagick \
    librsvg2-tools \
    python3-gobject \
    python3-pillow \
    curl \
    wget \
    tar \
    xz
else
  echo "⚠️ Package manager not recognized. Please ensure sassc, papirus-icon-theme, qt5ct, qt6ct, and kvantum are installed."
fi

# Verify Qt & Kvantum installation status
for tool in qt5ct qt6ct kvantummanager; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "  ✅ $tool is installed ($(command -v "$tool"))"
  else
    echo "  ⚠️ Warning: $tool was not found in PATH"
  fi
done

mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$SYSTEMD_USER_DIR" "$THEMES_USER_DIR" "$ICONS_USER_DIR" "${XDG_CONFIG_HOME:-$HOME/.config}/environment.d"

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

# 4. Install Papirus icon theme & papirus-folders
echo ""
echo "📁 Step 4: Installing Papirus icon theme and papirus-folders..."
mkdir -p "$ICONS_USER_DIR" "$BIN_DIR"

# Repair or remove any broken partial overlay from older versions
if [[ -d "$ICONS_USER_DIR/Papirus" ]]; then
  if [[ ! -d "$ICONS_USER_DIR/Papirus/128x128" || ! -d "$ICONS_USER_DIR/Papirus/48x48/apps" ]] || \
     grep -q "Material You Dynamic Icons" "$ICONS_USER_DIR/Papirus/index.theme" 2>/dev/null; then
    echo "🧹 Cleaning up incomplete Papirus overlay in $ICONS_USER_DIR..."
    rm -rf "$ICONS_USER_DIR/Papirus" "$ICONS_USER_DIR/Papirus-Dark" "$ICONS_USER_DIR/Papirus-Light"
  fi
fi

if [[ ! -d "$ICONS_USER_DIR/Papirus" || ! -d "$ICONS_USER_DIR/Papirus-Dark" ]]; then
  if [[ -d "/usr/share/icons/Papirus" ]]; then
    echo "📦 Copying complete Papirus icon themes from system to $ICONS_USER_DIR..."
    for variant in Papirus Papirus-Dark Papirus-Light; do
      if [[ -d "/usr/share/icons/$variant" ]]; then
        rm -rf "$ICONS_USER_DIR/$variant"
        cp -ra "/usr/share/icons/$variant" "$ICONS_USER_DIR/$variant"
      fi
    done
  else
    echo "📥 Downloading complete Papirus Icon Theme to $ICONS_USER_DIR..."
    wget -qO- https://git.io/papirus-icon-theme-install | env DESTDIR="$ICONS_USER_DIR" sh || true
  fi
fi

for variant in Papirus Papirus-Dark Papirus-Light; do
  if [[ -d "$ICONS_USER_DIR/$variant" ]]; then
    chmod -R u+w "$ICONS_USER_DIR/$variant" 2>/dev/null || true
  fi
done

if [[ ! -x "$BIN_DIR/papirus-folders" ]] && ! command -v papirus-folders >/dev/null 2>&1; then
  echo "📥 Downloading papirus-folders helper..."
  curl -sSLo "$BIN_DIR/papirus-folders" https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders || true
  chmod +x "$BIN_DIR/papirus-folders" 2>/dev/null || true
  echo "✅ papirus-folders installed to $BIN_DIR/papirus-folders"
else
  echo "✅ papirus-folders is ready."
fi

# 5. Copy Templates
echo ""
echo "📁 Step 5: Installing Matugen templates..."
rm -rf "$CONFIG_DIR/templates"
cp -r "$SCRIPT_DIR/templates" "$CONFIG_DIR/templates"
echo "✅ Templates installed to $CONFIG_DIR/templates"

# 6. Install Executables
echo ""
echo "⚙️ Step 6: Installing executables..."
cp "$SCRIPT_DIR/bin/gnome-matugen-apply" "$BIN_DIR/gnome-matugen-apply"
cp "$SCRIPT_DIR/bin/gnome-matugen-daemon" "$BIN_DIR/gnome-matugen-daemon"
cp "$SCRIPT_DIR/bin/sync-papirus-folders" "$BIN_DIR/sync-papirus-folders"
chmod +x "$BIN_DIR/gnome-matugen-apply" "$BIN_DIR/gnome-matugen-daemon" "$BIN_DIR/sync-papirus-folders"
echo "✅ Installed binaries in $BIN_DIR"

# 7. Enable GNOME User Theme Extension
echo ""
echo "🧩 Step 7: Enabling GNOME Shell User Themes extension..."

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

# 8. Configure Qt / Kvantum Environment for GNOME
echo ""
echo "🪟 Step 8: Configuring Qt5/Qt6 & Kvantum environment for GNOME..."
ENV_D_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d"
mkdir -p "$ENV_D_DIR"
cat > "$ENV_D_DIR/90-matugen-qt.conf" << 'EOF'
QT_QPA_PLATFORMTHEME=qt5ct
QT_STYLE_OVERRIDE=kvantum
QT_QPA_PLATFORM=xcb
EOF

# Add to ~/.profile for login sessions
if ! grep -q 'QT_STYLE_OVERRIDE=kvantum' "$HOME/.profile" 2>/dev/null; then
  cat >> "$HOME/.profile" << 'EOF'

# GNOME Matugen Qt / Kvantum integration
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=kvantum
EOF
fi

# Add to ~/.bashrc for interactive bash terminals
if [[ -f "$HOME/.bashrc" ]] && ! grep -q 'QT_QPA_PLATFORMTHEME=qt5ct' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" << 'EOF'

# GNOME Matugen Qt / Kvantum integration
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=kvantum
EOF
fi

# Add to ~/.zshrc for interactive zsh terminals
if [[ -f "$HOME/.zshrc" ]] && ! grep -q 'QT_QPA_PLATFORMTHEME=qt5ct' "$HOME/.zshrc" 2>/dev/null; then
  cat >> "$HOME/.zshrc" << 'EOF'

# GNOME Matugen Qt / Kvantum integration
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_STYLE_OVERRIDE=kvantum
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

# 9. Configure Systemd Service
echo ""
echo "🔄 Step 9: Configuring Systemd user service..."
cp "$SCRIPT_DIR/systemd/matugen-gnome.service" "$SYSTEMD_USER_DIR/matugen-gnome.service"
systemctl --user daemon-reload
systemctl --user enable --now matugen-gnome.service
echo "✅ Systemd service enabled and started."

# 10. Add ~/.local/bin to PATH in bashrc if needed
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  if ! grep -q 'PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "ℹ️ Added ~/.local/bin to ~/.bashrc"
  fi
fi

# 11. Apply theme for the first time
echo ""
echo "✨ Step 10: Generating initial theme..."
export PATH="$BIN_DIR:$PATH"
"$BIN_DIR/gnome-matugen-apply" || true

echo ""
echo "=========================================================="
echo " 🎉 Installation Complete!"
echo " GNOME, Papirus Icons & Qt (qt5ct/qt6ct + Kvantum) are now"
echo " dynamically themed with Material You."
echo ""
echo " Useful Commands:"
echo "   - Apply theme manually: gnome-matugen-apply"
echo "   - Service status:       systemctl --user status matugen-gnome.service"
echo "   - Service logs:         journalctl --user -u matugen-gnome.service -f"
echo "=========================================================="

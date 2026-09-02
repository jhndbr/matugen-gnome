# GNOME Matugen Material You Themer 🎨

Automatic, dynamic Material You (Material Design 3) theme generator and applier for **GNOME Shell**, **GTK 4 / Libadwaita**, **GTK 3 (adw-gtk3)**, **Papirus Folder Icons**, and **Qt 5 / Qt 6** on **Debian 13 (Trixie)** and modern Linux distributions.

---

## ✨ Features

- 🖼️ **Dynamic Wallpaper Theming**: Automatically extracts color palettes from your active GNOME wallpaper (including JPEG XL `.jxl`) using [Matugen](https://github.com/InioX/matugen).
- 🌓 **Instant Light / Dark Mode Sync**: Reacts immediately when toggling GNOME's Dark/Light mode using native GNOME GSettings/GIO event listeners.
- 📁 **Adaptive Papirus Folder Icons**: Dynamically adjusts Papirus folder icon colors to match your Material You accent palette.
- 🐚 **Full GNOME Shell Theming**: Dynamically re-compiles the GNOME Shell stylesheet (`Material-You`) with `sassc` and applies it in real-time without restarting GNOME.
- 🪟 **Unified GTK 3 & GTK 4**: Themes Libadwaita (GTK4) and legacy GTK3 applications (via `adw-gtk3`) with identical colors.
- ⚙️ **Qt Support**: Generates color schemes for `qt5ct` and `qt6ct`.
- 🔄 **Native Background Daemon**: Runs as a lightweight Systemd user service monitoring `gsettings` changes via GIO with zero CPU overhead and instant response.

---

## 📋 Requirements

The installer automatically installs and configures:
- **Debian 13 (Trixie)** / Ubuntu / Fedora with GNOME 45, 46, 47, or 48.
- `sassc`
- `gnome-shell-extensions` (specifically `user-theme`)
- `gnome-tweaks`
- `qt5ct` & `qt6ct`
- `papirus-icon-theme` & `papirus-folders`
- `libjxl-tools` & `imagemagick` (for `.jxl` wallpapers)
- `python3-gi` (for native GSettings events)
- [Matugen](https://github.com/InioX/matugen) (Auto-downloaded if not present)
- [adw-gtk3](https://github.com/lassekongo83/adw-gtk3) (Auto-downloaded if not present)

---

## 🚀 Quick Start (Installation)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/<your-user>/matugen-gnome-themer.git
   cd matugen-gnome-themer
   ```

2. **Run the installer:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

3. **That's it!** The installer will:
   - Install required packages.
   - Install Papirus icon theme & `papirus-folders`.
   - Set up templates in `~/.config/gnome-matugen/templates`.
   - Install the helper binaries in `~/.local/bin/`.
   - Enable the `user-theme` GNOME extension.
   - Start the background auto-theming service (`matugen-gnome.service`).
   - Apply the theme and sync folder icons immediately.

---

## 🛠️ Manual Usage

You can trigger or customize the theme anytime from your terminal:

```bash
# Apply theme using current GNOME wallpaper & sync Papirus icons
gnome-matugen-apply

# Apply theme with a specific image
gnome-matugen-apply --image ~/Pictures/wallpaper.jpg

# Apply theme from a custom HEX color
gnome-matugen-apply --color "#7c3aed"

# Force Dark or Light mode
gnome-matugen-apply --mode dark
gnome-matugen-apply --mode light

# Use a different Material You palette scheme
# (scheme-tonal-spot, scheme-expressive, scheme-fruit-salad, scheme-rainbow, scheme-fidelity, scheme-content)
gnome-matugen-apply --type scheme-fruit-salad
```

---

## 🔄 Service Management

The background daemon monitors your wallpaper and color-scheme changes automatically:

```bash
# Check service status
systemctl --user status matugen-gnome.service

# View live logs
journalctl --user -u matugen-gnome.service -f

# Restart service
systemctl --user restart matugen-gnome.service

# Stop service
systemctl --user stop matugen-gnome.service
```

---

## 🗑️ Uninstallation

To cleanly remove the theme, service, and configuration:

```bash
./uninstall.sh
```

---

## 📁 Project Structure

```
matugen-gnome-themer/
├── bin/
│   ├── gnome-matugen-apply      # Theme generator and applier
│   ├── gnome-matugen-daemon     # Native GIO background event listener
│   └── sync-papirus-folders     # Dynamic Papirus icon folder color adapter
├── systemd/
│   └── matugen-gnome.service    # Systemd user unit
├── templates/
│   ├── gtk.css                  # Libadwaita / GTK3 & GTK4 color definitions
│   ├── qtct.conf                # Qt5ct / Qt6ct palette definitions
│   ├── gnome-shell.scss         # GNOME Shell root stylesheet
│   ├── gnome-shell-colors.scss  # GNOME Shell dynamic color mapping
│   └── gnome-shell-sass/        # Modular GNOME Shell SCSS sources
├── install.sh                   # One-step installer
├── uninstall.sh                 # Clean uninstaller
├── LICENSE                      # MIT License
└── README.md
```

---

## 🤝 Acknowledgments

- [Matugen](https://github.com/InioX/matugen) by InioX
- [adw-gtk3](https://github.com/lassekongo83/adw-gtk3) by lassekongo83
- [Papirus Development Team](https://github.com/PapirusDevelopmentTeam)
- [GNOME Shell Sass](https://gitlab.gnome.org/GNOME/gnome-shell)

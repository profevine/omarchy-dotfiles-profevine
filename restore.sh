#!/bin/bash
# Restore personal configs on top of a fresh omarchy install.
# Usage: bash restore.sh
# Run AFTER omarchy has been installed (boot.sh already executed).

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$DOTFILES_DIR/config"
CONFIG_DST="$HOME/.config"

files=(
  hypr/bindings.conf
  hypr/hyprland.conf
  hypr/input.conf
  hypr/looknfeel.conf
  hypr/monitors.conf
  hypr/workspaces.conf
  waybar/config.jsonc
  waybar/style.css
  waybar/battery_threshold.sh
  waybar/power_usage.sh
  waybar/custom_weather.sh
  omarchy/extensions/menu.sh
)

for f in "${files[@]}"; do
  src="$CONFIG_SRC/$f"
  dst="$CONFIG_DST/$f"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "restored: ~/.config/$f"
done

echo ""
echo "Done. Reload Hyprland (Super+Shift+Q → logout) for changes to take effect."

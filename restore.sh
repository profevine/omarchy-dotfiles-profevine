#!/bin/bash
# Script para restaurar as configurações do Omarchy em uma instalação limpa.
# Detecta automaticamente o hostname e aplica configurações específicas de máquina se disponíveis.
# Uso: bash restore.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$DOTFILES_DIR/config"
CONFIG_DST="$HOME/.config"
hostname_suffix=$(hostname)

echo "--- Iniciando Restauração das Configurações ---"
echo "Hostname detectado: $hostname_suffix"

# 1. Arquivos gerais que são os mesmos para todas as máquinas
general_files=(
  hypr/bindings.conf
  hypr/hyprland.conf
  hypr/looknfeel.conf
  hypr/workspaces.conf
  hypr/appearance.lua
  hypr/autostart.lua
  hypr/bindings.lua
  hypr/hyprland.lua
  hypr/looknfeel.lua
  waybar/style.css
  waybar/battery_threshold.sh
  waybar/power_usage.sh
  waybar/custom_weather.sh
  systemd/user/fix-downloads-perms.service
  omarchy/extensions/menu.sh
  omarchy/extensions/omarchy-menu.jsonc
)

for f in "${general_files[@]}"; do
  src="$CONFIG_SRC/$f"
  dst="$CONFIG_DST/$f"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "Restaurado (geral): ~/.config/$f"
  fi
done

# 2. Arquivos específicos de máquina (procura por <nome>.<hostname>.<ext>, cai para <nome>.<ext> se não achar)
machine_files=(
  hypr/monitors.conf
  hypr/input.conf
  hypr/monitors.lua
  hypr/input.lua
  hypr/hyprmoncfg-monitors.lua
  waybar/config.jsonc
  omarchy/shell.json
)

for mf in "${machine_files[@]}"; do
  dir_name=$(dirname "$mf")
  base_name=$(basename "$mf")
  extension="${base_name##*.}"
  name_without_ext="${base_name%.*}"
  
  src_machine="$CONFIG_SRC/$dir_name/${name_without_ext}.${hostname_suffix}.${extension}"
  src_fallback="$CONFIG_SRC/$mf"
  dst="$CONFIG_DST/$mf"
  
  if [ -f "$src_machine" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src_machine" "$dst"
    echo "Restaurado (específico de $hostname_suffix): ~/.config/$mf"
  elif [ -f "$src_fallback" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src_fallback" "$dst"
    echo "Restaurado (padrão): ~/.config/$mf"
  else
    echo "Aviso: Arquivo de configuração $mf não encontrado no repositório."
  fi
done

# Faugus Launcher: o app completa sozinho as chaves que faltarem no config.json
if [ -f "$CONFIG_SRC/faugus-launcher/config.json" ]; then
  mkdir -p "$CONFIG_DST/faugus-launcher"
  cp "$CONFIG_SRC/faugus-launcher/config.json" "$CONFIG_DST/faugus-launcher/config.json"
  echo "Restaurado: ~/.config/faugus-launcher/config.json"
fi

# Plugins do Omarchy shell: copia os próprios e reinstala os de terceiros pelo git
if [ -d "$CONFIG_SRC/omarchy/plugins" ]; then
  mkdir -p "$CONFIG_DST/omarchy/plugins"
  for p in "$CONFIG_SRC/omarchy/plugins"/*/; do
    name=$(basename "$p")
    rm -rf "$CONFIG_DST/omarchy/plugins/$name"
    cp -r "$p" "$CONFIG_DST/omarchy/plugins/$name"
    echo "Restaurado (plugin): ~/.config/omarchy/plugins/$name"
  done
fi

if [ -f "$CONFIG_SRC/omarchy/plugins-third-party.txt" ] && command -v omarchy &> /dev/null; then
  while read -r url; do
    [ -z "$url" ] && continue
    omarchy plugin add "$url" --yes || echo "Aviso: falha ao instalar plugin $url"
  done < "$CONFIG_SRC/omarchy/plugins-third-party.txt"
fi

# 3. Restaurar scripts e atalhos em ~/.local
echo ""
echo "Restaurando scripts e atalhos em ~/.local..."
local_files=(
  "bin/fix-downloads-perms.sh"
  "share/nautilus/scripts/Destravar Permissões"
)

for lf in "${local_files[@]}"; do
  src="$DOTFILES_DIR/local/$lf"
  dst="$HOME/.local/$lf"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    chmod +x "$dst"
    echo "Restaurado: ~/.local/$lf"
  fi
done

# 4. Ativar serviço de permissões do usuário
if command -v systemctl &> /dev/null; then
    echo "Ativando serviço fix-downloads-perms..."
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable --now fix-downloads-perms.service 2>/dev/null || true
fi

echo ""
echo "Restauração concluída! Reinicie o Hyprland (Super+Shift+Q -> logout) para aplicar."

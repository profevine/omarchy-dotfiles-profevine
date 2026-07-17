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
  waybar/style.css
  waybar/battery_threshold.sh
  waybar/power_usage.sh
  waybar/custom_weather.sh
  omarchy/extensions/menu.sh
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
  waybar/config.jsonc
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

echo ""
echo "Restauração concluída! Reinicie o Hyprland (Super+Shift+Q -> logout) para aplicar."

#!/bin/bash
# Script para atualizar o Omarchy e aplicar configurações do GitHub nesta máquina.
# Este script é focado em DOWNLOAD: ele puxa do GitHub e aplica localmente.

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$DOTFILES_DIR/config"
CONFIG_DST="$HOME/.config"

echo "--- Iniciando Atualização (Modo Download) ---"

# 1. Atualizar o sistema Omarchy
if command -v omarchy-update &> /dev/null; then
    echo "Atualizando Omarchy..."
    omarchy-update
else
    echo "Comando omarchy-update não encontrado, pulando..."
fi

# 2. Puxar as configurações mais recentes do GitHub
cd "$DOTFILES_DIR"
echo "Buscando atualizações no GitHub..."

# Descarta mudanças locais que possam impedir o pull (segurança para máquinas novas)
git fetch origin main
git reset --hard origin/main

# 3. Aplicar as configurações do repositório no sistema (~/.config)
echo "Sincronizando arquivos de configuração com ~/.config..."

files=(
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

for f in "${files[@]}"; do
  src="$CONFIG_SRC/$f"
  dst="$CONFIG_DST/$f"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "Aplicado: ~/.config/$f"
  fi
done

# Aplicar arquivos específicos de máquina com sufixo do hostname ou manter locais
hostname_suffix=$(hostname)
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
    echo "Aplicado: ~/.config/$mf (específico de $hostname_suffix)"
  elif [ -f "$src_fallback" ] && [ ! -f "$dst" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src_fallback" "$dst"
    echo "Aplicado: ~/.config/$mf (padrão do repositório)"
  else
    echo "Mantido: ~/.config/$mf local (específico desta máquina)"
  fi
done

# 4. Recarregar Hyprland para aplicar as mudanças
if command -v hyprctl &> /dev/null; then
    echo "Recarregando Hyprland..."
    hyprctl reload
fi

echo "--- Concluído! Configurações do GitHub aplicadas com sucesso. ---"

#!/bin/bash
# Script para atualizar o Omarchy, sincronizar com o GitHub e atualizar configurações locais.

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$DOTFILES_DIR/config"
CONFIG_DST="$HOME/.config"

echo "--- Iniciando Atualização e Sincronização ---"

# 1. Atualizar o sistema Omarchy (se o comando estiver disponível)
if command -v omarchy-update &> /dev/null; then
    echo "Atualizando Omarchy..."
    omarchy-update
else
    echo "Comando omarchy-update não encontrado, pulando..."
fi

# 2. Sincronizar com o GitHub
cd "$DOTFILES_DIR"

# Puxar mudanças remotas primeiro
echo "Buscando atualizações no GitHub..."
git pull origin main

# Verificar se há mudanças locais para enviar
if [[ -n $(git status -s) ]]; then
    echo "Detectadas mudanças locais. Enviando para o GitHub..."
    git add .
    git commit -m "sync: auto-update from $(hostname) em $(date +'%Y-%m-%d %H:%M:%S')"
    git push origin main
else
    echo "Nenhuma mudança local para sincronizar."
fi

# 3. Atualizar as configurações locais (~/.config) baseadas no repositório
echo "Atualizando arquivos de configuração local (~/.config)..."

# Lista de arquivos para sincronizar (baseada no restore.sh)
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
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "Atualizado: ~/.config/$f"
  fi
done

# 4. Recarregar Hyprland
if command -v hyprctl &> /dev/null; then
    echo "Recarregando Hyprland..."
    hyprctl reload
fi

echo "--- Tudo pronto! Sistema e dotfiles atualizados. ---"

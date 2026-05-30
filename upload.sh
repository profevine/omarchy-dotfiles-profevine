#!/bin/bash
# Script para enviar as configurações ATUAIS desta máquina para o GitHub.
# Use isto apenas na máquina onde você fez as modificações que deseja salvar.

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$DOTFILES_DIR/config"
CONFIG_DST="$HOME/.config"

echo "--- Iniciando Upload de Configurações para o GitHub ---"

# 1. Copiar as configurações ativas do sistema (~/.config) para o repositório
echo "Copiando configurações ativas de ~/.config para o repositório..."

# Lista de arquivos para sincronizar
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
  src="$CONFIG_DST/$f"
  dst="$CONFIG_SRC/$f"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "Copiado: $f"
  else
    echo "Aviso: Arquivo ativo não encontrado ($src), ignorando..."
  fi
done

# 2. Sincronizar com o GitHub
cd "$DOTFILES_DIR"

# Verifica se houve alguma alteração real nos arquivos copiados
if [[ -z $(git status -s) ]]; then
    echo "Nenhuma mudança detectada entre suas configurações ativas e o repositório."
    echo "O GitHub já está atualizado!"
    exit 0
fi

echo "Mudanças detectadas. Preparando para enviar..."

# Usa uma mensagem de commit personalizada se fornecida ($1), senão usa a padrão
COMMIT_MSG=${1:-"update: configurações salvas de $(hostname) em $(date +'%Y-%m-%d %H:%M:%S')"}

git add .
git commit -m "$COMMIT_MSG"
git push origin main

echo "--- Concluído! Suas configurações foram salvas no GitHub com sucesso. ---"

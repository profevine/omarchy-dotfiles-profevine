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

# Lista de arquivos gerais para sincronizar
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

# Copiar arquivos específicos de máquina com sufixo do hostname
hostname_suffix=$(hostname)
machine_files=(
  hypr/monitors.conf
  hypr/input.conf
  waybar/config.jsonc
)

for mf in "${machine_files[@]}"; do
  src="$CONFIG_DST/$mf"
  dir_name=$(dirname "$mf")
  base_name=$(basename "$mf")
  extension="${base_name##*.}"
  name_without_ext="${base_name%.*}"
  dst="$CONFIG_SRC/$dir_name/${name_without_ext}.${hostname_suffix}.${extension}"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "Copiado com sufixo da máquina: $mf -> ${dir_name}/${name_without_ext}.${hostname_suffix}.${extension}"
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

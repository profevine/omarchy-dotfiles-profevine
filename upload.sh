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

# Copiar scripts e atalhos em ~/.local
local_files=(
  "bin/fix-downloads-perms.sh"
  "share/nautilus/scripts/Destravar Permissões"
)

for lf in "${local_files[@]}"; do
  src="$HOME/.local/$lf"
  dst="$DOTFILES_DIR/local/$lf"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    chmod +x "$dst"
    echo "Copiado (.local): $lf"
  fi
done

# Copiar arquivos específicos de máquina com sufixo do hostname
hostname_suffix=$(hostname)
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

# Plugins do Omarchy shell: os próprios (sem .git) são copiados inteiros;
# os de terceiros são clones git e só têm a URL registrada para reinstalar.
PLUGINS_SRC="$CONFIG_DST/omarchy/plugins"
PLUGINS_DST="$CONFIG_SRC/omarchy/plugins"
THIRD_PARTY_LIST="$CONFIG_SRC/omarchy/plugins-third-party.txt"

if [ -d "$PLUGINS_SRC" ]; then
  mkdir -p "$PLUGINS_DST"
  : > "$THIRD_PARTY_LIST"
  for p in "$PLUGINS_SRC"/*/; do
    name=$(basename "$p")
    if [ -e "$p/.git" ]; then
      url=$(git -C "$p" remote get-url origin 2>/dev/null || true)
      [ -n "$url" ] && echo "$url" >> "$THIRD_PARTY_LIST"
    else
      rm -rf "$PLUGINS_DST/$name"
      cp -r "$p" "$PLUGINS_DST/$name"
      echo "Copiado (plugin): omarchy/plugins/$name"
    fi
  done
fi

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

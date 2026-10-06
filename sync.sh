#!/bin/bash
# Atualiza o Omarchy e aplica nesta máquina as configurações do GitHub.
# Arquivos de máquina (monitores, teclado, barra, host.lua) vêm da versão desta
# máquina no repositório; sem ela, o arquivo local é mantido.
# Uso: ./sync.sh [--no-update]   (--no-update pula o omarchy-update)

set -e
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$DOTFILES_DIR"

echo "--- Sincronizando $HOST com o GitHub ---"

adopt_upstream_if_matching || true
if [ -n "$(git status --porcelain)" ]; then
  echo "O repositório tem mudanças que ainda não foram para o GitHub:"
  git status --short
  echo "Salve com ./upload.sh ou descarte com 'git checkout -- .' e rode de novo."
  exit 1
fi

if [ "$1" != "--no-update" ] && command -v omarchy-update &> /dev/null; then
  echo "Atualizando o Omarchy..."
  omarchy-update
fi

echo "Buscando atualizações no GitHub..."
if ! git pull --ff-only origin main; then
  echo "Este repositório tem commits que não estão no GitHub. Rode ./upload.sh antes."
  exit 1
fi

apply_configs
reload_desktop
record_applied

echo "--- Concluído! Configurações aplicadas em $HOST. ---"

#!/bin/bash
# Envia as configurações ATUAIS desta máquina para o GitHub.
# Uso: ./upload.sh ["mensagem do commit"]

set -e
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$DOTFILES_DIR"

echo "--- Upload das configurações de $HOST ---"

# Mudanças soltas no repositório costumam ser o Nextcloud trazendo arquivos de
# outra máquina; salvar por cima delas misturaria as duas.
adopt_upstream_if_matching || true
if [ -n "$(git status --porcelain)" ]; then
  echo "O repositório tem mudanças que não são desta execução:"
  git status --short
  echo "Confira (ou descarte com 'git checkout -- .') e rode de novo."
  exit 1
fi

# Parte da versão mais recente, para não desfazer o que a outra máquina enviou
git pull --ff-only origin main

save_configs

if [ -z "$(git status --porcelain)" ]; then
  echo "Nenhuma mudança: o GitHub já está atualizado."
  exit 0
fi

git status --short
git add .
git commit -m "${1:-"update: configurações salvas de $HOST em $(date +'%Y-%m-%d %H:%M:%S')"}"
git push origin main

echo "--- Concluído! Configurações de $HOST salvas no GitHub. ---"

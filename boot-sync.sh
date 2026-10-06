#!/bin/bash
# Roda o sync.sh ao entrar na sessão (dotfiles-sync.service), sem o
# omarchy-update, que pede senha. Não aplica nada se esta máquina tiver
# mudanças que ainda não foram para o GitHub: avisa para rodar o upload.sh.
# Log: journalctl --user -u dotfiles-sync

set -u
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$DOTFILES_DIR" || exit 1

notify() {
  echo "$2"
  command -v notify-send &> /dev/null && notify-send -a Dotfiles -u "$1" "Dotfiles" "$2"
}

wait_for() {
  local tries=$1; shift
  until "$@"; do
    tries=$((tries - 1))
    [ "$tries" -le 0 ] && return 1
    sleep 20
  done
}

github_ok() { GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=10" git ls-remote -q origin main > /dev/null 2>&1; }
repo_clean() { adopt_upstream_if_matching > /dev/null 2>&1; [ -z "$(git status --porcelain)" ]; }

if ! wait_for 9 github_ok; then
  notify normal "Sem acesso ao GitHub; dotfiles não atualizados neste boot."
  exit 0
fi

# Logo após o boot o Nextcloud pode estar baixando o que a outra máquina mudou
if ! wait_for 30 repo_clean; then
  notify critical "Repositório com mudanças soltas; sync não rodou. Veja 'git status' em $DOTFILES_DIR."
  exit 1
fi

base=$(cat "$APPLIED_FILE" 2>/dev/null || git rev-parse HEAD)
git cat-file -e "$base^{commit}" 2>/dev/null || base=$(git rev-parse HEAD)
changes=$(local_changes "$base")
if [ -n "$changes" ]; then
  notify critical "$HOST tem mudanças não enviadas; nada foi sobrescrito. Rode ./upload.sh:
$changes"
  exit 0
fi

before=$(git rev-parse HEAD)
if ./sync.sh --no-update; then
  after=$(git rev-parse HEAD)
  if [ "$before" != "$after" ]; then
    notify normal "Atualizado: $(git log --oneline "$before..$after" | wc -l) commit(s) novo(s) aplicado(s)."
  else
    echo "Já estava atualizado."
  fi
else
  notify critical "sync.sh falhou. Veja: journalctl --user -u dotfiles-sync"
  exit 1
fi

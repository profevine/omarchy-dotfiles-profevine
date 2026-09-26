#!/usr/bin/env bash
set -euo pipefail

TARGET="$HOME/Downloads"
mkdir -p "$TARGET"

fix_perms() {
    # Localiza arquivos e pastas em Downloads sem permissão de escrita para o usuário e corrige
    find "$TARGET" -mindepth 1 ! -writable -exec chmod u+rwX {} + 2>/dev/null || true
}

# Execução inicial para corrigir itens já existentes
fix_perms

# Monitora recursivamente novos arquivos e pastas criados ou movidos para ~/Downloads
inotifywait -m -r -q -e create,moved_to --format '%e' "$TARGET" 2>/dev/null | while read -r _event; do
    # Debounce de 1 segundo para aguardar o término da extração de múltiplos arquivos
    while read -t 1 -r _event; do :; done
    fix_perms
done

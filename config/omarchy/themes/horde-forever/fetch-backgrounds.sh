#!/bin/bash
# Baixa da Warcraft Wiki os papéis de parede listados em backgrounds.txt que
# ainda não estão em backgrounds/. Pode rodar de novo: só baixa o que falta.
# Uso: fetch-backgrounds.sh

set -euo pipefail

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API="https://warcraft.wiki.gg/api.php"
UA="Mozilla/5.0 (X11; Linux x86_64) omarchy-theme-horde-forever"

mkdir -p "$THEME_DIR/backgrounds"
fetched=0

while read -r name wiki_file; do
  [[ -z $name || $name == \#* ]] && continue
  dst="$THEME_DIR/backgrounds/$name"
  [[ -s $dst ]] && continue

  # A URL do arquivo muda quando a wiki recebe uma versão nova, então é
  # resolvida pela API a cada download em vez de ficar fixa na lista.
  url=$(curl -sfG "$API" -A "$UA" \
    --data-urlencode action=query --data-urlencode prop=imageinfo \
    --data-urlencode iiprop=url --data-urlencode format=json \
    --data-urlencode "titles=File:$wiki_file" |
    jq -r '.query.pages[].imageinfo[0].url // empty')

  if [[ -z $url ]] || ! curl -sfL -A "$UA" -o "$dst.part" "$url"; then
    rm -f "$dst.part"
    echo "Aviso: não consegui baixar $wiki_file" >&2
    continue
  fi
  mv "$dst.part" "$dst"
  echo "Baixado: $name"
  fetched=$((fetched + 1))
done < "$THEME_DIR/backgrounds.txt"

echo "$fetched papéis de parede novos."

#!/bin/bash
# Lista de arquivos e regras de cópia compartilhadas por upload.sh, sync.sh e
# restore.sh. Mantenha a lista só aqui: foi um sync.sh com lista própria que
# ficou desatualizado e parou de aplicar a config nova.
#
# Cada máquina é identificada pelo hostname (ch3n = desktop, m33po = notebook).
# No repositório, uma versão da máquina é salva como <nome>.<hostname>.<ext>,
# por exemplo config/hypr/monitors.ch3n.lua.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$DOTFILES_DIR/config"
CONFIG_DST="$HOME/.config"
HOST="$(hostname)"

# Iguais em todas as máquinas. Se uma máquina precisar de uma versão própria de
# um deles, basta existir <nome>.<hostname>.<ext> no repositório: ela passa a
# ser usada e atualizada no lugar da geral, só naquela máquina.
GENERAL_FILES=(
  hypr/hyprland.lua
  hypr/bindings.lua
  hypr/looknfeel.lua
  hypr/appearance.lua
  hypr/autostart.lua
  omarchy/extensions/omarchy-menu.jsonc
  omarchy/extensions/menu.sh
  systemd/user/fix-downloads-perms.service
  systemd/user/app-Nextcloud@autostart.service.d/restart.conf
  systemd/user/dotfiles-sync.service
  systemd/user/windows-vm-perms.service
  # Legado (antes do Omarchy Quattro e do Omarchy shell)
  hypr/bindings.conf
  hypr/hyprland.conf
  hypr/looknfeel.conf
  hypr/workspaces.conf
  waybar/style.css
  waybar/battery_threshold.sh
  waybar/power_usage.sh
  waybar/custom_weather.sh
)

# Sempre de cada máquina. Uma máquina sem versão própria no repositório mantém
# o arquivo local; nunca recebe o de outra máquina, que teria monitores,
# teclado ou barra errados.
MACHINE_FILES=(
  hypr/host.lua
  hypr/monitors.lua
  hypr/input.lua
  hypr/hyprmoncfg-monitors.lua
  omarchy/shell.json
  # Legado
  hypr/monitors.conf
  hypr/input.conf
  waybar/config.jsonc
)

LOCAL_FILES=(
  "bin/fix-downloads-perms.sh"
  "bin/webcam-overlay"
  "bin/imv-sized"
  "bin/windows-vm-perms"
  "share/nautilus/scripts/Destravar Permissões"
  "share/applications/imv.desktop"
)

# hypr/host.lua -> hypr/host.ch3n.lua
host_variant() {
  local f="$1" dir base
  dir=$(dirname "$f")
  base=$(basename "$f")
  echo "$dir/${base%.*}.$HOST.${base##*.}"
}

is_machine_file() {
  local f
  for f in "${MACHINE_FILES[@]}"; do [ "$f" = "$1" ] && return 0; done
  return 1
}

copy_file() {
  mkdir -p "$(dirname "$2")"
  cp "$1" "$2"
}

# ~/.config -> repositório
save_configs() {
  local f repo_path
  for f in "${GENERAL_FILES[@]}" "${MACHINE_FILES[@]}"; do
    [ -f "$CONFIG_DST/$f" ] || continue
    if is_machine_file "$f" || [ -f "$CONFIG_SRC/$(host_variant "$f")" ]; then
      repo_path=$(host_variant "$f")
    else
      repo_path="$f"
    fi
    copy_file "$CONFIG_DST/$f" "$CONFIG_SRC/$repo_path"
    echo "Salvo: $repo_path"
  done

  local lf
  for lf in "${LOCAL_FILES[@]}"; do
    [ -f "$HOME/.local/$lf" ] || continue
    copy_file "$HOME/.local/$lf" "$DOTFILES_DIR/local/$lf"
    chmod +x "$DOTFILES_DIR/local/$lf"
    echo "Salvo: local/$lf"
  done

  save_faugus
  save_plugins
  save_themes
}

# repositório -> ~/.config
apply_configs() {
  local f
  for f in "${GENERAL_FILES[@]}" "${MACHINE_FILES[@]}"; do
    local variant general
    variant="$CONFIG_SRC/$(host_variant "$f")"
    general="$CONFIG_SRC/$f"
    if [ -f "$variant" ]; then
      copy_file "$variant" "$CONFIG_DST/$f"
      echo "Aplicado: ~/.config/$f (de $HOST)"
    elif is_machine_file "$f"; then
      [ -f "$CONFIG_DST/$f" ] && echo "Mantido: ~/.config/$f (local, sem versão de $HOST no repositório)"
    elif [ -f "$general" ]; then
      copy_file "$general" "$CONFIG_DST/$f"
      echo "Aplicado: ~/.config/$f"
    fi
  done

  # hyprland.lua carrega o host.lua; ele precisa existir mesmo sem nada dentro
  if [ ! -f "$CONFIG_DST/hypr/host.lua" ]; then
    mkdir -p "$CONFIG_DST/hypr"
    echo "-- Configurações só desta máquina ($HOST)" > "$CONFIG_DST/hypr/host.lua"
    echo "Criado: ~/.config/hypr/host.lua (vazio)"
  fi

  local lf
  for lf in "${LOCAL_FILES[@]}"; do
    [ -f "$DOTFILES_DIR/local/$lf" ] || continue
    copy_file "$DOTFILES_DIR/local/$lf" "$HOME/.local/$lf"
    chmod +x "$HOME/.local/$lf"
    echo "Aplicado: ~/.local/$lf"
  done

  apply_faugus
  apply_plugins
  apply_themes

  if command -v systemctl &> /dev/null; then
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable --now fix-downloads-perms.service 2>/dev/null || true
    systemctl --user enable dotfiles-sync.service 2>/dev/null || true
    systemctl --user enable --now windows-vm-perms.service 2>/dev/null || true
  fi

  apply_nextcloud
}

# Cliente do Nextcloud: arquivos que o servidor apagar vão para a lixeira desta
# máquina em vez de sumir, e ele pergunta antes de apagar tudo de uma pasta. Em
# 01/10/2026 uma exclusão de ~/Nextcloud/Projects numa máquina apagou a pasta no
# servidor e na outra. O cliente regrava o .cfg ao fechar, por isso é parado
# antes da edição.
NEXTCLOUD_CFG="$CONFIG_DST/Nextcloud/nextcloud.cfg"
NEXTCLOUD_SETTINGS=(moveToTrash=true promptDeleteAllFiles=true launchOnSystemStartup=true)

apply_nextcloud() {
  [ -f "$NEXTCLOUD_CFG" ] || return 0
  local kv missing=()
  for kv in "${NEXTCLOUD_SETTINGS[@]}"; do
    grep -qx "$kv" "$NEXTCLOUD_CFG" || missing+=("$kv")
  done
  [ ${#missing[@]} -eq 0 ] && return 0

  local unit=app-Nextcloud@autostart.service
  systemctl --user stop "$unit" 2>/dev/null || true
  pkill -x nextcloud 2>/dev/null && sleep 2
  for kv in "${missing[@]}"; do
    if grep -q "^${kv%%=*}=" "$NEXTCLOUD_CFG"; then
      sed -i "s/^${kv%%=*}=.*/$kv/" "$NEXTCLOUD_CFG"
    else
      sed -i "/^\[General\]/a $kv" "$NEXTCLOUD_CFG"
    fi
    echo "Aplicado (Nextcloud): $kv"
  done
  systemctl --user start "$unit" 2>/dev/null || (setsid nextcloud --background &> /dev/null &)
}

# Faugus Launcher: só as preferências. A chave da SteamGridDB fica de fora por
# ser segredo, tempo de jogo e datas porque mudam sozinhos a cada uso, e o
# tamanho da janela porque depende da tela de cada máquina.
FAUGUS_SKIP='del(."steamgriddb-api-key", .playtime, ."donate-last", ."backup-last-date", .width, .height)'

save_faugus() {
  local src="$CONFIG_DST/faugus-launcher/config.json"
  [ -f "$src" ] && command -v jq &> /dev/null || return 0
  mkdir -p "$CONFIG_SRC/faugus-launcher"
  jq "$FAUGUS_SKIP" "$src" > "$CONFIG_SRC/faugus-launcher/config.json"
  echo "Salvo (sem segredos): faugus-launcher/config.json"
}

# Mescla por cima do arquivo local, que continua com o tempo de jogo, as datas
# e a chave da SteamGridDB desta máquina.
apply_faugus() {
  local repo="$CONFIG_SRC/faugus-launcher/config.json"
  local dst="$CONFIG_DST/faugus-launcher/config.json"
  [ -f "$repo" ] || return 0
  if [ -f "$dst" ] && command -v jq &> /dev/null; then
    jq -s '.[0] * .[1]' "$dst" "$repo" > "$dst.tmp" && mv "$dst.tmp" "$dst"
  else
    copy_file "$repo" "$dst"
  fi
  echo "Aplicado: ~/.config/faugus-launcher/config.json"
}

# Plugins do Omarchy shell: os próprios (sem .git) vão inteiros para o
# repositório; os de terceiros são clones git e só têm a URL registrada.
PLUGINS_LIST="$CONFIG_SRC/omarchy/plugins-third-party.txt"

save_plugins() {
  local src="$CONFIG_DST/omarchy/plugins" p name url
  [ -d "$src" ] || return 0
  mkdir -p "$CONFIG_SRC/omarchy/plugins"
  touch "$PLUGINS_LIST"
  for p in "$src"/*/; do
    name=$(basename "$p")
    if [ -e "$p/.git" ]; then
      # Acrescenta sem apagar: um plugin que só a outra máquina usa continua na lista
      url=$(git -C "$p" remote get-url origin 2>/dev/null || true)
      if [ -n "$url" ] && ! grep -qxF "$url" "$PLUGINS_LIST"; then
        echo "$url" >> "$PLUGINS_LIST"
      fi
    else
      rm -rf "$CONFIG_SRC/omarchy/plugins/$name"
      cp -r "$p" "$CONFIG_SRC/omarchy/plugins/$name"
      echo "Salvo (plugin): omarchy/plugins/$name"
    fi
  done
}

# Instala só o que falta. Plugins copiados ficam disponíveis, mas aparecer na
# barra depende do shell.json de cada máquina.
apply_plugins() {
  local dst="$CONFIG_DST/omarchy/plugins" p name url
  mkdir -p "$dst"
  if [ -d "$CONFIG_SRC/omarchy/plugins" ]; then
    for p in "$CONFIG_SRC/omarchy/plugins"/*/; do
      name=$(basename "$p")
      rm -rf "$dst/$name"
      cp -r "$p" "$dst/$name"
      echo "Aplicado (plugin): ~/.config/omarchy/plugins/$name"
    done
  fi

  [ -f "$PLUGINS_LIST" ] && command -v omarchy &> /dev/null || return 0
  local installed
  installed=$(for p in "$dst"/*/; do git -C "$p" remote get-url origin 2>/dev/null || true; done)
  while read -r url; do
    [ -z "$url" ] && continue
    grep -qxF "$url" <<< "$installed" && continue
    omarchy plugin add "$url" --yes || echo "Aviso: falha ao instalar plugin $url"
  done < "$PLUGINS_LIST"
}

# Temas próprios (sem .git). Um tema com fetch-backgrounds.sh baixa os papéis
# de parede sozinho, então vai sem a pasta backgrounds/: as imagens são de
# terceiros e pesadas demais para o repositório.
save_themes() {
  local src="$CONFIG_DST/omarchy/themes" t name
  [ -d "$src" ] || return 0
  for t in "$src"/*/; do
    [ -e "$t/.git" ] && continue
    name=$(basename "$t")
    rm -rf "$CONFIG_SRC/omarchy/themes/$name"
    mkdir -p "$CONFIG_SRC/omarchy/themes"
    cp -r "$t" "$CONFIG_SRC/omarchy/themes/$name"
    if [ -x "$t/fetch-backgrounds.sh" ]; then
      rm -rf "$CONFIG_SRC/omarchy/themes/$name/backgrounds"
    fi
    echo "Salvo (tema): omarchy/themes/$name"
  done
}

apply_themes() {
  local src="$CONFIG_SRC/omarchy/themes" t name dst
  [ -d "$src" ] || return 0
  for t in "$src"/*/; do
    name=$(basename "$t")
    dst="$CONFIG_DST/omarchy/themes/$name"
    mkdir -p "$dst"
    # Copia por cima sem apagar a pasta, para manter os papéis de parede já baixados
    cp -r "$t". "$dst/"
    echo "Aplicado (tema): ~/.config/omarchy/themes/$name"
    if [ -x "$dst/fetch-backgrounds.sh" ]; then
      "$dst/fetch-backgrounds.sh" || echo "Aviso: falha ao baixar papéis de parede de $name"
    fi
  done
}

reload_desktop() {
  if command -v hyprctl &> /dev/null; then
    hyprctl reload > /dev/null && echo "Hyprland recarregado."
    local errors
    errors=$(hyprctl configerrors 2>/dev/null) || true
    [ -n "$errors" ] && [ "$errors" != "no errors" ] && echo "Aviso: erros na config do Hyprland:" && echo "$errors"
  fi
  # O shell só relê o código de plugins alterados quando é reiniciado
  if command -v omarchy &> /dev/null && pgrep -f "quickshell.*omarchy" > /dev/null; then
    omarchy restart shell > /dev/null 2>&1 && echo "Omarchy shell reiniciado."
  fi
  # Sem sessão gráfica (ex.: via SSH) não há o que recarregar; não é falha
  return 0
}

# Último commit aplicado nesta máquina. O boot-sync.sh compara ~/.config com
# ele para saber se há mudanças locais que ainda não foram para o GitHub.
APPLIED_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-sync/applied"

record_applied() {
  mkdir -p "$(dirname "$APPLIED_FILE")"
  git -C "$DOTFILES_DIR" rev-parse HEAD > "$APPLIED_FILE"
}

# Lista os arquivos do repositório que esta máquina mudou desde o commit dado:
# roda o save_configs numa cópia descartável desse commit e vê o que mudou.
# Arquivos que só existem aqui (sem versão no repositório) não contam, porque
# o apply_configs nunca os sobrescreve; diferença só de permissão também não
# (o Nextcloud perde o bit de execução).
local_changes() {
  local base="$1" tmp
  tmp=$(mktemp -d)
  git -C "$DOTFILES_DIR" archive "$base" | tar -x -C "$tmp"
  (
    cd "$tmp" || exit 1
    git init -q && git config core.fileMode false
    git add -A && git -c user.name=x -c user.email=x@x commit -qm base
    bash -c 'source ./lib.sh; save_configs' > /dev/null 2>&1
    # A lista de plugins não entra: o apply_plugins só instala, nunca remove
    git status --porcelain | grep -v '^??' | cut -c4- | grep -vx 'config/omarchy/plugins-third-party.txt'
  )
  rm -rf "$tmp"
}

# O Nextcloud sincroniza os arquivos deste repositório mas ignora o .git. Quando
# a outra máquina faz push, os arquivos novos chegam por aqui antes do commit, e
# o git os vê como mudanças soltas. Se a pasta já está idêntica ao GitHub, só
# avança o git para lá; os arquivos não são tocados.
adopt_upstream_if_matching() {
  [ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ] || return 0
  git -C "$DOTFILES_DIR" fetch -q origin main || return 1
  local old
  old=$(git -C "$DOTFILES_DIR" rev-parse HEAD)
  git -C "$DOTFILES_DIR" merge-base --is-ancestor "$old" origin/main || return 1
  git -C "$DOTFILES_DIR" reset -q origin/main
  if [ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]; then
    git -C "$DOTFILES_DIR" reset -q "$old"
    return 1
  fi
  echo "Repositório alinhado ao GitHub (o Nextcloud já tinha trazido os arquivos)."
}

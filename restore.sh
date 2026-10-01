#!/bin/bash
# Restaura as configurações numa instalação limpa do Omarchy.
# Arquivos de máquina vêm da versão deste hostname no repositório; uma máquina
# nova, sem versão própria, fica com os padrões do Omarchy para eles.
# Uso: bash restore.sh

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

echo "--- Restaurando configurações em $HOST ---"
apply_configs
reload_desktop
echo "--- Concluído! Se algo não aplicou, saia e entre de novo na sessão. ---"

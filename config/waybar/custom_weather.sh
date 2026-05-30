#!/bin/bash

# Locais solicitados
LOCATIONS=("Sao+Luiz+Gonzaga" "Santo+Antonio+das+Missoes" "Roque+Gonzales")
DISPLAY_NAMES=("São Luiz Gonzaga" "Santo Antônio das Missões" "Roque Gonzales")

fetch_weather() {
    local loc=$1
    local name=$2
    # Busca dados básicos: ícone (via omarchy-weather-icon se possível, mas wttr.in é mais simples aqui para múltiplos)
    # Vamos usar o formato simplificado para o Waybar
    data=$(curl -fsS --max-time 4 "https://wttr.in/$loc?format=%t" 2>/dev/null)
    if [[ -n "$data" ]]; then
        echo "$name: $data"
    else
        echo "$name: ?"
    fi
}

# Para o ícone geral, usamos a primeira localização
main_icon=$(omarchy-weather-icon 2>/dev/null)
[[ -z "$main_icon" ]] && main_icon=""

# Imprimindo apenas o ícone para a Waybar
printf '{"text":"%s"}\n' "$main_icon"

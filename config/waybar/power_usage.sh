#!/bin/bash

BAT_PATH="/sys/class/power_supply/BAT1"
[ ! -d "$BAT_PATH" ] && BAT_PATH="/sys/class/power_supply/BAT0"

if [ ! -d "$BAT_PATH" ]; then
    echo "{\"text\": \"N/A\"}"
    exit 0
fi

uA=$(cat "$BAT_PATH/current_now" 2>/dev/null)
uV=$(cat "$BAT_PATH/voltage_now" 2>/dev/null)
status=$(cat "$BAT_PATH/status" 2>/dev/null)

if [ -z "$uA" ] || [ -z "$uV" ] || [ "$uA" -eq 0 ]; then
    echo "{\"text\": \"0W\"}"
    exit 0
fi

# Cálculo para 1 casa decimal
val=$(( (uA * uV) / 100000000000 ))
w_int=$(( val / 10 ))
w_dec=$(( val % 10 ))

text="${w_int}.${w_dec}W"

# Correção dos ícones:
# Tomada para carregando, Raio para consumindo/descarregando
if [ "$status" = "Charging" ]; then
    icon=""
else
    icon="󱐥"
fi

echo "{\"text\": \"$icon $text\", \"tooltip\": \"Status: $status\nConsumo: $text\"}"

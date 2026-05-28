#!/bin/bash

# Path to the battery threshold file
THRESHOLD_FILE="/sys/class/power_supply/BAT1/charge_control_end_threshold"

if [[ ! -f "$THRESHOLD_FILE" ]]; then
    # Fallback search if path differs
    THRESHOLD_FILE=$(find /sys/class/power_supply/*/charge_control_end_threshold -print -quit 2>/dev/null)
fi

if [[ -z "$THRESHOLD_FILE" ]]; then
    echo '{"text": "󰂑", "tooltip": "Battery protection not supported", "class": "unsupported"}'
    exit 0
fi

CURRENT_VALUE=$(cat "$THRESHOLD_FILE")

if [[ "$1" == "toggle" ]]; then
    if [[ "$CURRENT_VALUE" -eq 80 ]]; then
        NEW_VALUE=100
    else
        NEW_VALUE=80
    fi
    
    # Attempt to write using pkexec for a GUI password prompt
    if pkexec sh -c "echo $NEW_VALUE > $THRESHOLD_FILE"; then
        CURRENT_VALUE=$NEW_VALUE
    else
        # If cancelled or failed, keep current value
        :
    fi
fi

if [[ "$CURRENT_VALUE" -eq 80 ]]; then
    echo '{"text": "󱊞", "tooltip": "Battery Protection: ON (Limit 80%)", "class": "enabled"}'
else
    echo '{"text": "󱊣", "tooltip": "Battery Protection: OFF (Limit 100%)", "class": "disabled"}'
fi

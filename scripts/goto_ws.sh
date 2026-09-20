#!/bin/bash

requested="${1:-0}"

if ! [[ "$requested" =~ ^[0-9]+$ ]]; then
	echo "Fel: Du måste ange ett giltigt nummer."
	exit 1
fi

# SPECIALREGEL FÖR PAR 10 & 20
if [ "$requested" -eq 10 ]; then
	hyprctl dispatch 'hl.dsp.focus({ workspace = 10 })'
	exit 0
fi

# Räkna ut max_used
max_used=$(hyprctl clients -j | jq '
  [ .[] | .workspace.id | 
    if (. >= 11 and . <= 19) then . - 10 
    elif (. > 0 and . < 10) then . 
    else empty 
    end 
  ] | max // 0
')

allowed=$((max_used + 1))

if [ "$requested" -gt "$allowed" ]; then
	target_base="$allowed"
else
	target_base="$requested"
fi

target_left=$((target_base + 10))
target_right=$target_base

# Utför workspace-bytena
hyprctl dispatch 'hl.dsp.focus({ workspace = '$target_base' })'

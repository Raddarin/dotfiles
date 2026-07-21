#!/bin/bash

requested=$1

# SPECIALREGEL FÖR PAR 10 & 20: 
# Gå hit direkt och strunta i all max_used-logik så att du alltid når dem!
if [ "$requested" -eq 10 ]; then
	hyprctl dispatch movefocus l
	hyprctl dispatch workspace 20
	hyprctl dispatch movefocus r
	hyprctl dispatch workspace 10
	exit 0
fi

# (Resten av ditt skript förblir exakt likadant som innan...)
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

hyprctl dispatch movefocus l
hyprctl dispatch workspace "$target_left"
hyprctl dispatch movefocus r
hyprctl dispatch workspace "$target_right"

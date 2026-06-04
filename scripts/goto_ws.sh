#!/bin/bash

# Vilket workspace vill användaren gå till?
requested=$1

# Om det är workspace 10, gå dit direkt (specialregel)
if [ "$requested" -eq 10 ]; then
	hyprctl dispatch workspace 10
	exit 0
fi

# Hitta det högsta använda workspacet (exklusive 10 och special)
max_used=$(hyprctl clients -j | jq '[.[] | select(.workspace.id > 0 and .workspace.id < 10) | .workspace.id] | max // 0')

# Det högsta tillåtna workspacet är max_used + 1
allowed=$((max_used + 1))

if [ "$requested" -gt "$allowed" ]; then
	# Om användaren vill gå för långt, skicka dem till nästa lediga istället
	hyprctl dispatch workspace "$allowed"
else
	# Annars, gå dit de bad om
	hyprctl dispatch workspace "$requested"
fi

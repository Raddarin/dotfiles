#!/bin/bash

# Vi omdirigerar ALL output för hela skriptet till /dev/null direkt
exec >/dev/null 2>&1

# $1 = Bildsökväg
# $2, $3 = Koordinater

# Kör Pywal (tyst)
wal -i "$1" -n

# Kör hyprpaper (vi lägger till 'quiet' om möjligt, annars sköter exec ovan det)
hyprctl hyprpaper preload "$1"
hyprctl hyprpaper wallpaper ",$1"

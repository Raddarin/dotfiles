#!/bin/bash

# Vi hämtar parametern
VAL=$1

# I Bash använder vi [ ] för tester och $ framför variabelnamnet
if [ "$VAL" = "1" ]; then
	hyprctl hyprpaper wallpaper ",/home/Raddarin/Pictures/wallpapers/ygdrasill.png"
	wal -i "/home/Raddarin/Pictures/wallpapers/ygdrasill.png"
elif [ "$VAL" = "2" ]; then
	hyprctl hyprpaper wallpaper ",/home/Raddarin/Pictures/wallpapers/Red_Blosom.png"
	wal -i "/home/Raddarin/Pictures/wallpapers/Red_Blosom.png"
elif [ "$VAL" = "3" ]; then
	hyprctl hyprpaper wallpaper ",/home/Raddarin/Pictures/wallpapers/wp5712386-amoled-pc-wallpapers.png"
	wal -i "/home/Raddarin/Pictures/wallpapers/wp5712386-amoled-pc-wallpapers.png"
elif [ "$VAL" = "4" ]; then
	hyprctl hyprpaper wallpaper ",/home/Raddarin/Pictures/wallpapers/gargantua-black-3840x2160-9621.png"
	wal -i "/home/Raddarin/Pictures/wallpapers/gargantua-black-3840x2160-9621.png"
elif [ "$VAL" = "5" ]; then
	hyprctl hyprpaper wallpaper ",/home/Raddarin/Pictures/wallpapers/gargantua-endurance-3840x2160-25445.png"
	wal -i "/home/Raddarin/Pictures/wallpapers/gargantua-endurance-3840x2160-25445.png"
elif [ "$VAL" = "6" ]; then
	hyprctl hyprpaper wallpaper ",/home/Raddarin/Pictures/wallpapers/romantic-night-sky-5120x2880-25549.png"
	wal -i "/home/Raddarin/Pictures/wallpapers/romantic-night-sky-5120x2880-25549.png"
elif [ "$VAL" = "7" ]; then
	hyprctl hyprpaper wallpaper ",/home/Raddarin/Pictures/wallpapers/Mosaik_bird.png"
	wal -i "/home/Raddarin/Pictures/wallpapers/Mosaik_bird.png"

else
	echo "Användning: $0 1 eller 2"
fi

# Starta om Waybar för att ladda de nya Pywal-färgerna
killall waybar
waybar &

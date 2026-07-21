#!/bin/bash
target=$1

if [ "$target" -eq 10 ]; then
    left=20
    right=10
else
    left=$((target + 10))
    right=$target
fi

# Flytta fönstret till rätt workspace
hyprctl dispatch movetoworkspace "$right"

# Tvinga båda skärmarna att hoppa till paret och behåll fokus på höger
hyprctl dispatch focusmonitor HDMI-A-1
hyprctl dispatch workspace "$left"
hyprctl dispatch focusmonitor DP-1
hyprctl dispatch workspace "$right"

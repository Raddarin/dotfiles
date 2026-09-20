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
hyprctl dispatch 'hl.dsp.window.move({ workspace, follow, '$target' })'

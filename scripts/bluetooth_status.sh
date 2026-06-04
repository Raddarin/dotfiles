#!/usr/bin/env bash

icon="" # Bluetooth-ikon

# Defaultvärden
tooltip="Bluetooth av"
class="off"

# Är bluetooth på?
if bluetoothctl show | grep -q "Powered: yes"; then
	# Kolla om någon enhet är ansluten
	connected_name=""

	while read -r _ mac rest; do
		if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
			connected_name=$(bluetoothctl info "$mac" | awk -F': ' '/Name:/ {print $2; exit}')
			break
		fi
	done < <(bluetoothctl devices)

	if [ -n "$connected_name" ]; then
		tooltip="Ansluten: $connected_name"
		class="connected"
	else
		tooltip="Ingen enhet ansluten"
		class="on"
	fi
fi

# Skicka JSON till Waybar
printf '{"text":"%s","tooltip":"%s","class":["%s"]}\n' "$icon" "$tooltip" "$class"

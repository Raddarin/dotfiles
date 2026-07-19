import subprocess

# Kör kommandot
resultat = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True)

# Skriv texten direkt till filen
with open('/home/Raddarin/.config/scripts/save_workspaces/hyprland_layout.json', 'w') as f:
    f.write(resultat.stdout)

import json
import subprocess
import os
import socket
import time

def get_hypr_data(cmd):
    try:
        process = subprocess.run(['hyprctl', '-j', cmd], capture_output=True, text=True)
        return json.loads(process.stdout)
    except Exception:
        return []

def compress_workspaces():
    # En kort paus för att låta Hyprland uppdatera sin klientlista efter stängning
    time.sleep(0.1)
    
    clients = get_hypr_data('clients')
    if not clients:
        return

    # Filtrera: Endast vanliga workspaces (> 0), men INTE workspace 10
    active_clients = [c for c in clients if c['workspace']['id'] > 0 and c['workspace']['id'] != 10]
    
    if not active_clients:
        return

    # Sortera efter nuvarande workspace-ID
    active_clients.sort(key=lambda x: x['workspace']['id'])

    # Gruppera fönster per workspace
    ws_map = {}
    for c in active_clients:
        old_ws = c['workspace']['id']
        if old_ws not in ws_map:
            ws_map[old_ws] = []
        ws_map[old_ws].append(c['address'])

    batch_commands = []
    current_target_ws = 1
    
    for old_ws in sorted(ws_map.keys()):
        if current_target_ws == 10:
            current_target_ws += 1
            
        if old_ws != current_target_ws:
            for addr in ws_map[old_ws]:
                batch_commands.append(f"movetoworkspacesilent {current_target_ws},address:{addr}")
        
        current_target_ws += 1

    # Kör alla flyttar samtidigt om det finns några
    if batch_commands:
        batch_str = " ; ".join(batch_commands)
        subprocess.run(['hyprctl', 'dispatch', '--', batch_str])

def main():
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    if not signature:
        print("Kunde inte hitta HYPRLAND_INSTANCE_SIGNATURE. Kör du scriptet inuti Hyprland?")
        return

    # Testa den vanligaste sökvägen först, sen fallbacken
    socket_path = f"/run/user/{os.getuid()}/hypr/{signature}/.socket2.sock"
    if not os.path.exists(socket_path):
        socket_path = f"/tmp/hypr/{signature}/.socket2.sock"

    if not os.path.exists(socket_path):
        print(f"Kunde inte hitta socket2.sock på någon av standardplatserna.")
        return

    print(f"Ansluten till socket: {socket_path}")

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.connect(socket_path)
        while True:
            data = s.recv(4096).decode('utf-8')
            if any(event in data for event in ["openwindow", "closewindow", "movewindow"]):
                compress_workspaces()

if __name__ == "__main__":
    main()

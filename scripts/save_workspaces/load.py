import json
import subprocess
import time

def main():
    with open("/home/Raddarin/.config/scripts/save_workspaces/hyprland_layout.json", "r") as f:
        clients = json.load(f)
    print("1")
    komando_maping = {
        "Alacritty": "alacritty",
        "vivaldi-stable": "vivaldi",
        # Lägg till fler här om du stöter på andra program som vägrar starta
    }
    print("2")
    for client in clients:
        window = client.get("class", "") 
        if not window:
            continue
        terminal_comand = komando_maping.get(window, window.lower())
        if not terminal_comand:
            continue
        try:
            subprocess.Popen([terminal_comand])
        except FileNotFoundError:
            print(f"Kunde inte starta: {terminal_comand} (Hittade inte kommandot)")

    print("3")
    time.sleep(0.5)
    for client in clients:
        workspace = client["workspace"]["name"]
        program = client["class"]
        subprocess.run(["hyprctl", "dispatch", "movetoworkspace", f"{workspace},class:{program}"])       
        # if client["floating"]:
        #     os.system(f"hyprctl dispatch togglefloating class:{program}")
        #     x, y = client["at"]
        #     w, h = client["size"]
if __name__ == "__main__":
    main()

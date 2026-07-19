use hyprland::event_listener::EventListener;
use serde::Deserialize;
use std::process::Command;

#[derive(Deserialize, Debug, Clone, Default)]
struct WorkspaceInfo {
    id: i32,
}

#[derive(Deserialize, Debug, Clone, Default)]
struct HyprClient {
    address: String,
    workspace: WorkspaceInfo,
}

fn move_to(workspace: i32, address: String) {
    let target_arg = format!("{},address:{}", workspace, address);
    let _output = Command::new("hyprctl")
        .args(["dispatch", "movetoworkspacesilent", &target_arg])
        .output()
        .expect("Misslyckades att köra hyprctl");
}

fn compress() {
    let input = Command::new("hyprctl")
        .args(["clients", "-j"])
        .output()
        .expect("Misslyckades att köra hyprctl");

    let clients: Vec<HyprClient> = serde_json::from_slice(&input.stdout).unwrap_or_default();
    if clients.is_empty() {
        return;
    };

    // Array med 9 element, där varje element är ett par (tuple) av två Vektorer
    let mut client_workspaces: [(Vec<HyprClient>, Vec<HyprClient>); 9] =
        std::array::from_fn(|_| (Vec::new(), Vec::new()));

    for client in &clients {
        let id = client.workspace.id;
        if id >= 1 && id <= 9 {
            client_workspaces[(id - 1) as usize].0.push(client.clone());
        } else if id >= 11 && id <= 19 {
            client_workspaces[(id - 11) as usize].1.push(client.clone());
        } else if id == 21 {
            move_to(1, client.address.clone());
        }
        // // Mappa fönstret till rätt par-index baserat på dess bas-id
        // let base_id = if id >= 11 && id <= 19 {
        //     id - 10 // Vänster skärm (11 blir slot 1, 12 blir slot 2...)
        // } else if id >= 1 && id <= 9 {
        //     id // Höger skärm / Laptop-skärm
        // } else {
        //     continue; // Ignorera workspace 10 och andra special-workspaces
        // };
        //
        //     client_workspaces[(base_id - 1) as usize].push(client.clone());
    }

    let mut target_id = 1;
    let mut current_workspace_id = 0;
    for client_workspace in &client_workspaces {
        current_workspace_id += 1;
        if client_workspace.1.is_empty() && client_workspace.0.is_empty() {
            continue;
        }
        if current_workspace_id != target_id {
            for client_right in &client_workspace.0 {
                move_to(target_id, client_right.address.clone());
            }
            for client_left in &client_workspace.1 {
                move_to(target_id + 10, client_left.address.clone());
            }
        }

        target_id += 1;
        // for client in client_workspace {
        //     let current_id = client.workspace.id;
        //
        //     // Räkna ut målet men behåll fönstrets ursprungliga skärm (höger eller vänster)
        //     let target_id = if current_id >= 11 {
        //         target_base_id + 10 // Vänster skärm
        //     } else {
        //         target_base_id // Höger skärm
        //     };
        //
        //     // Flytta endast om fönstret faktiskt ligger på fel workspace
        //     if current_id != target_id {
        //         move_to(target_id, client.address.clone());
        //     }
        // }
    }
}

fn main() {
    let mut event_listener = EventListener::new();

    event_listener.add_window_closed_handler(|_| {
        compress();
    });

    event_listener
        .start_listener()
        .expect("Misslyckades att starta Hyprland event listener");
}

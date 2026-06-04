use serde::Deserialize;
use std::process::Command;
use std::time::Duration;

#[derive(Deserialize, Debug, Clone)]
struct WorkspaceInfo {
    id: i32,
    // name: String,
}

#[derive(Deserialize, Debug, Clone)]
struct HyprClient {
    address: String, // Denna kommer att vara t.ex. "5638af4608a0"
    //class: String,
    //title: String,
    workspace: WorkspaceInfo,
}
fn move_to(workspace: i32, address: String) {
    let target_arg = format!("{},address:{}", workspace, address);

    let _output = Command::new("hyprctl")
        .args(["dispatch", "movetoworkspacesilent", &target_arg])
        .output()
        .expect("Misslyckades att köra hyprctl");
}
fn main() {
    std::thread::sleep(Duration::from_millis(50));
    let input = Command::new("hyprctl")
        .args(["clients", "-j"])
        .output()
        .expect("Misslyckades att köra hyprctl");

    let mut clients: Vec<HyprClient> = serde_json::from_slice(&input.stdout).unwrap_or_default();
    if clients.len() == 0 {
        return;
    }

    clients.sort_by_key(|client| client.workspace.id);
    let mut client_workspaces: [Vec<HyprClient>; 9] = std::array::from_fn(|_| Vec::new());
    for client in &clients {
        if client.workspace.id < 10 {
            client_workspaces[(client.workspace.id - 1) as usize].push(client.clone());
        }
    }

    let mut id = 1;
    for client_workspace in &client_workspaces {
        if client_workspace.len() == 0 {
            continue;
        }
        if client_workspace[0].workspace.id > id {
            for client in client_workspace {
                move_to(id.clone(), client.address.clone());
            }
        }
        id += 1;
    }
}

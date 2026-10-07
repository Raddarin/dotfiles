use hyprland::event_listener::EventListener;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::process::Command;

#[derive(Serialize)]
struct WaybarOutput {
    text: String,
    tooltip: String,
    class: String,
}

// Structs för att avkoda Hyprlands JSON-output
#[derive(Deserialize)]
struct HyprClient {
    workspace: HyprWorkspace,
    class: String,
    title: String,
}

#[derive(Deserialize)]
struct HyprWorkspace {
    id: i32,
}

fn generate_waybar_string() -> String {
    let active_id = get_active_workspace();

    // Hämta klienter i JSON-format
    let output = Command::new("hyprctl")
        .args(["clients", "-j"])
        .output()
        .expect("Misslyckades att köra hyprctl");

    let clients: Vec<HyprClient> = serde_json::from_slice(&output.stdout).unwrap_or_default();
    let mut workspace_map: HashMap<i32, Vec<String>> = HashMap::new();

    for client in clients {
        let mut final_title = client.class.clone();
        if client.workspace.id == -98 {
            continue;
        }

        if client.class == "kitty" {
            if client.title.to_lowercase().contains("yazi") {
                final_title = "yazi".to_string();
            } else if client.title.to_lowercase().contains("nvim") {
                final_title = "nvim".to_string();
            } else if client.title.to_lowercase().contains("btop") {
                final_title = "btop".to_string();
            }
        } else if client.class.contains("zathura") {
            final_title = "zathura".to_string();
        }

        let icon = match final_title.to_lowercase().as_str() {
            "vivaldi-stable" => "",
            "kitty" => "",
            "spotify" => "",
            "mattermost-desktop" => "󰾆",
            "nvim" => "",
            "blueman-manager" => "",
            "yazi" => "",
            "btop" => "",
            "firefox" => "",
            "zathura" => "󰰶",
            "wofi" => "",
            "localsend" => "󱥸",
            "libreoffice-writer" => "󰷈",
            _ => "",
        };
        let mut id = client.workspace.id as i32 % 10;
        if id == 0 {
            id = 10;
        }
        workspace_map.entry(id).or_default().push(icon.to_string());
    }

    let mut ws_ids: Vec<i32> = workspace_map.keys().cloned().collect();
    ws_ids.sort();

    let mut final_pango_text = String::new();
    let total_ids = ws_ids.len();

    for (index, id) in ws_ids.iter().enumerate() {
        if let Some(icons) = workspace_map.get(id) {
            let icon_str = icons.join(" ");
            let content = format!("{}", icon_str);
            if id.to_string() == "10" {
                final_pango_text.push_str("<span color='#4C566A'>|</span>");
            }

            if id.to_string() == active_id {
                final_pango_text.push_str(&format!("<span color='#7dd6ff'>  {}  </span>", content));
            } else {
                final_pango_text.push_str(&format!("<span color='#D8DEE9'>  {}  </span>", content));
            }

            if index < total_ids - 1 {
                final_pango_text.push_str("<span color='#4C566A'>|</span>");
            }
        }
    }
    let final_text = if final_pango_text.is_empty() {
        "<span color='#4C566A'>  </span>".to_string()
    } else {
        final_pango_text.trim().to_string()
    };

    let waybar_json = WaybarOutput {
        text: final_text,
        tooltip: "Aktiva fönster".to_string(),
        class: "custom-workspaces".to_string(),
    };
    serde_json::to_string(&waybar_json).unwrap_or_else(|_| "{}".to_string())
}
fn get_active_workspace() -> String {
    let output = Command::new("hyprctl")
        .args(["activeworkspace", "-j"])
        .output()
        .ok();

    if let Some(o) = output {
        let stdout = String::from_utf8_lossy(&o.stdout);
        if let Some(id_pos) = stdout.find("\"id\":") {
            let start = id_pos + 5;
            let end = stdout[start..]
                .find(',')
                .unwrap_or(stdout[start..].find('}').unwrap_or(0));
            return stdout[start..start + end].trim().to_string();
        }
    }
    "1".to_string()
}

fn main() -> hyprland::Result<()> {
    println!("{}", generate_waybar_string());

    let mut event_listener = EventListener::new();

    event_listener.add_window_opened_handler(|_| {
        println!("{}", generate_waybar_string());
    });
    event_listener.add_window_closed_handler(|_| {
        println!("{}", generate_waybar_string());
    });
    event_listener.add_window_moved_handler(|_| {
        println!("{}", generate_waybar_string());
    });
    event_listener.add_workspace_changed_handler(|_| {
        println!("{}", generate_waybar_string());
    });

    event_listener.start_listener()
}

pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string workspaceText: ""

    Process {
        id: proc
        command: ["/home/Raddarin/.config/scripts/hypr-waybar-icons/target/release/hypr-waybar-icons"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                let raw = data.trim()
                if (raw.length === 0) return

                try {
                    let json = JSON.parse(raw)
                    if (json.text) {
                        let text = json.text

                        // Konvertera Pango <span color='...'> till Qt-kompatibel <font color='...'>
                        text = text.replace(/<span\s+color=['"]([^'"]+)['"]\s*>/g, "<font color='$1'>")
                                   .replace(/<\/span>/g, "</font>")

                        root.workspaceText = text
                    }
                } catch (e) {
                    console.warn("WorkspaceData: kunde inte tolka rad:", raw)
                    root.workspaceText = raw
                }
            }
        }

        // Rust-programmets felutskrifter (panics m.m.) hamnar i quickshells logg
        stderr: SplitParser {
            onRead: data => console.warn("hypr-waybar-icons stderr:", data)
        }

        // Om programmet dör: logga varför och starta om det
        onExited: (exitCode, exitStatus) => {
            console.warn("hypr-waybar-icons avslutades, kod", exitCode, "status", exitStatus, "– startar om")
            restartTimer.start()
        }
    }

    Timer {
        id: restartTimer
        interval: 1000
        onTriggered: proc.running = true
    }
}

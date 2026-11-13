pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string workspaceText: ""

    Process {
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
                    root.workspaceText = raw
                }
            }
        }
    }
}

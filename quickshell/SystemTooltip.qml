import QtQuick

// Innehållet som visas när rightWidget expanderar nedåt.
// Ligger inuti rightWidget, så den ritas över fönstren under (ingen exclusiveZone).
Item {
    id: tt

    property var status                       // SystemStatus-instansen
    readonly property real pad: 12
    property string shown: ""                 // senast visade tooltip (behålls under stängningsanimationen)

    Connections {
        target: tt.status
        function onTipChanged() {
            if (tt.status.tip !== "") tt.shown = tt.status.tip
        }
    }

    readonly property Item current:
        shown === "net" ? netInfo :
        shown === "bt" ? btInfo :
        shown === "battery" ? batInfo :
        shown === "cpu" ? cpuInfo : null

    implicitWidth: current ? current.implicitWidth + 2 * pad : 0
    implicitHeight: current ? current.implicitHeight + 2 + pad : 0

    // Håller tooltipen öppen så länge musen är över den
    HoverHandler {
        onHoveredChanged: {
            if (!tt.status) return
            tt.status.tooltipHovered = hovered
            if (!hovered) tt.status.leave()
        }
    }

    component T: Text {
        color: "#ffffff"
        font.pixelSize: 12
        font.family: "JetBrainsMono Nerd Font"
    }

    // ---------- Nätverk ----------
    Column {
        id: netInfo
        visible: tt.shown === "net"
        spacing: 3
        x: tt.pad
        y: 2

        T {
            font.bold: true
            text: tt.status.netType === "wifi" ? (tt.status.ssid || "Okänt nät")
                : tt.status.netType === "ethernet" ? "Ethernet (" + tt.status.netDev + ")"
                : "Ej ansluten"
        }
        T {
            visible: tt.status.netType === "wifi"
            color: "#aaaaaa"
            text: "Signal " + tt.status.wifiSignal + "%  ·  Länk " + tt.status.linkRate
        }
        T {
            visible: tt.status.netType !== "none"
            text: "↓ " + tt.status.fmtRate(tt.status.rxRate) + "   ↑ " + tt.status.fmtRate(tt.status.txRate)
        }
    }

    // ---------- Bluetooth ----------
    Column {
        id: btInfo
        visible: tt.shown === "bt"
        spacing: 3
        x: tt.pad
        y: 2

        T {
            font.bold: true
            text: !tt.status.btOn ? "Bluetooth av"
                : tt.status.btDevices.length === 0 ? "Ingen enhet ansluten"
                : "Ansluten till"
        }
        Repeater {
            model: tt.status.btOn ? tt.status.btDevices : []
            T { text: "• " + modelData }
        }
    }

    // ---------- Batteri ----------
    Column {
        id: batInfo
        visible: tt.shown === "battery"
        spacing: 3
        x: tt.pad
        y: 2

        T {
            font.bold: true
            text: tt.status.batteryPercent + "%  ·  " +
                  (tt.status.charging ? "Laddar"
                   : tt.status.batteryStatus === "Full" ? "Fulladdat"
                   : tt.status.batteryStatus === "Discharging" ? "Laddar ur"
                   : "Ansluten")
        }
        T {
            visible: tt.status.batteryHours >= 0
            color: "#aaaaaa"
            text: (tt.status.charging ? "Full om " : "Tom om ") + tt.status.fmtDuration(tt.status.batteryHours)
        }
    }

    // ---------- CPU ----------
    Column {
        id: cpuInfo
        visible: tt.shown === "cpu"
        spacing: 6
        x: tt.pad
        y: 2

        T {
            font.bold: true
            text: "CPU " + tt.status.cpuUsage + "%  ·  " + tt.status.coreUsage.length + " kärnor"
        }
        Grid {
            columns: tt.status.coreUsage.length <= 8 ? 2 : 4
            columnSpacing: 16
            rowSpacing: 4

            Repeater {
                model: tt.status.coreUsage

                Row {
                    spacing: 6
                    T {
                        width: 22
                        horizontalAlignment: Text.AlignRight
                        color: "#888888"
                        text: index
                    }
                    Item {
                        width: 46
                        height: 14
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 6
                            radius: 3
                            color: "#333333"
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width * modelData / 100
                            height: 6
                            radius: 3
                            color: modelData > 80 ? "#ff5555" : "#ffffff"
                            Behavior on width { NumberAnimation { duration: 300 } }
                        }
                    }
                    T {
                        width: 34
                        horizontalAlignment: Text.AlignRight
                        color: modelData > 5 ? "#ffffff" : "#666666"
                        text: modelData + "%"
                    }
                }
            }
        }
    }
}

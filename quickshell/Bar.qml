import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: window

    anchors { top: true; left: true; right: true }

    property bool expanded: false

    implicitHeight: 600                       // fast höjd (kalendern blir ~545 px hög)
    color: "transparent"                      // utan den här blir fönstret vitt

    exclusiveZone: expanded ? 37 : 0          // reservera bara själva baren, aldrig hela fönstret
    WlrLayershell.layer: WlrLayer.Top

    // Växla mellan liten och utfälld bar
    GlobalShortcut {
        name: "toggle_bar"
        onPressed: window.expanded = !window.expanded
    }

    // Klick tas bara emot på de synliga widgetarna, resten släpps igenom till fönstren under
    mask: Region {
        regions: [
            Region { item: window.expanded ? (expandedLoader.item ? expandedLoader.item.topLineItem : null)
                                           : (minifiedLoader.item ? minifiedLoader.item.island : null) },
            Region { item: window.expanded && expandedLoader.item ? expandedLoader.item.leftItem : null },
            Region { item: window.expanded && expandedLoader.item ? expandedLoader.item.centerItem : null },
            Region { item: window.expanded && expandedLoader.item ? expandedLoader.item.rightItem : null }
        ]
    }

    Loader {
        id: minifiedLoader
        active: !window.expanded
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter
        sourceComponent: ClockWidget {}
    }

    Loader {
        id: expandedLoader
        active: window.expanded
        anchors.fill: parent
        sourceComponent: ExtendedBar {}
    }
}

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: window

    anchors { top: true; left: true; right: true }

    property bool expanded: false
    readonly property bool calendarOpen: expandedLoader.item ? expandedLoader.item.calendarOpen : false

    // Ytan växer bara när kalendern är öppen
    implicitHeight: 450
    color: "transparent"

    // Reservera bara själva baren (5 px linje + 32 px), inte hela fönstret
    exclusiveZone: expanded ? 37 : 0
    WlrLayershell.layer: WlrLayer.Top

    GlobalShortcut {
        name: "toggle_bar"
        onPressed: window.expanded = !window.expanded
    }

    // Klick tas bara emot på de synliga widgetarna
    mask: Region {
        regions: [
            Region { item: window.expanded ? (expandedLoader.item ? expandedLoader.item.topLineItem : null) : minifiedLoader.item },
            Region { item: window.expanded && expandedLoader.item ? expandedLoader.item.leftItem : null },
            Region { item: window.expanded && expandedLoader.item ? expandedLoader.item.centerItem : null },
            Region { item: window.expanded && expandedLoader.item ? expandedLoader.item.rightItem : null }
        ]
    }

    Loader {
        id: minifiedLoader
        active: !window.expanded
        anchors.top: parent.top
        anchors.topMargin: 5                       // samma läge som förut (40 px ö i 50 px fönster)
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

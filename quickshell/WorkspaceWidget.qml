import QtQuick

Rectangle {
    id: workspaceIsland

    width: textItem.implicitWidth + 24
    height: 36
    radius: height / 2

    color: "#000000"
    border.color: "#222222"
    border.width: 1

    Row {
        anchors.centerIn: parent

        Text {
            id: textItem
            text: WorkspaceData.workspaceText
            color: "#ffffff"
            font.pixelSize: 16
            font.bold: true
            font.family: "JetBrains Mono, sans-serif"
            
            // Gör så att Pango/HTML-färgerna i skriptet tolkas korrekt
            textFormat: Text.StyledText
        }
    }
}

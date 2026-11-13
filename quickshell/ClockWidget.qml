import QtQuick
import QtQuick.Layouts

// Den lilla "ön" med bara klockan. Klick expanderar den till kalendern.
Rectangle {
    id: island

    property bool calendarOpen: false

    width: calendarOpen ? 340 : layout.implicitWidth + 68
    height: calendarOpen ? 40 + calendar.implicitHeight + 16 : 40
    radius: 20
    clip: true

    color: "#000000"
    border.color: "#222222"
    border.width: 1

    Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on height {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    // Klickbar yta är bara klockraden (översta 40 px), inte kalendern
    MouseArea {
        id: hoverArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        hoverEnabled: true
        onClicked: island.calendarOpen = !island.calendarOpen
    }

    RowLayout {
        id: layout
        anchors.horizontalCenter: parent.horizontalCenter
        y: (40 - height) / 2
        spacing: 1

        Text {
            text: Time.hoursMinutes
            color: "#ffffff"
            font.pixelSize: 14
            font.bold: true
            font.family: "JetBrains Mono, sans-serif"
        }

        Text {
            text: ":" + Time.seconds
            color: "#ffffff"
            font.pixelSize: 14
            font.bold: true
            font.family: "JetBrains Mono, sans-serif"

            visible: hoverArea.containsMouse
            opacity: hoverArea.containsMouse ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }
    }

    CalendarWidget {
        id: calendar
        active: island.calendarOpen
        anchors.top: parent.top
        anchors.topMargin: 44
        anchors.horizontalCenter: parent.horizontalCenter
        width: 300
        opacity: island.calendarOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }
}

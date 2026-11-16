import QtQuick
import QtQuick.Layouts

// Rot-Item = "platshållare" som grannar i baren ser: alltid den hopfällda storleken.
// Själva ön (island) växer utanför platshållaren när kalendern öppnas,
// så workspace-ön och andra widgetar inte flyttas.
Item {
    id: root

    readonly property bool calendarOpen: CalendarData.open

    // Används av Bar.qml för klickmasken (hela ön, inte bara platshållaren)
    property alias island: island

    width: layout.implicitWidth + 68
    height: 40
    

    Item {
        id: island

        // När kalendern är öppen fästs ön i skärmens överkant (samma form som i den utfällda baren)
        property real topPad: root.calendarOpen ? 5 : 0
        Behavior on topPad { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        anchors.horizontalCenter: parent.horizontalCenter
        y: -topPad

        width: root.calendarOpen ? calendar.implicitWidth + 40 : root.width
        height: root.calendarOpen ? topPad + 40 + 4 + calendar.implicitHeight + 24 : 40

        Behavior on width {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        // Bakgrund med rundade hörn (ritas separat så att den aldrig påverkas av clip)
        Rectangle {
            id: bg
            anchors.fill: parent
            color: "#000000"
            border.color: "#222222"
            border.width: 1

            topLeftRadius: root.calendarOpen ? 0 : 20
            topRightRadius: root.calendarOpen ? 0 : 20
            bottomLeftRadius: root.calendarOpen ? 16 : 20
            bottomRightRadius: root.calendarOpen ? 16 : 20

            Behavior on topLeftRadius { NumberAnimation { duration: 200 } }
            Behavior on topRightRadius { NumberAnimation { duration: 200 } }
            Behavior on bottomLeftRadius { NumberAnimation { duration: 200 } }
            Behavior on bottomRightRadius { NumberAnimation { duration: 200 } }
        }

        // Innehåll (klippt till ön)
        Item {
            anchors.fill: parent
            clip: true

            // Klickbar yta är bara klockraden (40 px), inte kalendern
            MouseArea {
                id: hoverArea
                anchors.top: parent.top
                anchors.topMargin: island.topPad
                anchors.left: parent.left
                anchors.right: parent.right
                height: 40
                hoverEnabled: true
                onClicked: CalendarData.open = !CalendarData.open
            }

            RowLayout {
                id: layout
                anchors.horizontalCenter: parent.horizontalCenter
                y: island.topPad + (40 - height) / 2
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
                active: root.calendarOpen
                anchors.top: parent.top
                anchors.topMargin: island.topPad + 44
                anchors.horizontalCenter: parent.horizontalCenter
                width: implicitWidth
                opacity: root.calendarOpen ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
    }
}

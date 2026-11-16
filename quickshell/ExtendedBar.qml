import QtQuick
import QtQuick.Layouts

Item {
    id: expandedBar
    anchors.fill: parent

    // Exponeras så att Bar.qml kan bygga en klickmask
    property alias topLineItem: topLine
    property alias leftItem: leftWidget
    property alias centerItem: centerWidget
    property alias rightItem: rightWidget

    // 1. Tunn linje längs skärmens överkant
    Rectangle {
        id: topLine
        height: 5
        color: "#000000"
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
    }

    // 2. Vänster widget (Workspaces)
    Rectangle {
        id: leftWidget
        height: 32
        width: leftLayout.implicitWidth + 24
        anchors.top: topLine.bottom
        anchors.left: parent.left
        anchors.leftMargin: 0

        color: "#000000"

        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: 0
        bottomRightRadius: 16

        Row {
            id: leftLayout
            anchors.centerIn: parent
            Text {
                text: WorkspaceData.workspaceText
                color: "#ffffff"
                font.pixelSize: 16
                font.bold: true
                font.family: "JetBrains Mono, sans-serif"
                textFormat: Text.StyledText
            }
        }
    }

    // 3. Mitten-widget (klockan, expanderar till kalendern)
    Item {
        id: centerWidget
        readonly property bool open: CalendarData.open

        height: open ? 32 + calendar.implicitHeight + 24 : 32
        width: open ? calendar.implicitWidth + 40 : centerLayout.implicitWidth + 68
        anchors.top: topLine.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        Behavior on width {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        // Bakgrund med rundade nedre hörn (ritas separat från innehållet)
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: 16
            bottomRightRadius: 16
        }

        Item {
            anchors.fill: parent
            clip: true

            // Klockraden (klickbar yta är bara de översta 32 px)
            Item {
                id: clockRow
                width: parent.width
                height: 32

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: CalendarData.open = !CalendarData.open
                }
                Row {
                    id: centerLayout
                    anchors.centerIn: parent
                    spacing: 2
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
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
            }

            CalendarWidget {
                id: calendar
                active: centerWidget.open
                anchors.top: clockRow.bottom
                anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                width: implicitWidth
                opacity: centerWidget.open ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
        }
    }

    // 4. Höger widget (systeminfo + expanderande tooltip)
    Rectangle {
        id: rightWidget
        readonly property bool tipOpen: rightStatus.tip !== ""

        height: 32 + (tipOpen ? rightTip.implicitHeight : 0)
        width: Math.max(rightStatus.implicitWidth + 24, tipOpen ? rightTip.implicitWidth : 0)
        anchors.top: topLine.bottom
        anchors.right: parent.right
        clip: true

        color: "#000000"

        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: 16
        bottomRightRadius: 0

        Behavior on width  { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        SystemStatus {
            id: rightStatus
            anchors.right: parent.right
            anchors.rightMargin: 12
            y: (32 - height) / 2
        }

        SystemTooltip {
            id: rightTip
            status: rightStatus
            anchors.top: parent.top
            anchors.topMargin: 32
            anchors.left: parent.left
            anchors.right: parent.right
            height: implicitHeight
        }
    }
}

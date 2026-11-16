import QtQuick
import QtQuick.Layouts

// Kalendern. Standard: kompakt månadsvy. Knappen "Vecka" (eller ett klick på ett
// veckonummer) fäller ut vecka + dag bredvid varandra. Allt tillstånd ligger i
// CalendarData, så alla instanser visar samma kalender.
Item {
    id: root

    // Sätts utifrån: true när widgeten är synlig/uppfälld
    property bool active: false

    // ---- Storlek (ändra här) ----
    readonly property real monthW: 350          // kompakt månadsvy
    readonly property real weekPanelW: 442      // veckovyn (36 + 7 * 58)
    readonly property real dayPanelW: 320       // dagsvyn
    readonly property real gap: 14
    readonly property int bodyHeight: 440

    readonly property bool weekMode: CalendarData.viewMode === "week"

    implicitWidth: weekMode ? weekPanelW + gap + dayPanelW : monthW
    implicitHeight: col.implicitHeight

    Component.onCompleted: if (active) CalendarData.acquire()
    Component.onDestruction: if (active) CalendarData.release()
    onActiveChanged: {
        if (active) CalendarData.acquire()
        else CalendarData.release()
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        // ---------- Header ----------
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            spacing: 8

            Text {
                text: "‹"
                color: "#ffffff"
                font.pixelSize: 22
                font.family: "JetBrains Mono, sans-serif"
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: CalendarData.step(-1)
                }
            }
            Text {
                text: "›"
                color: "#ffffff"
                font.pixelSize: 22
                font.family: "JetBrains Mono, sans-serif"
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    onClicked: CalendarData.step(1)
                }
            }
            Text {
                Layout.fillWidth: true
                text: CalendarData.titleText()
                elide: Text.ElideRight
                color: "#ffffff"
                font.pixelSize: 15
                font.bold: true
                font.family: "JetBrains Mono, sans-serif"
            }

            // Idag
            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 26
                radius: 13
                color: "transparent"
                border.color: "#444444"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Idag"
                    color: "#ffffff"
                    font.pixelSize: 12
                    font.family: "JetBrains Mono, sans-serif"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: CalendarData.goToday()
                }
            }

            // Växla: Vecka (expandera) / Månad (tillbaka)
            Rectangle {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 26
                radius: 13
                color: "#ffffff"
                Text {
                    anchors.centerIn: parent
                    text: root.weekMode ? "Månad" : "Vecka"
                    color: "#000000"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "JetBrains Mono, sans-serif"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: CalendarData.setMode(root.weekMode ? "month" : "week")
                }
            }
        }

        // Felmeddelande från skriptet
        Text {
            Layout.fillWidth: true
            visible: CalendarData.errorText !== ""
            text: CalendarData.errorText
            color: "#ff7777"
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.pixelSize: 11
            font.family: "JetBrains Mono, sans-serif"
        }

        // ---------- Body (fast höjd så att ön inte hoppar mellan vyerna) ----------
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.bodyHeight

            MonthView {
                visible: !root.weekMode
                x: 0
                width: root.monthW
                height: parent.height
            }

            Item {
                visible: root.weekMode
                width: root.weekPanelW + root.gap + root.dayPanelW
                height: parent.height

                WeekView {
                    x: 0
                    width: root.weekPanelW
                    height: parent.height
                }

                // Avdelare
                Rectangle {
                    x: root.weekPanelW + root.gap / 2
                    width: 1
                    height: parent.height
                    color: "#222222"
                }

                DayView {
                    x: root.weekPanelW + root.gap
                    width: root.dayPanelW
                    height: parent.height
                }
            }
        }
    }
}

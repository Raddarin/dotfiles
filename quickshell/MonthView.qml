import QtQuick
import QtQuick.Layouts

// Kompakt månadsvy (standardvyn): rutnät med färgade prickar + agenda för vald dag.
// Klicka på ett veckonummer (eller knappen "Vecka") för vecka + dag bredvid varandra.
Item {
    id: view

    readonly property real weekNoW: 24
    readonly property real cellW: (width - weekNoW) / 7
    readonly property real cellH: 40

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // ---------- Veckodagar ----------
        Row {
            Layout.preferredHeight: 18
            Item { width: view.weekNoW; height: 18 }
            Repeater {
                model: CalendarData.dayNames
                Text {
                    width: view.cellW
                    height: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: "#888888"
                    font.pixelSize: 11
                    font.family: "JetBrains Mono, sans-serif"
                }
            }
        }

        // ---------- Rutnät ----------
        Column {
            Layout.preferredHeight: CalendarData.weeks * view.cellH

            Repeater {
                model: CalendarData.weeks

                Row {
                    id: weekRow
                    property int rowIndex: index
                    property bool isSelectedWeek:
                        CalendarData.keyOf(CalendarData.weekStart(CalendarData.selectedDate))
                        === CalendarData.keyOf(CalendarData.cellDate(rowIndex * 7))

                    // Veckonummer (klick = vecka + dag bredvid varandra)
                    Item {
                        width: view.weekNoW
                        height: view.cellH

                        Rectangle {
                            anchors.centerIn: parent
                            width: 20
                            height: 24
                            radius: 6
                            color: weekMouse.containsMouse ? "#222222" : (weekRow.isSelectedWeek ? "#161616" : "transparent")
                        }
                        Text {
                            anchors.centerIn: parent
                            text: CalendarData.isoWeek(CalendarData.cellDate(weekRow.rowIndex * 7 + 3))
                            color: weekMouse.containsMouse ? "#ffffff" : "#777777"
                            font.pixelSize: 10
                            font.family: "JetBrains Mono, sans-serif"
                        }
                        MouseArea {
                            id: weekMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: CalendarData.selectWeek(CalendarData.cellDate(weekRow.rowIndex * 7))
                        }
                    }

                    // Dagar
                    Repeater {
                        model: 7

                        Item {
                            id: cell
                            width: view.cellW
                            height: view.cellH

                            property date d: CalendarData.cellDate(weekRow.rowIndex * 7 + index)
                            property bool inMonth: d.getMonth() === CalendarData.viewDate.getMonth()
                            property bool isToday: CalendarData.keyOf(d) === CalendarData.keyOf(new Date())
                            property bool isSelected: CalendarData.keyOf(d) === CalendarData.keyOf(CalendarData.selectedDate)
                            property var dayEvents: CalendarData.events[CalendarData.keyOf(d)] || []

                            Rectangle {
                                x: (parent.width - width) / 2
                                y: 1
                                width: 28
                                height: 28
                                radius: 14
                                color: cell.isSelected ? "#ffffff" : (cell.isToday ? "#333333" : "transparent")
                                border.color: cell.isToday && !cell.isSelected ? "#4285F4" : "transparent"
                                border.width: 1
                            }
                            Text {
                                x: (parent.width - width) / 2
                                y: 1 + (28 - height) / 2
                                text: cell.d.getDate()
                                color: cell.isSelected ? "#000000" : (cell.inMonth ? "#ffffff" : "#555555")
                                font.pixelSize: 13
                                font.bold: cell.isToday
                                font.family: "JetBrains Mono, sans-serif"
                            }

                            // Färgade prickar (max 4) – färgen kommer från Google
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: 32
                                spacing: 2
                                opacity: cell.inMonth ? 1.0 : 0.45
                                Repeater {
                                    model: Math.min(4, cell.dayEvents.length)
                                    Rectangle {
                                        width: 5
                                        height: 5
                                        radius: 2.5
                                        color: cell.dayEvents[index].color
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    CalendarData.selectDate(cell.d)
                                    if (!cell.inMonth) {
                                        CalendarData.viewDate = new Date(cell.d.getFullYear(), cell.d.getMonth(), 1)
                                        CalendarData.refresh()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---------- Avdelare ----------
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#333333"
        }

        // ---------- Agenda: rubrik ----------
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 18

            Text {
                text: CalendarData.fullDayNames[CalendarData.selectedDate.getDay()] + " "
                      + CalendarData.selectedDate.getDate() + " "
                      + CalendarData.monthNames[CalendarData.selectedDate.getMonth()].toLowerCase()
                color: "#ffffff"
                font.pixelSize: 13
                font.bold: true
                font.family: "JetBrains Mono, sans-serif"
            }
            Item { Layout.fillWidth: true }
            Text {
                text: CalendarData.status !== "" ? CalendarData.status
                      : (CalendarData.selEvents.length > 0 ? CalendarData.selEvents.length + " st" : "")
                color: "#888888"
                font.pixelSize: 11
                font.family: "JetBrains Mono, sans-serif"
            }
        }

        // ---------- Agenda: lista (scrollbar). Klick på ett event visar beskrivningen ----------
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: agendaCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: agendaCol
                width: view.width
                spacing: 5

                Text {
                    visible: CalendarData.selEvents.length === 0 && CalendarData.status === ""
                    text: "Inga händelser"
                    color: "#555555"
                    font.pixelSize: 12
                    font.family: "JetBrains Mono, sans-serif"
                }

                Repeater {
                    model: CalendarData.selEvents

                    Rectangle {
                        id: card
                        property bool open: false

                        width: agendaCol.width
                        height: cardCol.implicitHeight + 14
                        radius: 8
                        color: "#111111"

                        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Rectangle {
                            x: 6
                            y: 7
                            width: 4
                            height: parent.height - 14
                            radius: 2
                            color: modelData.color
                        }

                        Column {
                            id: cardCol
                            x: 18
                            y: 7
                            width: parent.width - 28
                            spacing: 1

                            Text {
                                width: cardCol.width
                                text: modelData.title
                                color: "#ffffff"
                                font.pixelSize: 13
                                font.bold: true
                                font.family: "sans-serif"
                                elide: Text.ElideRight
                            }
                            Text {
                                width: cardCol.width
                                text: modelData.timeLabel + (modelData.info !== "" ? "  ·  " + modelData.info : "")
                                color: "#cccccc"
                                font.pixelSize: 12
                                font.family: "sans-serif"
                                elide: Text.ElideRight
                            }
                            Text {
                                width: cardCol.width
                                text: modelData.cal + (modelData.location !== "" ? "  ·  " + modelData.location : "")
                                color: "#888888"
                                font.pixelSize: 11
                                font.family: "sans-serif"
                                elide: Text.ElideRight
                            }
                            Text {
                                width: cardCol.width
                                visible: card.open && modelData.desc.trim() !== ""
                                text: modelData.desc.trim()
                                color: "#999999"
                                font.pixelSize: 11
                                font.family: "sans-serif"
                                wrapMode: Text.WordWrap
                                maximumLineCount: 5
                                elide: Text.ElideRight
                                topPadding: 3
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: card.open = !card.open
                        }
                    }
                }
            }
        }
    }
}

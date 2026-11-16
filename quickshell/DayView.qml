import QtQuick
import QtQuick.Layouts

// Detaljerad dagsvy: tidslinje 00–24 + detaljpanel för valt event.
Item {
    id: view

    readonly property real hourH: 50
    property bool userScrolled: false

    function scrollToRelevant() {
        if (!visible) return
        var target = 8 * 60
        var timed = CalendarData.selEvents.filter(function (e) { return !e.allDay })
        var now = new Date()
        if (timed.length > 0) target = timed[0].startMin
        else if (CalendarData.keyOf(CalendarData.selectedDate) === CalendarData.keyOf(now)) target = now.getHours() * 60
        var y = target / 60 * hourH - hourH * 0.75
        dayFlick.contentY = Math.max(0, Math.min(y, dayFlick.contentHeight - dayFlick.height))
    }

    Connections {
        target: CalendarData
        function onDateSelected() {
            view.userScrolled = false
            Qt.callLater(view.scrollToRelevant)
        }
        function onDataLoaded() {
            if (!view.userScrolled) Qt.callLater(view.scrollToRelevant)
        }
    }
    onVisibleChanged: if (visible) {
        userScrolled = false
        Qt.callLater(scrollToRelevant)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // Rubrik
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 26
            spacing: 8

            Text {
                text: "‹"
                color: "#ffffff"
                font.pixelSize: 20
                font.family: "JetBrains Mono, sans-serif"
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: CalendarData.stepDay(-1)
                }
            }
            Text {
                text: "›"
                color: "#ffffff"
                font.pixelSize: 20
                font.family: "JetBrains Mono, sans-serif"
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: CalendarData.stepDay(1)
                }
            }
            Text {
                text: CalendarData.fullDayNames[CalendarData.selectedDate.getDay()] + " "
                      + CalendarData.selectedDate.getDate() + " "
                      + CalendarData.monthShort[CalendarData.selectedDate.getMonth()]
                color: "#ffffff"
                font.pixelSize: 14
                font.bold: true
                font.family: "JetBrains Mono, sans-serif"
            }
            Item { Layout.fillWidth: true }
            Text {
                text: CalendarData.status !== "" ? CalendarData.status
                      : (CalendarData.selEvents.length === 0 ? "Inga händelser" : CalendarData.selEvents.length + " st")
                color: "#777777"
                font.pixelSize: 11
                font.family: "JetBrains Mono, sans-serif"
            }
        }

        // Heldagsevent
        Flow {
            Layout.fillWidth: true
            visible: CalendarData.allDayEvents.length > 0
            spacing: 4

            Repeater {
                model: CalendarData.allDayEvents
                Rectangle {
                    height: 22
                    width: Math.min(allDayText.implicitWidth + 16, view.width)
                    radius: 4
                    color: modelData.color
                    border.color: CalendarData.focusUid === modelData.uid ? "#ffffff" : "transparent"
                    border.width: 2
                    Text {
                        id: allDayText
                        anchors.centerIn: parent
                        width: parent.width - 12
                        text: modelData.title + (modelData.info !== "" ? "  (" + modelData.info + ")" : "")
                        elide: Text.ElideRight
                        color: CalendarData.textOn(modelData.color)
                        font.pixelSize: 12
                        font.family: "sans-serif"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: CalendarData.focusUid = (CalendarData.focusUid === modelData.uid ? -1 : modelData.uid)
                    }
                }
            }
        }

        // Tidslinje
        Flickable {
            id: dayFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: 24 * view.hourH
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            onMovementStarted: view.userScrolled = true

            Item {
                id: timeline
                width: dayFlick.width
                height: 24 * view.hourH

                readonly property real areaX: 46
                readonly property real areaW: width - areaX - 4

                // Timlinjer + etiketter
                Repeater {
                    model: 24
                    Item {
                        y: index * view.hourH
                        width: timeline.width
                        height: 1
                        Text {
                            x: 0
                            y: index === 0 ? 0 : -7
                            width: 40
                            horizontalAlignment: Text.AlignRight
                            text: CalendarData.pad(index) + ":00"
                            color: "#777777"
                            font.pixelSize: 10
                            font.family: "JetBrains Mono, sans-serif"
                        }
                        Rectangle {
                            x: timeline.areaX
                            width: timeline.areaW
                            height: 1
                            color: "#222222"
                        }
                    }
                }

                // Event-block
                Repeater {
                    model: CalendarData.dayLayout

                    Rectangle {
                        id: blk
                        property var ev: modelData.ev
                        x: timeline.areaX + modelData.col * (timeline.areaW / modelData.cols)
                        y: ev.startMin / 60 * view.hourH + 1
                        width: timeline.areaW / modelData.cols - 2
                        height: Math.max(20, (ev.endMin - ev.startMin) / 60 * view.hourH - 2)
                        radius: 5
                        color: ev.color
                        clip: true
                        border.color: CalendarData.focusUid === ev.uid ? "#ffffff" : "#000000"
                        border.width: CalendarData.focusUid === ev.uid ? 2 : 1

                        Column {
                            x: 6
                            y: 3
                            width: blk.width - 10
                            spacing: 0
                            Text {
                                width: parent.width
                                text: blk.ev.title
                                elide: Text.ElideRight
                                color: CalendarData.textOn(blk.ev.color)
                                font.pixelSize: 12
                                font.bold: true
                                font.family: "sans-serif"
                            }
                            Text {
                                visible: blk.height >= 38
                                width: parent.width
                                text: blk.ev.timeLabel
                                elide: Text.ElideRight
                                color: CalendarData.textOn(blk.ev.color)
                                opacity: 0.85
                                font.pixelSize: 11
                                font.family: "sans-serif"
                            }
                            Text {
                                visible: blk.height >= 56 && blk.ev.location !== ""
                                width: parent.width
                                text: blk.ev.location
                                elide: Text.ElideRight
                                color: CalendarData.textOn(blk.ev.color)
                                opacity: 0.75
                                font.pixelSize: 10
                                font.family: "sans-serif"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: CalendarData.focusUid = (CalendarData.focusUid === blk.ev.uid ? -1 : blk.ev.uid)
                        }
                    }
                }

                // "Nu"-linje
                Item {
                    visible: CalendarData.keyOf(CalendarData.selectedDate) === CalendarData.keyOf(new Date())
                    y: CalendarData.nowMin / 60 * view.hourH
                    x: timeline.areaX - 4
                    width: timeline.areaW + 4
                    height: 1
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        x: -4
                        y: -3
                        color: "#ea4335"
                    }
                    Rectangle {
                        width: parent.width
                        height: 2
                        y: -1
                        color: "#ea4335"
                    }
                }
            }
        }

        // Detaljpanel för valt event
        Rectangle {
            Layout.fillWidth: true
            visible: CalendarData.focusEvent !== null
            Layout.preferredHeight: visible ? detailCol.implicitHeight + 16 : 0
            radius: 8
            color: "#121212"
            border.color: "#2a2a2a"
            border.width: 1

            Rectangle {
                x: 8
                y: 8
                width: 4
                height: parent.height - 16
                radius: 2
                color: CalendarData.focusEvent ? CalendarData.focusEvent.color : "transparent"
            }

            Column {
                id: detailCol
                x: 22
                y: 8
                width: parent.width - 32
                spacing: 2

                Text {
                    width: parent.width
                    text: CalendarData.focusEvent ? CalendarData.focusEvent.title : ""
                    color: "#ffffff"
                    font.pixelSize: 14
                    font.bold: true
                    font.family: "sans-serif"
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: CalendarData.focusEvent ? CalendarData.focusEvent.timeLabel
                          + (CalendarData.focusEvent.info !== "" ? "  ·  " + CalendarData.focusEvent.info : "") : ""
                    color: "#cccccc"
                    font.pixelSize: 12
                    font.family: "sans-serif"
                }
                Text {
                    width: parent.width
                    text: CalendarData.focusEvent ? CalendarData.focusEvent.cal
                          + (CalendarData.focusEvent.location !== "" ? "  ·  " + CalendarData.focusEvent.location : "") : ""
                    color: "#888888"
                    font.pixelSize: 11
                    font.family: "sans-serif"
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    visible: CalendarData.focusEvent !== null && CalendarData.focusEvent.desc.trim() !== ""
                    text: CalendarData.focusEvent ? CalendarData.focusEvent.desc.trim() : ""
                    color: "#999999"
                    font.pixelSize: 11
                    font.family: "sans-serif"
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    topPadding: 3
                }
            }
        }
    }
}

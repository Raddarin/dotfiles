import QtQuick

// Veckovy: 7 kolumner med tidslinje. Klicka på en dag/ett event för att visa den i dagsvyn.
Item {
    id: view

    readonly property real gutter: 36
    readonly property real colW: (width - gutter) / 7
    readonly property real hourH: 36
    readonly property int headH: 40

    property bool userScrolled: false
    property string lastWeekKey: ""

    // Veckans sju dagar
    readonly property var days: {
        var s = CalendarData.weekStart(CalendarData.selectedDate)
        var a = []
        for (var i = 0; i < 7; i++) a.push(new Date(s.getFullYear(), s.getMonth(), s.getDate() + i))
        return a
    }
    readonly property var dayEvents: days.map(function (d) {
        return CalendarData.events[CalendarData.keyOf(d)] || []
    })
    readonly property var dayLayouts: dayEvents.map(function (list) { return CalendarData.layoutDay(list) })
    readonly property var dayAllDay: dayEvents.map(function (list) {
        return list.filter(function (e) { return e.allDay })
    })
    readonly property int maxAllDay: {
        var m = 0
        for (var i = 0; i < dayAllDay.length; i++) m = Math.max(m, dayAllDay[i].length)
        return m
    }
    readonly property real allDayH: maxAllDay > 0 ? Math.min(maxAllDay, 2) * 15 + 3 : 0

    function scrollToRelevant() {
        if (!visible) return
        var target = -1
        for (var i = 0; i < dayEvents.length; i++) {
            for (var j = 0; j < dayEvents[i].length; j++) {
                var e = dayEvents[i][j]
                if (!e.allDay && (target < 0 || e.startMin < target)) target = e.startMin
            }
        }
        if (target < 0) {
            var now = new Date()
            var todayKey = CalendarData.keyOf(now)
            var inWeek = false
            for (var d = 0; d < days.length; d++)
                if (CalendarData.keyOf(days[d]) === todayKey) inWeek = true
            target = inWeek ? now.getHours() * 60 : 8 * 60
        }
        var y = target / 60 * hourH - hourH * 0.5
        weekFlick.contentY = Math.max(0, Math.min(y, weekFlick.contentHeight - weekFlick.height))
    }

    Connections {
        target: CalendarData
        function onDateSelected() {
            var k = CalendarData.keyOf(CalendarData.weekStart(CalendarData.selectedDate))
            if (k !== view.lastWeekKey) {
                view.lastWeekKey = k
                view.userScrolled = false
                Qt.callLater(view.scrollToRelevant)
            }
        }
        function onDataLoaded() {
            if (!view.userScrolled) Qt.callLater(view.scrollToRelevant)
        }
    }
    onVisibleChanged: if (visible) {
        userScrolled = false
        lastWeekKey = CalendarData.keyOf(CalendarData.weekStart(CalendarData.selectedDate))
        Qt.callLater(scrollToRelevant)
    }

    // ---------- Dagrubriker ----------
    Row {
        id: headRow
        x: view.gutter
        height: view.headH

        Repeater {
            model: 7
            Item {
                id: head
                width: view.colW
                height: view.headH
                property date d: view.days[index]
                property bool isToday: CalendarData.keyOf(d) === CalendarData.keyOf(new Date())
                property bool isSel: CalendarData.keyOf(d) === CalendarData.keyOf(CalendarData.selectedDate)

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 3
                    text: CalendarData.dayNames[index]
                    color: head.isSel ? "#ffffff" : "#888888"
                    font.pixelSize: 10
                    font.family: "JetBrains Mono, sans-serif"
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 16
                    width: 22
                    height: 22
                    radius: 11
                    color: head.isToday ? "#4285F4" : (head.isSel ? "#ffffff" : "transparent")
                    Text {
                        anchors.centerIn: parent
                        text: head.d.getDate()
                        color: head.isToday ? "#ffffff" : (head.isSel ? "#000000" : "#ffffff")
                        font.pixelSize: 12
                        font.bold: head.isToday || head.isSel
                        font.family: "JetBrains Mono, sans-serif"
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: CalendarData.selectDate(head.d)
                }
            }
        }
    }

    // ---------- Heldagsevent ----------
    Item {
        id: allDayStrip
        y: view.headH
        x: view.gutter
        width: parent.width - view.gutter
        height: view.allDayH
        visible: view.allDayH > 0

        Row {
            Repeater {
                model: 7
                Column {
                    id: allCol
                    width: view.colW
                    spacing: 1
                    property int colIndex: index
                    property var list: view.dayAllDay[colIndex]
                    property int shown: list.length > 2 ? 1 : list.length

                    Repeater {
                        model: allCol.shown
                        Rectangle {
                            property var ev: allCol.list[index]
                            width: view.colW - 2
                            height: 14
                            x: 1
                            radius: 3
                            color: ev.color
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                x: 3
                                width: parent.width - 6
                                text: parent.ev.title
                                elide: Text.ElideRight
                                color: CalendarData.textOn(parent.ev.color)
                                font.pixelSize: 9
                                font.family: "sans-serif"
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    CalendarData.selectDate(view.days[allCol.colIndex])
                                    CalendarData.focusUid = parent.ev.uid
                                }
                            }
                        }
                    }
                    Text {
                        visible: allCol.list.length > 2
                        height: 14
                        leftPadding: 3
                        text: "+" + (allCol.list.length - allCol.shown)
                        color: "#aaaaaa"
                        font.pixelSize: 9
                        font.family: "sans-serif"
                    }
                }
            }
        }
    }

    // ---------- Tidslinje ----------
    Flickable {
        id: weekFlick
        y: view.headH + view.allDayH
        width: parent.width
        height: parent.height - view.headH - view.allDayH
        contentWidth: width
        contentHeight: 24 * view.hourH
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        onMovementStarted: view.userScrolled = true

        Item {
            width: weekFlick.width
            height: 24 * view.hourH

            // Timlinjer + etiketter
            Repeater {
                model: 24
                Item {
                    y: index * view.hourH
                    width: parent.width
                    height: 1
                    Text {
                        x: 0
                        y: index === 0 ? 0 : -6
                        width: view.gutter - 4
                        horizontalAlignment: Text.AlignRight
                        text: CalendarData.pad(index)
                        color: "#666666"
                        font.pixelSize: 9
                        font.family: "JetBrains Mono, sans-serif"
                    }
                    Rectangle {
                        x: view.gutter
                        width: parent.width - view.gutter
                        height: 1
                        color: "#1f1f1f"
                    }
                }
            }

            // Dagkolumner
            Repeater {
                model: 7

                Item {
                    id: dayCol
                    property int dayIndex: index
                    property date d: view.days[index]
                    property bool isToday: CalendarData.keyOf(d) === CalendarData.keyOf(new Date())
                    property bool isSel: CalendarData.keyOf(d) === CalendarData.keyOf(CalendarData.selectedDate)

                    x: view.gutter + index * view.colW
                    width: view.colW
                    height: 24 * view.hourH

                    // Bakgrund (markerar vald dag) + klick på tom yta
                    Rectangle {
                        anchors.fill: parent
                        color: dayCol.isSel ? "#101010" : "transparent"
                        border.color: "#1a1a1a"
                        border.width: 0
                        Rectangle {
                            width: 1
                            height: parent.height
                            color: "#1d1d1d"
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: CalendarData.selectDate(dayCol.d)
                    }

                    // Event-block
                    Repeater {
                        model: view.dayLayouts[dayCol.dayIndex]

                        Rectangle {
                            id: blk
                            property var ev: modelData.ev
                            x: modelData.col * (dayCol.width / modelData.cols) + 1
                            y: ev.startMin / 60 * view.hourH + 1
                            width: dayCol.width / modelData.cols - 2
                            height: Math.max(14, (ev.endMin - ev.startMin) / 60 * view.hourH - 2)
                            radius: 3
                            color: ev.color
                            clip: true
                            border.color: CalendarData.focusUid === ev.uid ? "#ffffff" : "#000000"
                            border.width: CalendarData.focusUid === ev.uid ? 2 : 1

                            Text {
                                x: 3
                                y: 1
                                width: blk.width - 6
                                text: blk.ev.title
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                                color: CalendarData.textOn(blk.ev.color)
                                font.pixelSize: 9
                                font.bold: true
                                font.family: "sans-serif"
                            }
                            Text {
                                visible: blk.height >= 28
                                x: 3
                                y: 12
                                width: blk.width - 6
                                text: blk.ev.timeLabel
                                elide: Text.ElideRight
                                color: CalendarData.textOn(blk.ev.color)
                                opacity: 0.85
                                font.pixelSize: 8
                                font.family: "sans-serif"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    var same = CalendarData.focusUid === blk.ev.uid
                                        && CalendarData.keyOf(CalendarData.selectedDate) === CalendarData.keyOf(dayCol.d)
                                    CalendarData.selectDate(dayCol.d)
                                    CalendarData.focusUid = same ? -1 : blk.ev.uid
                                }
                            }
                        }
                    }

                    // "Nu"-linje
                    Rectangle {
                        visible: dayCol.isToday
                        y: CalendarData.nowMin / 60 * view.hourH - 1
                        width: parent.width
                        height: 2
                        color: "#ea4335"
                    }
                }
            }
        }
    }
}

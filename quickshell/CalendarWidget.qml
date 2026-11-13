import QtQuick
import QtQuick.Layouts
import Quickshell.Io

// Månadskalender + dagsagenda, data hämtas från Google Calendar via gcalcli.
Item {
    id: root

    // Sätts utifrån: true när widgeten är synlig/expanderad (triggar hämtning)
    property bool active: false

    property date viewDate: new Date()      // månaden som visas
    property date selectedDate: new Date()  // vald dag
    property var events: ({})               // "YYYY-MM-DD" -> [{start, end, title, allDay}]
    property string status: ""

    readonly property var monthNames: ["Januari", "Februari", "Mars", "April", "Maj", "Juni",
                                       "Juli", "Augusti", "September", "Oktober", "November", "December"]
    readonly property var dayNames: ["Mån", "Tis", "Ons", "Tors", "Fre", "Lör", "Sön"]

    implicitWidth: 300
    implicitHeight: col.implicitHeight

    // ---------- Hjälpfunktioner ----------
    function pad(n) { return n < 10 ? "0" + n : "" + n }
    function keyOf(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) }

    // Första cellen i rutnätet (måndag i veckan där månaden börjar)
    function gridStart() {
        var first = new Date(viewDate.getFullYear(), viewDate.getMonth(), 1)
        var offset = (first.getDay() + 6) % 7
        return new Date(first.getFullYear(), first.getMonth(), 1 - offset)
    }
    function cellDate(i) {
        var s = gridStart()
        return new Date(s.getFullYear(), s.getMonth(), s.getDate() + i)
    }

    function changeMonth(delta) {
        viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + delta, 1)
        refresh()
    }
    function goToday() {
        var now = new Date()
        viewDate = new Date(now.getFullYear(), now.getMonth(), 1)
        selectedDate = now
        refresh()
    }

    function refresh() {
        if (fetcher.running) return
        var from = keyOf(cellDate(0))
        var to = keyOf(cellDate(42))
        fetcher.command = ["gcalcli", "--nocolor", "agenda", "--tsv", "--nodeclined", from, to]
        status = "Hämtar…"
        fetcher.running = true
    }

    // gcalcli --tsv: start_date, start_time, end_date, end_time, title
    function parse(text) {
        var map = {}
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            if (!line || line.indexOf("start_date") === 0) continue
            var c = line.split("\t")
            if (c.length < 5) continue
            var k = c[0]
            if (!map[k]) map[k] = []
            map[k].push({
                start: c[1],
                end: c[3],
                title: c[4],
                allDay: c[1] === ""
            })
        }
        events = map
        status = ""
    }

    onActiveChanged: if (active) { goToday() }

    // Uppdatera var 10:e minut medan widgeten är öppen
    Timer {
        interval: 600000
        running: root.active
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: fetcher
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.length > 0) root.status = "gcalcli-fel (kör 'gcalcli init')"
        }
    }

    // ---------- UI ----------
    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        // Header: < Månad År >
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "‹"
                color: "#ffffff"
                font.pixelSize: 18
                font.family: "JetBrains Mono, sans-serif"
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: root.changeMonth(-1)
                }
            }
            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.monthNames[root.viewDate.getMonth()] + " " + root.viewDate.getFullYear()
                color: "#ffffff"
                font.pixelSize: 13
                font.bold: true
                font.family: "JetBrains Mono, sans-serif"
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.goToday()
                }
            }
            Text {
                text: "›"
                color: "#ffffff"
                font.pixelSize: 18
                font.family: "JetBrains Mono, sans-serif"
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: root.changeMonth(1)
                }
            }
        }

        // Veckodagar
        Row {
            Layout.fillWidth: true
            Repeater {
                model: root.dayNames
                Text {
                    width: col.width / 7
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: "#888888"
                    font.pixelSize: 10
                    font.family: "JetBrains Mono, sans-serif"
                }
            }
        }

        // Datumrutnät (6 veckor)
        Grid {
            Layout.fillWidth: true
            columns: 7
            Repeater {
                model: 42
                Item {
                    id: cell
                    width: col.width / 7
                    height: 30

                    property date d: root.cellDate(index)
                    property bool inMonth: d.getMonth() === root.viewDate.getMonth()
                    property bool isToday: root.keyOf(d) === root.keyOf(new Date())
                    property bool isSelected: root.keyOf(d) === root.keyOf(root.selectedDate)
                    property bool hasEvents: (root.events[root.keyOf(d)] || []).length > 0

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        radius: 13
                        color: cell.isSelected ? "#ffffff" : (cell.isToday ? "#333333" : "transparent")
                    }
                    Text {
                        anchors.centerIn: parent
                        text: cell.d.getDate()
                        color: cell.isSelected ? "#000000" : (cell.inMonth ? "#ffffff" : "#555555")
                        font.pixelSize: 12
                        font.bold: cell.isToday
                        font.family: "JetBrains Mono, sans-serif"
                    }
                    // Prick under dagar med event
                    Rectangle {
                        visible: cell.hasEvents
                        width: 4
                        height: 4
                        radius: 2
                        color: cell.isSelected ? "#000000" : "#4285F4"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 1
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.selectedDate = cell.d
                    }
                }
            }
        }

        // Avdelare
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#333333"
        }

        // Agenda för vald dag
        Text {
            text: root.selectedDate.getDate() + " " + root.monthNames[root.selectedDate.getMonth()].toLowerCase()
                  + (root.status ? "  · " + root.status : "")
            color: "#888888"
            font.pixelSize: 11
            font.family: "JetBrains Mono, sans-serif"
        }

        Column {
            Layout.fillWidth: true
            spacing: 4

            Text {
                visible: dayEvents.count === 0 && root.status === ""
                text: "Inga händelser"
                color: "#555555"
                font.pixelSize: 12
                font.family: "JetBrains Mono, sans-serif"
            }

            Repeater {
                id: dayEvents
                model: root.events[root.keyOf(root.selectedDate)] || []

                Row {
                    spacing: 8
                    Rectangle {
                        width: 3
                        height: 16
                        radius: 1
                        color: "#4285F4"
                    }
                    Text {
                        text: modelData.allDay ? "Heldag" : modelData.start + "–" + modelData.end
                        color: "#888888"
                        font.pixelSize: 12
                        font.family: "JetBrains Mono, sans-serif"
                    }
                    Text {
                        width: col.width - 90
                        text: modelData.title
                        elide: Text.ElideRight
                        color: "#ffffff"
                        font.pixelSize: 12
                        font.family: "JetBrains Mono, sans-serif"
                    }
                }
            }
        }

        Item { height: 4 }
    }
}

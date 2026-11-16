pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Delat tillstånd + datahämtning för kalendern.
// Både klock-ön och den utfällda baren använder samma instans, så de visar alltid samma kalender.
Singleton {
    id: root

    // ---------- Delat tillstånd ----------
    property bool open: false                 // är kalendern uppfälld?
    property string viewMode: "month"         // "month" | "week" (vecka + dag bredvid varandra)
    property date viewDate: new Date()        // månaden som hämtas/visas
    property date selectedDate: new Date()    // vald dag
    property var events: ({})                 // "YYYY-MM-DD" -> [event]
    property string status: ""
    property string errorText: ""
    property int focusUid: -1                 // valt event (visas i detaljpanelen)
    property int nowMin: 0                    // minuter sedan midnatt (röd "nu"-linje)

    property int users: 0
    property double lastClosed: 0
    property double lastFetch: 0
    property string lastGridKey: ""
    property bool pendingRefresh: false

    signal dateSelected()
    signal dataLoaded()

    readonly property string scriptPath: Quickshell.shellPath("scripts/gcal-events.sh")

    readonly property var monthNames: ["Januari", "Februari", "Mars", "April", "Maj", "Juni",
                                       "Juli", "Augusti", "September", "Oktober", "November", "December"]
    readonly property var monthShort: ["jan", "feb", "mar", "apr", "maj", "jun",
                                       "jul", "aug", "sep", "okt", "nov", "dec"]
    readonly property var dayNames: ["Mån", "Tis", "Ons", "Tors", "Fre", "Lör", "Sön"]
    readonly property var fullDayNames: ["Söndag", "Måndag", "Tisdag", "Onsdag", "Torsdag", "Fredag", "Lördag"]

    // Antal veckor som behövs för att visa månaden (4–6)
    readonly property int weeks: {
        var first = new Date(viewDate.getFullYear(), viewDate.getMonth(), 1)
        var offset = (first.getDay() + 6) % 7
        var days = new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 0).getDate()
        return Math.ceil((offset + days) / 7)
    }

    // Härledd data för vald dag
    readonly property var selEvents: events[keyOf(selectedDate)] || []
    readonly property var allDayEvents: selEvents.filter(function (e) { return e.allDay })
    readonly property var dayLayout: layoutDay(selEvents)
    readonly property var focusEvent: findFocus()

    // ---------- Hjälpfunktioner ----------
    function pad(n) { return n < 10 ? "0" + n : "" + n }
    function keyOf(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) }
    function hm(d) { return pad(d.getHours()) + ":" + pad(d.getMinutes()) }
    function parseDateOnly(s) {
        var p = s.split("-")
        return new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))
    }
    function fmtDur(ms) {
        var m = Math.round(ms / 60000)
        var h = Math.floor(m / 60)
        var mm = m % 60
        if (h > 0 && mm > 0) return h + " h " + mm + " min"
        if (h > 0) return h + " h"
        return mm + " min"
    }

    // Svart eller vit text beroende på bakgrundsfärgens ljushet
    function textOn(hex) {
        if (!hex || hex.length < 7) return "#ffffff"
        var r = parseInt(hex.substr(1, 2), 16)
        var g = parseInt(hex.substr(3, 2), 16)
        var b = parseInt(hex.substr(5, 2), 16)
        return (0.299 * r + 0.587 * g + 0.114 * b) > 165 ? "#000000" : "#ffffff"
    }

    function isoWeek(d) {
        var t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        var dayNum = t.getUTCDay() || 7
        t.setUTCDate(t.getUTCDate() + 4 - dayNum)
        var yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1))
        return Math.ceil((((t - yearStart) / 86400000) + 1) / 7)
    }

    function weekStart(d) {
        var off = (d.getDay() + 6) % 7
        return new Date(d.getFullYear(), d.getMonth(), d.getDate() - off)
    }

    function gridStart() {
        var first = new Date(viewDate.getFullYear(), viewDate.getMonth(), 1)
        var offset = (first.getDay() + 6) % 7
        return new Date(first.getFullYear(), first.getMonth(), 1 - offset)
    }
    function cellDate(i) {
        var s = gridStart()
        return new Date(s.getFullYear(), s.getMonth(), s.getDate() + i)
    }

    function titleText() {
        if (viewMode === "month")
            return monthNames[viewDate.getMonth()] + " " + viewDate.getFullYear()
        var s = weekStart(selectedDate)
        var e = new Date(s.getFullYear(), s.getMonth(), s.getDate() + 6)
        var first = s.getDate() + (s.getMonth() !== e.getMonth() ? " " + monthShort[s.getMonth()] : "")
        return "Vecka " + isoWeek(s) + " · " + first + "–" + e.getDate() + " " + monthShort[e.getMonth()] + " " + e.getFullYear()
    }

    function findFocus() {
        for (var i = 0; i < selEvents.length; i++)
            if (selEvents[i].uid === focusUid) return selEvents[i]
        return null
    }

    // ---------- Navigering ----------
    function changeMonth(delta) {
        viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + delta, 1)
        refresh()
    }

    function selectDate(d) {
        var day = new Date(d.getFullYear(), d.getMonth(), d.getDate())
        selectedDate = day
        if (day < cellDate(0) || day > cellDate(weeks * 7 - 1)) {
            viewDate = new Date(day.getFullYear(), day.getMonth(), 1)
            refresh()
        }
        focusUid = -1
        dateSelected()
    }

    // Klick på en dag i månadsvyn: visa veckan + dagen bredvid varandra
    function openWeek(d) {
        viewMode = "week"
        selectDate(d)
    }

    // Klick på ett veckonummer: välj hela veckan (idag om den ingår, annars måndagen)
    function selectWeek(start) {
        var now = new Date()
        var today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        var end = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 6)
        viewMode = "week"
        selectDate((today >= start && today <= end) ? today : start)
    }

    function setMode(m) {
        viewMode = m
        selectDate(selectedDate)
    }

    // ‹ › i headern: månad i månadsvyn, vecka i veckovyn
    function step(delta) {
        if (viewMode === "month") changeMonth(delta)
        else selectDate(new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate() + 7 * delta))
    }

    // ‹ › i dagspanelen
    function stepDay(delta) {
        selectDate(new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate() + delta))
    }

    function goToday() {
        var now = new Date()
        viewDate = new Date(now.getFullYear(), now.getMonth(), 1)
        selectDate(now)
        refresh()
    }

    // ---------- Livscykel: widgetar som visar kalendern anmäler sig här ----------
    function acquire() {
        users++
        if (users !== 1) return

        // Byte mellan lilla och stora baren (widgeten återskapas direkt) behåller tillståndet.
        // Varje "riktig" öppning börjar i den kompakta månadsvyn på dagens datum.
        var quickSwitch = (Date.now() - lastClosed) < 1500
        if (!quickSwitch || lastFetch === 0) {
            var now = new Date()
            viewMode = "month"
            viewDate = new Date(now.getFullYear(), now.getMonth(), 1)
            selectedDate = new Date(now.getFullYear(), now.getMonth(), now.getDate())
            focusUid = -1
            dateSelected()
        }
        var stale = (Date.now() - lastFetch) > 120000
        if (lastFetch === 0 || stale || keyOf(cellDate(0)) !== lastGridKey) refresh()
    }
    function release() {
        users = Math.max(0, users - 1)
        if (users === 0) lastClosed = Date.now()
    }

    // ---------- Layout av överlappande events (tidslinjer) ----------
    function layoutDay(list) {
        var items = []
        for (var i = 0; i < list.length; i++) {
            var ev = list[i]
            if (ev.allDay) continue
            items.push({ ev: ev, s: ev.startMin, e: Math.max(ev.endMin, ev.startMin + 30), col: 0, cols: 1 })
        }
        items.sort(function (a, b) { return a.s - b.s || b.e - a.e })

        var clusters = []
        var cur = null
        var curEnd = -1
        for (var j = 0; j < items.length; j++) {
            var it = items[j]
            if (!cur || it.s >= curEnd) {
                cur = []
                clusters.push(cur)
                curEnd = it.e
            } else {
                curEnd = Math.max(curEnd, it.e)
            }
            cur.push(it)
        }

        for (var c = 0; c < clusters.length; c++) {
            var cl = clusters[c]
            var colEnds = []
            for (var k = 0; k < cl.length; k++) {
                var x = 0
                while (x < colEnds.length && colEnds[x] > cl[k].s) x++
                colEnds[x] = cl[k].e
                cl[k].col = x
            }
            for (var m = 0; m < cl.length; m++) cl[m].cols = colEnds.length
        }
        return items
    }

    // ---------- Datahämtning ----------
    function refresh() {
        if (fetcher.running) { pendingRefresh = true; return }
        errorText = ""
        status = "Hämtar…"
        lastGridKey = keyOf(cellDate(0))
        fetcher.command = ["bash", scriptPath, keyOf(cellDate(0)), keyOf(cellDate(weeks * 7))]
        fetcher.running = true
    }

    // Fördelar events på dagar (flerdagarsevent delas upp)
    function parse(text) {
        var data
        try {
            data = JSON.parse(text)
        } catch (e) {
            status = ""
            if (errorText === "") errorText = "Kunde inte läsa kalenderdata"
            return
        }

        var gridFirst = cellDate(0)
        var gridLast = cellDate(weeks * 7 - 1)
        var map = {}
        var uid = 0

        for (var i = 0; i < data.length; i++) {
            var ev = data[i]
            var s, e
            if (ev.allDay) {
                s = parseDateOnly(ev.start)
                e = parseDateOnly(ev.end)          // exklusivt
            } else {
                s = new Date(ev.start)
                e = new Date(ev.end)
            }

            var lastMs = Math.max(s.getTime(), e.getTime() - 1)
            var lastD = new Date(lastMs)
            var firstDay = new Date(s.getFullYear(), s.getMonth(), s.getDate())
            var lastDay = new Date(lastD.getFullYear(), lastD.getMonth(), lastD.getDate())
            var dayCount = Math.round((lastDay.getTime() - firstDay.getTime()) / 86400000) + 1

            var from = firstDay > gridFirst ? firstDay : gridFirst
            var to = lastDay < gridLast ? lastDay : gridLast

            for (var dd = from; dd <= to; dd = new Date(dd.getFullYear(), dd.getMonth(), dd.getDate() + 1)) {
                var idx = Math.round((dd.getTime() - firstDay.getTime()) / 86400000)
                var isFirst = idx === 0
                var isLast = dd.getTime() === lastDay.getTime()
                var fullDay = ev.allDay || (!isFirst && !isLast)

                var sMin = 0
                var eMin = 1440
                var timeLabel = "Heldag"
                if (!fullDay) {
                    sMin = isFirst ? s.getHours() * 60 + s.getMinutes() : 0
                    eMin = isLast ? ((e.getHours() === 0 && e.getMinutes() === 0) ? 1440
                                     : e.getHours() * 60 + e.getMinutes()) : 1440
                    if (eMin <= sMin) eMin = sMin + 30
                    timeLabel = pad(Math.floor(sMin / 60)) + ":" + pad(sMin % 60) + "–"
                                + pad(Math.floor(eMin / 60) % 24) + ":" + pad(eMin % 60)
                }

                var info = ""
                if (dayCount > 1) info = "dag " + (idx + 1) + "/" + dayCount
                else if (!ev.allDay) info = fmtDur(e.getTime() - s.getTime())

                var k = keyOf(dd)
                if (!map[k]) map[k] = []
                map[k].push({
                    uid: uid++,
                    title: ev.title,
                    color: ev.color,
                    cal: ev.cal,
                    location: ev.location,
                    desc: ev.desc,
                    allDay: fullDay,
                    timeLabel: timeLabel,
                    info: info,
                    startMin: sMin,
                    endMin: eMin,
                    sortKey: fullDay ? -1 : sMin
                })
            }
        }

        for (var key in map) {
            map[key].sort(function (a, b) {
                if (a.sortKey !== b.sortKey) return a.sortKey - b.sortKey
                return a.title < b.title ? -1 : 1
            })
        }

        events = map
        focusUid = -1
        status = ""
        lastFetch = Date.now()
        dataLoaded()
    }

    // Uppdatera var 10:e minut medan någon visar kalendern
    Timer {
        interval: 600000
        running: root.users > 0
        repeat: true
        onTriggered: root.refresh()
    }

    // Röd "nu"-linje
    Timer {
        interval: 30000
        running: root.users > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var n = new Date()
            root.nowMin = n.getHours() * 60 + n.getMinutes()
        }
    }

    Process {
        id: fetcher
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
        stderr: StdioCollector {
            onStreamFinished: {
                var t = text.trim()
                if (t.length > 0) {
                    root.errorText = t
                    root.status = ""
                }
            }
        }
        onRunningChanged: {
            if (!running && root.pendingRefresh) {
                root.pendingRefresh = false
                root.refresh()
            }
        }
    }
}

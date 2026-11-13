import QtQuick
import Quickshell
import Quickshell.Io

// Motsvarighet till waybars modules-right, med data för tooltips.
Row {
    id: root
    spacing: 14

    // ---------- Tooltip-tillstånd ----------
    // "" | "net" | "bt" | "battery" | "cpu"
    property string tip: ""
    // Sätts av SystemTooltip när musen är över tooltip-ytan
    property bool tooltipHovered: false

    function enter(name) { leaveTimer.stop(); tip = name }
    function leave() { leaveTimer.restart() }

    onTipChanged: if (tip !== "net") lastNet = null

    Timer {
        id: leaveTimer
        interval: 250
        onTriggered: if (!root.tooltipHovered) root.tip = ""
    }

    // ---------- Data ----------
    property int volume: 0
    property bool muted: false

    property string netType: "none"      // "wifi" | "ethernet" | "none"
    property string netDev: ""
    property string ssid: ""
    property int wifiSignal: 0
    property string linkRate: ""
    property real rxRate: 0              // bytes/s
    property real txRate: 0
    property var lastNet: null

    property bool btOn: false
    property var btDevices: []

    property bool hasBattery: false
    property int batteryPercent: 0
    property string batteryStatus: ""
    property bool charging: false
    property real batteryHours: -1       // -1 = okänt

    property string ramUsed: ""
    property int cpuUsage: 0
    property var coreUsage: []
    property var lastCpu: null

    // ---------- Hjälpfunktioner ----------
    function cp(n) { return String.fromCodePoint(n) }

    function fmtRate(bytesPerSec) {
        var bits = bytesPerSec * 8
        if (bits >= 1e6) return (bits / 1e6).toFixed(1) + " Mb/s"
        if (bits >= 1e3) return Math.round(bits / 1e3) + " kb/s"
        return Math.round(bits) + " b/s"
    }

    function fmtDuration(hours) {
        var m = Math.round(hours * 60)
        var h = Math.floor(m / 60)
        var mm = m % 60
        return h > 0 ? h + " h " + mm + " min" : mm + " min"
    }

    // ---------- Ikoner ----------
    function volumeIcon() {
        if (muted) return cp(0xF075F)
        var icons = [0xF057F, 0xF0580, 0xF0580, 0xF057E, 0xF057E, 0xF057E, 0xF057E]
        var idx = Math.min(6, Math.floor(volume / (100 / 7)))
        return cp(icons[idx])
    }
    function networkIcon() {
        if (netType === "wifi") return cp(0xF1EB)
        if (netType === "ethernet") return cp(0xF0200)
        return cp(0xF05AA)
    }
    function bluetoothIcon() {
        return btOn ? cp(0xF00AF) : cp(0xF00B2)
    }
    function batteryIcon() {
        var normal = [0xF008E, 0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E,
                      0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079]
        var chg = [0xF089F, 0xF089C, 0xF0086, 0xF0087, 0xF0088, 0xF089D,
                   0xF0089, 0xF089E, 0xF008A, 0xF008B, 0xF0085]
        var idx = Math.max(0, Math.min(10, Math.round(batteryPercent / 10)))
        return cp((charging ? chg : normal)[idx])
    }

    // ---------- Hjälpkomponenter ----------
    component Module: Text {
        color: "#ffffff"
        font.pixelSize: 16
        font.family: "JetBrainsMono Nerd Font"   // byt om din Nerd Font heter något annat
        verticalAlignment: Text.AlignVCenter
    }

    // Kör ett kommando med jämna mellanrum och skickar ut stdout.
    // visible: false så att Row inte räknar in den i spacing.
    component Poller: Item {
        id: p
        visible: false
        property var command: []
        property int interval: 1000
        property bool active: true
        signal output(string text)

        function refresh() { if (!proc.running) proc.running = true }

        Process {
            id: proc
            command: p.command
            stdout: StdioCollector {
                onStreamFinished: p.output(text)
            }
        }
        Timer {
            interval: p.interval
            running: p.active
            repeat: true
            triggeredOnStart: true
            onTriggered: p.refresh()
        }
    }

    // ---------- Datakällor ----------
    Poller {
        id: audioPoll
        interval: 1000
        command: ["sh", "-c", "pactl get-sink-mute @DEFAULT_SINK@; pactl get-sink-volume @DEFAULT_SINK@"]
        onOutput: (t) => {
            root.muted = /Mute: yes/.test(t)
            var m = t.match(/(\d+)%/)
            if (m) root.volume = parseInt(m[1])
        }
    }

    // Nätverkstyp + aktivt gränssnitt
    Poller {
        interval: 3000
        command: ["sh", "-c", "nmcli -t -f DEVICE,TYPE,STATE device"]
        onOutput: (t) => {
            var type = "none"
            var dev = ""
            var lines = t.split("\n")
            for (var i = 0; i < lines.length; i++) {
                var f = lines[i].split(":")
                if (f.length < 3 || f[2].indexOf("connected") !== 0) continue
                if (f[1] === "ethernet") { type = "ethernet"; dev = f[0]; break }
                if (f[1] === "wifi" && type === "none") { type = "wifi"; dev = f[0] }
            }
            root.netType = type
            root.netDev = dev
        }
    }

    // SSID, signal och länkhastighet (hämtas bara medan tooltipen visas)
    Poller {
        interval: 3000
        active: root.tip === "net" && root.netType === "wifi"
        command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL,RATE dev wifi list --rescan no"]
        onOutput: (t) => {
            var m = t.match(/^yes:(.*):(\d+):([^:]*)$/m)
            if (m) {
                root.ssid = m[1].replace(/\\:/g, ":")
                root.wifiSignal = parseInt(m[2])
                root.linkRate = m[3]
            }
        }
    }

    // Aktuell upp-/nedladdningshastighet (bara medan tooltipen visas)
    Poller {
        interval: 1000
        active: root.tip === "net" && root.netDev !== ""
        command: ["sh", "-c", "cat /proc/net/dev"]
        onOutput: (t) => {
            var lines = t.split("\n")
            for (var i = 0; i < lines.length; i++) {
                var l = lines[i].trim()
                if (l.indexOf(root.netDev + ":") !== 0) continue
                var f = l.substring(l.indexOf(":") + 1).trim().split(/\s+/).map(Number)
                var now = Date.now()
                if (root.lastNet && now > root.lastNet.t) {
                    var dt = (now - root.lastNet.t) / 1000
                    root.rxRate = Math.max(0, (f[0] - root.lastNet.rx) / dt)
                    root.txRate = Math.max(0, (f[8] - root.lastNet.tx) / dt)
                }
                root.lastNet = { "rx": f[0], "tx": f[8], "t": now }
                break
            }
        }
    }

    // Bluetooth: av/på + anslutna enheter
    Poller {
        interval: 5000
        command: ["sh", "-c",
            "bluetoothctl show 2>/dev/null | awk '/Powered:/ {print \"POWER\", $2}'; bluetoothctl devices Connected 2>/dev/null"]
        onOutput: (t) => {
            var on = false
            var devs = []
            var lines = t.split("\n")
            for (var i = 0; i < lines.length; i++) {
                if (lines[i].indexOf("POWER yes") === 0) { on = true; continue }
                var m = lines[i].match(/^Device\s+\S+\s+(.*)$/)
                if (m) devs.push(m[1])
            }
            root.btOn = on
            root.btDevices = devs
        }
    }

    // Batteri: nivå, status och tid kvar/till full (beräknad från sysfs)
    Poller {
        interval: 10000
        command: ["sh", "-c",
            'for b in /sys/class/power_supply/BAT*; do [ -r "$b/capacity" ] || continue; ' +
            'now=$(cat $b/energy_now 2>/dev/null || cat $b/charge_now 2>/dev/null); ' +
            'full=$(cat $b/energy_full 2>/dev/null || cat $b/charge_full 2>/dev/null); ' +
            'rate=$(cat $b/power_now 2>/dev/null || cat $b/current_now 2>/dev/null); ' +
            'echo "$(cat $b/capacity)|$(cat $b/status)|$now|$full|$rate"; break; done']
        onOutput: (t) => {
            var line = t.trim().split("\n")[0]
            if (!line) { root.hasBattery = false; return }
            var p = line.split("|")
            root.hasBattery = true
            root.batteryPercent = parseInt(p[0])
            root.batteryStatus = p[1]
            root.charging = p[1] === "Charging"
            var now = Number(p[2]), full = Number(p[3]), rate = Number(p[4])
            var hours = -1
            if (rate > 0) {
                if (root.charging) hours = Math.max(0, (full - now) / rate)
                else if (p[1] === "Discharging") hours = now / rate
            }
            root.batteryHours = hours
        }
    }

    Poller {
        interval: 5000
        command: ["sh", "-c", "free -h | awk '/Mem:/ {print $3}'"]
        onOutput: (t) => { root.ramUsed = t.trim() }
    }

    // CPU: totalt + per kärna
    Poller {
        interval: 1000
        command: ["sh", "-c", "grep '^cpu' /proc/stat"]
        onOutput: (t) => {
            var lines = t.trim().split("\n")
            var prev = root.lastCpu || []
            var cur = []
            var cores = []
            for (var i = 0; i < lines.length; i++) {
                var p = lines[i].trim().split(/\s+/).slice(1, 9).map(Number)
                var idle = p[3] + p[4]
                var total = p.reduce(function (a, b) { return a + b }, 0)
                cur.push({ "total": total, "idle": idle })
                if (prev[i]) {
                    var dt = total - prev[i].total
                    var di = idle - prev[i].idle
                    var u = dt > 0 ? Math.round(100 * (dt - di) / dt) : 0
                    if (i === 0) root.cpuUsage = u
                    else cores.push(u)
                }
            }
            root.lastCpu = cur
            if (prev.length) root.coreUsage = cores
        }
    }

    // ---------- UI ----------

    // Ljud: scrolla = volym, klick = mute
    Module {
        text: root.muted ? root.volumeIcon() : root.volume + "% " + root.volumeIcon()
        color: root.muted ? "#888888" : "#ffffff"
        MouseArea {
            anchors.fill: parent
            onClicked: {
                Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"])
                audioPoll.refresh()
            }
            onWheel: (wheel) => {
                Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@",
                                         wheel.angleDelta.y > 0 ? "+1%" : "-1%"])
                audioPoll.refresh()
            }
        }
    }

    // Nätverk (tooltip: nätnamn + hastighet) — klick = nmtui
    Module {
        text: root.networkIcon()
        color: root.netType === "none" ? "#888888" : "#ffffff"
        HoverArea {
            onEntered: root.enter("net")
            onExited: root.leave()
            onClicked: Quickshell.execDetached(["alacritty", "-e", "bash", "-ic", "nmtui"])
        }
    }

    // Bluetooth (tooltip: anslutna enheter) — klick = bluetuith
    Module {
        text: root.bluetoothIcon()
        color: root.btOn ? "#ffffff" : "#888888"
        HoverArea {
            onEntered: root.enter("bt")
            onExited: root.leave()
            onClicked: Quickshell.execDetached(["alacritty", "-e", "bash", "-ic", "bluetuith"])
        }
    }

    // Batteri (tooltip: tid till full/tom) — göms om batteri saknas
    Module {
        visible: root.hasBattery
        text: root.batteryIcon()
        color: (!root.charging && root.batteryPercent <= 10) ? "#ff5555" : "#ffffff"
        HoverArea {
            onEntered: root.enter("battery")
            onExited: root.leave()
        }
    }

    // RAM — klick = btop
    Module {
        text: root.cp(0xEFC5) + " " + root.ramUsed
        MouseArea {
            anchors.fill: parent
            onClicked: Quickshell.execDetached(["kitty", "-e", "btop"])
        }
    }

    // CPU (tooltip: användning per kärna)
    Module {
        text: root.cp(0xF2DB) + " " + String(root.cpuUsage).padStart(2, " ") + "%"
        HoverArea {
            onEntered: root.enter("cpu")
            onExited: root.leave()
        }
    }
}

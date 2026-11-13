pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // Formaterad tid
    readonly property string hoursMinutes: Qt.formatDateTime(clock.date, "hh:mm")
    readonly property string seconds: Qt.formatDateTime(clock.date, "ss")

    // SystemClock uppdateras automatiskt varje sekund
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}

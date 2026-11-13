import QtQuick

// Hover-yta som är lite större än ikonen den ligger på,
// så musen kan ta sig ner till tooltipen utan att tappa hovern.
MouseArea {
    hoverEnabled: true
    anchors.fill: parent
    anchors.topMargin: -9
    anchors.bottomMargin: -9
    anchors.leftMargin: -5
    anchors.rightMargin: -5
}

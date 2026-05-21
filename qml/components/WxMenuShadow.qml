import QtQuick
import Qt5Compat.GraphicalEffects

DropShadow {
    anchors.fill: parent.shadowTarget
    source: parent.shadowTarget
    transparentBorder: true
    horizontalOffset: 0
    verticalOffset: 4
    radius: 12
    color: Qt.rgba(0, 0, 0, 0.08)
}

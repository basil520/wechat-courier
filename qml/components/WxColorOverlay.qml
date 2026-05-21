import QtQuick
import Qt5Compat.GraphicalEffects
import "../theme"

ColorOverlay {
    anchors.fill: parent
    source: parent.sourceImage
    color: parent.overlayColor

    Behavior on color {
        ColorAnimation {
            duration: WxTheme.animNormal
        }
    }
}

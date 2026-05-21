import QtQuick
import "../theme"

Rectangle {
    id: root

    property color fillColor: WxTheme.clPanelFill
    property color borderColor: WxTheme.clSurfaceBorder
    property color focusColor: WxTheme.clFocusRing
    property bool focused: false
    property bool highlightEnabled: true

    color: fillColor
    radius: WxTheme.radiusMedium
    border.width: 1
    border.color: borderColor

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Math.max(1, root.radius / 2)
        anchors.rightMargin: Math.max(1, root.radius / 2)
        height: 1
        color: WxTheme.clSurfaceHighlight
        visible: root.highlightEnabled
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: root.radius + 2
        color: "transparent"
        border.width: 2
        border.color: root.focusColor
        opacity: root.focused ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: WxTheme.animNormal }
        }
    }

    Behavior on color {
        ColorAnimation { duration: WxTheme.animNormal }
    }

    Behavior on border.color {
        ColorAnimation { duration: WxTheme.animNormal }
    }
}

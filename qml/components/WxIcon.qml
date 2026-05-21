import QtQuick
import "../theme"

Item {
    id: root

    property string iconSource: ""
    property color iconColor: "transparent"       // "transparent" means keep original SVG colors
    property color hoverColor: "transparent"      // Hover tint (only active if iconColor is set)
    property real iconSize: 20
    property bool hoverScale: true
    property bool active: false

    implicitWidth: iconSize
    implicitHeight: iconSize

    // Hover detection
    property bool hovered: mouseArea.containsMouse

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton // Let mouse events pass through to parents!
    }

    Item {
        id: container
        anchors.fill: parent
        scale: root.hoverScale && (root.hovered || root.active) ? 1.08 : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: WxTheme.animNormal
                easing.type: Easing.OutQuad
            }
        }

        Image {
            id: svgImage
            anchors.fill: parent
            source: root.iconSource
            sourceSize.width: root.iconSize
            sourceSize.height: root.iconSize
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: root.iconColor === "transparent" || root.iconColor.toString() === "#00000000" || overlayLoader.status !== Loader.Ready
        }

        Loader {
            id: overlayLoader
            anchors.fill: svgImage
            visible: root.iconColor !== "transparent" && root.iconColor.toString() !== "#00000000"

            // Custom properties passed down to the loaded ColorOverlay item
            property var sourceImage: svgImage
            property color overlayColor: {
                if (root.hovered && root.hoverColor !== "transparent" && root.hoverColor.toString() !== "#00000000") {
                    return root.hoverColor
                }
                return root.iconColor
            }

            source: "WxColorOverlay.qml"
        }
    }
}

import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root

    property bool checked: false
    property string text: ""

    signal toggled(bool checked)

    implicitWidth: mainLayout.implicitWidth
    implicitHeight: mainLayout.implicitHeight

    // Tactile scale on hover for a premium feeling
    scale: hoverArea.containsMouse ? 1.03 : 1.0
    Behavior on scale {
        NumberAnimation { duration: WxTheme.animNormal; easing.type: Easing.OutQuad }
    }

    RowLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: WxTheme.spSmall

        // 轨道
        Rectangle {
            id: track
            Layout.preferredWidth: 36
            Layout.preferredHeight: 20
            radius: 10
            color: root.checked ? WxTheme.clPrimary : WxTheme.clSwitchTrackOff

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            // 滑块
            Rectangle {
                id: thumb
                width: 16
                height: 16
                radius: 8
                color: WxTheme.clSwitchThumb
                anchors.verticalCenter: parent.verticalCenter
                x: root.checked ? parent.width - width - 2 : 2

                // Springy curve for satisfying toggle transition
                Behavior on x {
                    NumberAnimation { duration: 180; easing.type: Easing.OutBack }
                }

                layer.enabled: true
                layer.effect: ShaderEffectSource {
                    // 简单阴影通过边框模拟，避免复杂 shader
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(0, 0, 0, 0.08)
                }
            }
        }

        // 标签
        Text {
            text: root.text
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeSmall
            color: WxTheme.clTextPrimary
            verticalAlignment: Text.AlignVCenter
            visible: root.text !== ""
            Layout.fillWidth: true
        }
    }

    // Single MouseArea overlaying the entire switch control for click/hover stability
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.toggled(!root.checked)
        }
    }
}



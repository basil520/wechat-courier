import QtQuick
import QtQuick.Layouts
import "../theme"

RowLayout {
    id: root

    property bool checked: false
    property string text: ""

    signal toggled(bool checked)

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

            Behavior on x {
                NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
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

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.checked = !root.checked
                root.toggled(root.checked)
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
    }
}

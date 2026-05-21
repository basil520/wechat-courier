import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property int value: 0
    property int from: 0
    property int to: 100
    property int stepSize: 1

    signal valueModified(int newValue)

    implicitWidth: 72
    implicitHeight: WxTheme.controlHeight
    radius: WxTheme.radiusSmall
    color: WxTheme.clBgInput
    border.width: activeFocus ? 1 : 0
    border.color: WxTheme.clBorderFocus

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // 减号按钮
        Rectangle {
            Layout.preferredWidth: 20
            Layout.fillHeight: true
            color: minusArea.containsMouse ? WxTheme.clBgHover : "transparent"
            radius: WxTheme.radiusSmall

            Behavior on color {
                ColorAnimation { duration: WxTheme.animFast }
            }

            Text {
                anchors.centerIn: parent
                text: "−"
                font.pixelSize: WxTheme.fontSizeNormal
                color: WxTheme.clTextPrimary
            }

            MouseArea {
                id: minusArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (root.value > root.from) {
                        root.value = Math.max(root.from, root.value - root.stepSize)
                        root.valueModified(root.value)
                    }
                }
            }
        }

        // 分隔线
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            color: WxTheme.clDivider
        }

        // 数字显示
        Text {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: root.value
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeSmall
            color: WxTheme.clTextPrimary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        // 分隔线
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            color: WxTheme.clDivider
        }

        // 加号按钮
        Rectangle {
            Layout.preferredWidth: 20
            Layout.fillHeight: true
            color: plusArea.containsMouse ? WxTheme.clBgHover : "transparent"
            radius: WxTheme.radiusSmall

            Behavior on color {
                ColorAnimation { duration: WxTheme.animFast }
            }

            Text {
                anchors.centerIn: parent
                text: "+"
                font.pixelSize: WxTheme.fontSizeNormal
                color: WxTheme.clTextPrimary
            }

            MouseArea {
                id: plusArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (root.value < root.to) {
                        root.value = Math.min(root.to, root.value + root.stepSize)
                        root.valueModified(root.value)
                    }
                }
            }
        }
    }
}

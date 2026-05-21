import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string errorText: ""

    signal copyRequested()

    height: errorLayout.implicitHeight + 20
    radius: WxTheme.radiusMedium
    color: "#fff5f5"
    border.width: 1
    border.color: WxTheme.clBorder

    RowLayout {
        id: errorLayout
        anchors.fill: parent
        anchors.margins: WxTheme.spMedium
        spacing: WxTheme.spSmall

        // 红色左边框指示条
        Rectangle {
            width: 3
            height: parent.height
            radius: 1.5
            color: WxTheme.clDangerNew
        }

        // 警告图标
        Text {
            text: "⚠"
            font.pixelSize: 16
        }

        // 错误文字
        Text {
            text: root.errorText
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeNormal
            color: WxTheme.clDangerNew
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // 复制按钮
        Text {
            text: "复制"
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeSmall
            color: copyMouse.containsMouse ? WxTheme.clDangerNewHover : WxTheme.clDangerNew

            MouseArea {
                id: copyMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.copyRequested()
            }
        }
    }
}

import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property var compBackend: null

    height: 36
    color: WxTheme.clBgSecondary

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: WxTheme.spSmall

        Text {
            text: "支持微信 4.x 版本。使用前请确保电脑已登录并打开微信。"
            font.family: WxTheme.fontFamily
            font.pixelSize: 12
            color: WxTheme.clTextSecondary
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            visible: compBackend ? compBackend.demoMode : false
            text: "⚠ 演示模式：非 Windows 环境，所有发送仅做界面模拟"
            font.family: WxTheme.fontFamily
            font.pixelSize: 12
            color: WxTheme.clDangerNew
        }
    }
}

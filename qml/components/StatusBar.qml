import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property var compBackend: null

    height: WxTheme.statusBarHeight
    color: WxTheme.clToolbarFill

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: WxTheme.spMedium
        anchors.rightMargin: WxTheme.spMedium
        spacing: WxTheme.spSmall

        Text {
            text: "支持微信 4.x 版本。使用前请确保电脑已登录并打开微信。"
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeXSmall
            color: WxTheme.clTextSecondary
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            visible: compBackend ? compBackend.demoMode : false
            text: "⚠ 演示模式"
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeXSmall
            color: WxTheme.clDangerNew
        }

        Text {
            text: compBackend ? compBackend.versionInfo.split(" ").pop() : ""
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeXSmall
            color: WxTheme.clTextHint
            horizontalAlignment: Text.AlignRight
        }
    }
}

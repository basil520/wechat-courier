import QtQuick
import QtQuick.Layouts
import "../theme"

ColumnLayout {
    id: root

    property string iconText: "📋"
    property string title: ""
    property string subtitle: ""

    spacing: WxTheme.spSmall

    Text {
        text: root.iconText
        font.pixelSize: 36
        horizontalAlignment: Text.AlignHCenter
        Layout.alignment: Qt.AlignHCenter
    }

    Text {
        visible: root.title !== ""
        text: root.title
        font.family: WxTheme.fontFamily
        font.pixelSize: WxTheme.fontSizeNormal
        color: WxTheme.clTextSecondary
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
    }

    Text {
        visible: root.subtitle !== ""
        text: root.subtitle
        font.family: WxTheme.fontFamily
        font.pixelSize: WxTheme.fontSizeSmall
        color: WxTheme.clTextHint
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
    }
}

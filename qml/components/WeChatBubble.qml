import QtQuick
import QtQuick.Layouts
import "../theme"

Row {
    id: root

    property string messageText: ""
    property bool isError: false

    spacing: 0

    // 三角尾巴
    Canvas {
        width: 8
        height: 12
        anchors.bottom: bubbleRect.bottom
        anchors.bottomMargin: 8

        onPaint: {
            var ctx = getContext("2d")
            ctx.fillStyle = root.isError ? WxTheme.clWarningBg : WxTheme.clBubbleTail
            ctx.beginPath()
            ctx.moveTo(8, 0)
            ctx.lineTo(0, 6)
            ctx.lineTo(8, 12)
            ctx.closePath()
            ctx.fill()
        }
    }

    // 气泡主体
    Rectangle {
        id: bubbleRect
        width: bubbleContent.implicitWidth + 20
        height: bubbleContent.implicitHeight + 16
        radius: WxTheme.radiusMedium
        color: root.isError ? WxTheme.clWarningBg : WxTheme.clBubbleBg

        Text {
            id: bubbleContent
            anchors.fill: parent
            anchors.margins: 8
            text: root.messageText
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeNormal
            color: root.isError ? WxTheme.clLogErr : WxTheme.clTextPrimary
            wrapMode: Text.WordWrap
            maximumLineCount: 20
            elide: Text.ElideRight
        }
    }
}

import QtQuick
import QtQuick.Layouts
import "../theme"

Row {
    id: root

    property string messageText: ""
    property bool isError: false
    property bool isOutgoing: false

    spacing: 0
    layoutDirection: root.isOutgoing ? Qt.RightToLeft : Qt.LeftToRight

    // User profile avatar silhouette (WeChat style)
    Rectangle {
        id: avatarRect
        width: 34
        height: 34
        radius: 4
        color: root.isOutgoing ? WxTheme.clPrimary : WxTheme.clBgSecondary
        border.color: WxTheme.clBorder
        border.width: 1
        anchors.bottom: bubbleRect.bottom

        WxIcon {
            anchors.centerIn: parent
            iconSource: "../icons/user.svg"
            iconColor: root.isOutgoing ? "#ffffff" : WxTheme.clTextSecondary
            iconSize: 18
            hoverScale: false
        }
    }

    // Spacer between avatar and message bubble
    Item {
        width: 8
        height: 34
        anchors.bottom: bubbleRect.bottom
    }

    // 三角尾巴
    Canvas {
        width: 8
        height: 12
        anchors.bottom: bubbleRect.bottom
        anchors.bottomMargin: 10

        onPaint: {
            var ctx = getContext("2d")
            ctx.fillStyle = root.isError ? WxTheme.clWarningBg : WxTheme.clBubbleTail
            ctx.beginPath()
            if (root.isOutgoing) {
                ctx.moveTo(0, 0)
                ctx.lineTo(8, 6)
                ctx.lineTo(0, 12)
            } else {
                ctx.moveTo(8, 0)
                ctx.lineTo(0, 6)
                ctx.lineTo(8, 12)
            }
            ctx.closePath()
            ctx.fill()
        }
    }

    // 气泡主体
    Rectangle {
        id: bubbleRect
        width: Math.min(bubbleContent.implicitWidth + 20, WxTheme.chatBubbleMaxWidth)
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


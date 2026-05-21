import QtQuick
import QtQuick.Controls
import "../theme"

Rectangle {
    id: root
    height: 32
    color: "transparent"
    
    // Properties
    property int charCount: 0

    // Signals
    signal insertRequested(string text)

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: WxTheme.spSmall

        Text {
            id: insertBtn
            text: "+ 插入姓名占位符"
            color: insertMouseArea.containsMouse ? WxTheme.clPrimary : WxTheme.clTextLink
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeSmall
            verticalAlignment: Text.AlignVCenter

            MouseArea {
                id: insertMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.insertRequested("{name}")
                }
            }
            
            Behavior on color {
                ColorAnimation { duration: WxTheme.animFast }
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.charCount + " 字"
        color: WxTheme.clTextHint
        font.family: WxTheme.fontFamily
        font.pixelSize: WxTheme.fontSizeSmall
    }
}

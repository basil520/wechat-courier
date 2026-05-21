import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string friendName: ""
    property string status: "success"   // "success" / "error"
    property string detail: ""
    property string timestamp: ""
    property bool expanded: false

    height: root.expanded ? expandedLayout.implicitHeight + 10 : 24
    radius: WxTheme.radiusSmall
    color: {
        if (mouseArea.containsMouse && root.status === "error") {
            return "#fff5f5"
        }
        if (mouseArea.containsMouse) {
            return WxTheme.clBgHover
        }
        return "transparent"
    }

    Behavior on height {
        NumberAnimation { duration: WxTheme.animFast }
    }

    // 收拢状态
    RowLayout {
        id: collapsedLayout
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 4
        visible: !root.expanded

        Text {
            text: root.status === "success" ? "✅" : "❌"
            font.pixelSize: 12
        }

        Text {
            text: root.friendName
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeLog
            color: root.status === "success" ? WxTheme.clLogOk : WxTheme.clLogErr
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        Text {
            text: root.timestamp
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeTiny
            color: WxTheme.clTextHint
        }
    }

    // 展开状态
    ColumnLayout {
        id: expandedLayout
        anchors.fill: parent
        anchors.margins: 4
        spacing: 2
        visible: root.expanded

        RowLayout {
            spacing: 4
            Layout.fillWidth: true

            Text {
                text: root.status === "success" ? "✅" : "❌"
                font.pixelSize: 12
            }

            Text {
                text: root.friendName
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeLog
                color: root.status === "success" ? WxTheme.clLogOk : WxTheme.clLogErr
                Layout.fillWidth: true
            }

            Text {
                text: root.timestamp
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeTiny
                color: WxTheme.clTextHint
            }
        }

        Text {
            text: root.detail
            font.family: WxTheme.fontFamilyLog
            font.pixelSize: WxTheme.fontSizeLog
            color: WxTheme.clTextSecondary
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.expanded = !root.expanded
    }
}

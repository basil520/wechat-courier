import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../theme"

Rectangle {
    id: root

    property string friendName: ""
    property string status: "success"   // "success" / "error"
    property string detail: ""
    property string timestamp: ""
    property bool expanded: false
    property var itemBackend: null

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
        spacing: 6
        visible: !root.expanded

        WxIcon {
            iconSource: root.status === "success" ? "../icons/success.svg" : "../icons/error.svg"
            iconSize: 14
            hoverScale: false
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: root.friendName
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeLog
            color: root.status === "success" ? WxTheme.clLogOk : WxTheme.clLogErr
            Layout.fillWidth: true
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text: root.timestamp
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeTiny
            color: WxTheme.clTextHint
            verticalAlignment: Text.AlignVCenter
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
            spacing: 6
            Layout.fillWidth: true

            WxIcon {
                iconSource: root.status === "success" ? "../icons/success.svg" : "../icons/error.svg"
                iconSize: 14
                hoverScale: false
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: root.friendName
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeLog
                color: root.status === "success" ? WxTheme.clLogOk : WxTheme.clLogErr
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
            }

            Text {
                text: root.timestamp
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeTiny
                color: WxTheme.clTextHint
                verticalAlignment: Text.AlignVCenter
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                logContextMenu.popup()
            } else {
                root.expanded = !root.expanded
            }
        }
    }

    // 右键上下文菜单
    WxContextMenu {
        id: logContextMenu
        WxContextMenuItem {
            text: "复制当前日志行"
            iconSource: "../icons/file.svg"
            onTriggered: {
                if (root.itemBackend) {
                    var statusText = root.status === "success" ? "成功" : "失败"
                    var detailText = root.detail ? (" | 详情: " + root.detail) : ""
                    var logLine = "[" + root.timestamp + "] 好友: " + root.friendName + " | 状态: " + statusText + detailText
                    root.itemBackend.copy_to_clipboard(logLine)
                    root.itemBackend.showToast("已复制日志到剪贴板", "success")
                }
            }
        }
    }
}

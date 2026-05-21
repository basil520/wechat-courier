import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string fileName: ""
    property string fileSize: ""
    property string fileType: "other"   // "pdf" / "image" / "doc" / "other"
    property int fileIndex: -1

    signal removeRequested(int index)

    height: 32
    radius: WxTheme.radiusSmall
    color: mouseArea.containsMouse ? WxTheme.clBgHover : WxTheme.clBgPrimary
    border.width: 1
    border.color: WxTheme.clBorder

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: WxTheme.spSmall
        anchors.rightMargin: WxTheme.spSmall
        spacing: WxTheme.spSmall

        // 文件类型图标
        Rectangle {
            width: 20
            height: 20
            radius: WxTheme.radiusSmall
            color: {
                switch (root.fileType) {
                    case "pdf": return "#e74c3c"
                    case "image": return "#3498db"
                    case "doc": return "#f39c12"
                    default: return "#95a5a6"
                }
            }

            Text {
                anchors.centerIn: parent
                text: {
                    switch (root.fileType) {
                        case "pdf": return "PDF"
                        case "image": return "IMG"
                        case "doc": return "DOC"
                        default: return "FILE"
                    }
                }
                font.family: WxTheme.fontFamily
                font.pixelSize: 8
                color: "#ffffff"
                font.bold: true
            }
        }

        // 文件名 + 大小
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.fileName
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeSmall
                color: WxTheme.clTextPrimary
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }

            Text {
                visible: root.fileSize !== ""
                text: root.fileSize
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeTiny
                color: WxTheme.clTextHint
            }
        }

        // 删除按钮（hover 时显示）
        Text {
            text: "✕"
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeNormal
            color: mouseArea.containsMouse ? WxTheme.clDangerNew : "transparent"

            MouseArea {
                width: 20
                height: 20
                anchors.centerIn: parent
                z: 1
                onClicked: root.removeRequested(root.fileIndex)
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        z: 0
    }
}

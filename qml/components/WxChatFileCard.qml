import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string fileName: ""
    property string fileSize: ""
    property string fileType: "other"   // "pdf" / "image" / "doc" / "xls" / "other"

    height: WxTheme.chatFileCardHeight
    width: Math.min(parent.width, WxTheme.chatFileCardMaxWidth)
    radius: WxTheme.radiusMedium
    color: WxTheme.clSurfaceStrong
    border.width: 1
    border.color: WxTheme.clBorder

    RowLayout {
        anchors.fill: parent
        anchors.margins: WxTheme.spSmall
        spacing: WxTheme.spSmall

        // 矢量 SVG 图标（24px）
        WxIcon {
            id: fileIcon
            iconSize: 24
            hoverScale: false
            iconSource: {
                switch (root.fileType.toLowerCase()) {
                    case "pdf": return "../icons/pdf.svg"
                    case "image": case "img": return "../icons/image.svg"
                    case "doc": case "docx": case "word": return "../icons/word.svg"
                    case "xls": case "xlsx": case "excel": return "../icons/excel.svg"
                    default: return "../icons/file.svg"
                }
            }
        }

        // 文件名 + 大小
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

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
    }
}

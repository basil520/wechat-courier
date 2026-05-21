import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string fileName: ""
    property string fileSize: ""
    property string fileType: "other"   // "pdf" / "image" / "doc" / "other"

    height: 56
    radius: 8
    color: WxTheme.clBgPrimary
    border.width: 1
    border.color: WxTheme.clBorder

    // 阴影
    Rectangle {
        anchors.fill: parent
        color: WxTheme.clShadow
        opacity: WxTheme.shadowOpacityMedium
        radius: parent.radius
        z: -1
        anchors.horizontalCenterOffset: 0
        anchors.verticalCenterOffset: WxTheme.shadowOffsetY
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: WxTheme.spMedium
        spacing: WxTheme.spMedium

        // 类型色块
        Rectangle {
            width: 40
            height: 40
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
                font.pixelSize: 10
                color: "#ffffff"
                font.bold: true
            }
        }

        // 文件名 + 大小
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: root.fileName
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeNormal
                color: WxTheme.clTextPrimary
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }

            Text {
                visible: root.fileSize !== ""
                text: root.fileSize
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeSmall
                color: WxTheme.clTextHint
            }
        }

        // 下载箭头
        Text {
            text: "▼"
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeNormal
            color: WxTheme.clTextHint
        }
    }
}

import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property string fileName: ""
    property string fileSize: ""
    property string fileType: "other"   // "pdf" / "image" / "doc" / "xls" / "other"

    height: 56
    radius: 8
    color: WxTheme.clSurfaceStrong
    border.width: 1
    border.color: hovered ? WxTheme.clPrimary : WxTheme.clBorder

    // 悬浮提升微交互
    property bool hovered: mouseArea.containsMouse
    y: hovered ? -1 : 0

    Behavior on y { NumberAnimation { duration: WxTheme.animNormal || 120; easing.type: Easing.OutQuad } }
    Behavior on border.color { ColorAnimation { duration: WxTheme.animNormal || 120 } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // 阴影
    Rectangle {
        anchors.fill: parent
        color: WxTheme.clShadow
        opacity: root.hovered ? WxTheme.shadowOpacityLight * 1.5 : WxTheme.shadowOpacityLight
        radius: parent.radius
        z: -1
        anchors.horizontalCenterOffset: 0
        anchors.verticalCenterOffset: root.hovered ? WxTheme.shadowOffsetY + 1 : WxTheme.shadowOffsetY
        
        Behavior on opacity { NumberAnimation { duration: 120 } }
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 120 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: WxTheme.spMedium
        spacing: WxTheme.spMedium

        // 矢量 SVG 图标
        WxIcon {
            id: fileIcon
            iconSize: 36
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

        // 下载箭头/展开图标
        WxIcon {
            iconSource: "../icons/arrow_down.svg"
            iconSize: 14
            iconColor: WxTheme.clTextHint
            hoverScale: false
        }
    }
}

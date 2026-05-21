import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../theme"

Rectangle {
    id: root

    property string fileName: ""
    property string fileSize: ""
    property string fileType: "other"   // "pdf" / "image" / "doc" / "other"
    property int fileIndex: -1
    property string filePath: ""
    property var itemBackend: null
    property bool removable: true

    signal removeRequested(int index)

    // 是否处于删除动画阶段
    property bool isDeleting: false

    // 高度与透明度缩折动画
    height: isDeleting ? 0 : 32
    opacity: isDeleting ? 0.0 : 1.0
    clip: true

    Behavior on height {
        id: heightBehavior
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
            onRunningChanged: {
                if (!running && root.isDeleting) {
                    root.removeRequested(root.fileIndex)
                }
            }
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    radius: WxTheme.radiusSmall
    color: mouseArea.containsMouse ? WxTheme.clBgHover : WxTheme.clBgPrimary
    border.width: 1
    border.color: mouseArea.containsMouse ? WxTheme.clPrimary : WxTheme.clBorder

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                fileContextMenu.popup()
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: WxTheme.spSmall
        anchors.rightMargin: WxTheme.spSmall
        spacing: WxTheme.spSmall

        // 文件类型图标 (矢量 SVG)
        WxIcon {
            iconSize: 20
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

        // 删除按钮（hover 时显示，发送中隐藏）
        WxIcon {
            visible: root.removable
            iconSource: "../icons/trash.svg"
            iconSize: 14
            iconColor: mouseArea.containsMouse ? WxTheme.clTextHint : "transparent"
            hoverColor: WxTheme.clDangerNew
            hoverScale: true

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.isDeleting = true
                }
            }
        }
    }

    // 右键上下文菜单
    WxContextMenu {
        id: fileContextMenu
        WxContextMenuItem {
            text: "打开文件"
            iconSource: "../icons/play.svg"
            onTriggered: {
                if (root.itemBackend && root.filePath !== "") {
                    root.itemBackend.open_file(root.filePath)
                }
            }
        }
        WxContextMenuItem {
            text: "打开所在文件夹"
            iconSource: "../icons/export.svg"
            onTriggered: {
                if (root.itemBackend && root.filePath !== "") {
                    root.itemBackend.open_file_folder(root.filePath)
                }
            }
        }
        MenuSeparator {
            background: Rectangle {
                implicitHeight: 1
                color: WxTheme.clDivider
            }
        }
        WxContextMenuItem {
            text: "从列表中移除"
            iconSource: "../icons/trash.svg"
            iconColor: WxTheme.clDangerNew
            hoverIconColor: WxTheme.clDangerNewHover
            onTriggered: {
                root.isDeleting = true
            }
        }
    }
}

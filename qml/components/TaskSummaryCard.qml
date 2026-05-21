import QtQuick
import QtQuick.Controls
import "../theme"

Rectangle {
    id: root
    radius: WxTheme.radiusMedium
    color: WxTheme.clBgPrimary
    border.color: WxTheme.clBorder
    border.width: 1
    
    // Properties
    property bool isCompleted: true
    property int successCount: 0
    property int failureCount: 0
    property int elapsedTime: 0
    property int fileCount: 0

    // Signals
    signal exportLogsRequested()
    signal clearLogsRequested()

    // Formatted time: e.g. "12 秒" or "02:15"
    function formatTime(sec) {
        if (sec < 60) return sec + " 秒"
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s)
    }

    // Left visual accent bar
    Rectangle {
        id: accentBar
        width: 4
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: root.isCompleted ? WxTheme.clPrimary : WxTheme.clWarning
        radius: WxTheme.radiusSmall
    }

    Column {
        anchors.left: accentBar.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: WxTheme.spMedium
        spacing: WxTheme.spMedium

        // Header Row
        Row {
            spacing: WxTheme.spSmall
            Text {
                text: root.isCompleted ? "✅ 发送任务已完成" : "⚠️ 发送任务已结束"
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeNormal
                font.bold: true
                color: WxTheme.clTextPrimary
            }
        }

        // Stats Row
        Row {
            spacing: WxTheme.spLarge * 1.5
            width: parent.width

            // Success stat
            Column {
                spacing: WxTheme.spTiny
                Text {
                    text: "成功数"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeTiny
                    color: WxTheme.clTextSecondary
                }
                Text {
                    text: root.successCount + " 人"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeNormal
                    font.bold: true
                    color: WxTheme.clPrimary
                }
            }

            // Failure stat (only if > 0)
            Column {
                spacing: WxTheme.spTiny
                visible: root.failureCount > 0
                Text {
                    text: "失败数"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeTiny
                    color: WxTheme.clTextSecondary
                }
                Text {
                    text: root.failureCount + " 人"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeNormal
                    font.bold: true
                    color: WxTheme.clDangerNew
                }
            }

            // Elapsed Time stat
            Column {
                spacing: WxTheme.spTiny
                Text {
                    text: "总耗时"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeTiny
                    color: WxTheme.clTextSecondary
                }
                Text {
                    text: root.formatTime(root.elapsedTime)
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeNormal
                    font.bold: true
                    color: WxTheme.clTextPrimary
                }
            }

            // File Count stat
            Column {
                spacing: WxTheme.spTiny
                Text {
                    text: "发送文件"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeTiny
                    color: WxTheme.clTextSecondary
                }
                Text {
                    text: root.fileCount + " 个"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeNormal
                    font.bold: true
                    color: WxTheme.clTextPrimary
                }
            }
        }

        // Actions Row
        Row {
            spacing: WxTheme.spMedium
            
            Button {
                id: exportBtn
                text: "导出日志"
                contentItem: Text {
                    text: exportBtn.text
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeSmall
                    color: exportBtn.hovered ? WxTheme.clPrimaryHover : WxTheme.clPrimary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitWidth: 80
                    implicitHeight: 28
                    radius: WxTheme.radiusSmall
                    color: exportBtn.hovered ? "#edf9f2" : "#f4fcf7"
                    border.color: WxTheme.clPrimary
                    border.width: 1
                }
                onClicked: root.exportLogsRequested()
            }

            Button {
                id: clearBtn
                text: "清空记录"
                contentItem: Text {
                    text: clearBtn.text
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeSmall
                    color: clearBtn.hovered ? WxTheme.clTextPrimary : WxTheme.clTextSecondary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitWidth: 80
                    implicitHeight: 28
                    radius: WxTheme.radiusSmall
                    color: clearBtn.hovered ? "#ededed" : "#f5f5f5"
                    border.color: WxTheme.clBorder
                    border.width: 1
                }
                onClicked: root.clearLogsRequested()
            }
        }
    }
}

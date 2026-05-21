import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtCore
import "../theme"

Rectangle {
    id: root

    property var panelBackend: null
    
    // 统计数据
    property int successCount: 0
    property int failureCount: 0
    property int elapsedTime: 0

    color: WxTheme.clBgPrimary

    Timer {
        id: elapsedTimer
        interval: 1000
        repeat: true
        onTriggered: root.elapsedTime += 1
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: WxTheme.spSmall

        // ── 标题 ──
        Text {
            text: "发送进度"
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeNormal
            font.bold: true
            color: WxTheme.clTextPrimary
        }

        // ── 进度条 + 状态 ──
        RowLayout {
            Layout.fillWidth: true
            spacing: WxTheme.spMedium

            ProgressBar {
                id: progressBar
                Layout.fillWidth: true
                from: 0
                to: 100
                value: panelBackend ? panelBackend.progressValue : 0

                // 平滑动画
                Behavior on value {
                    NumberAnimation {
                        duration: WxTheme.animProgress
                        easing.type: Easing.OutCubic
                    }
                }

                background: Rectangle {
                    implicitHeight: 8
                    radius: height / 2
                    color: WxTheme.clDivider
                }

                contentItem: Item {
                    implicitHeight: 8
                    Rectangle {
                        width: progressBar.visualPosition * parent.width
                        height: parent.height
                        radius: height / 2
                        color: WxTheme.clPrimary
                    }
                }
            }

            Text {
                text: panelBackend ? panelBackend.progressStatus : ""
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeNormal
                color: WxTheme.clTextSecondary
                Layout.preferredWidth: 300
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }

        // ── 当前处理好友 ──
        Text {
            text: {
                if (panelBackend && panelBackend.currentFriend !== "") {
                    return "正在处理：" + panelBackend.currentFriend
                }
                return ""
            }
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeSmall
            color: WxTheme.clTextHint
            visible: text !== ""
        }

        // ── 致命错误（使用 ErrorCard）──
        ErrorCard {
            visible: panelBackend ? panelBackend.fatalError !== "" : false
            errorText: panelBackend ? panelBackend.fatalError : ""
            Layout.fillWidth: true
            onCopyRequested: {
                if (panelBackend && panelBackend.fatalError) {
                    // 复制到剪贴板（如果有 Qt 剪贴板支持）
                }
            }
        }

        // ── 发送总结卡片 ──
        TaskSummaryCard {
            id: summaryCard
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            Layout.minimumHeight: 140
            visible: panelBackend ? (panelBackend.phase === "done" && logModelList.count > 0) : false
            
            isCompleted: panelBackend ? (panelBackend.progressStatus.indexOf("停止") === -1 && panelBackend.progressStatus.indexOf("错误") === -1) : true
            successCount: root.successCount
            failureCount: root.failureCount
            elapsedTime: root.elapsedTime
            fileCount: panelBackend ? panelBackend.filePaths.length : 0

            onClearLogsRequested: {
                logModelList.clear()
                root.successCount = 0
                root.failureCount = 0
                root.elapsedTime = 0
            }

            onExportLogsRequested: {
                exportFileDialog.open()
            }
        }

        // ── 日志区 ──
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: WxTheme.radiusSmall
            border.width: 1
            border.color: WxTheme.clBorder
            color: WxTheme.clBgPrimary

            // 空状态
            EmptyState {
                anchors.centerIn: parent
                visible: logListView.count === 0
                iconText: "📋"
                title: "暂无发送记录"
                subtitle: "开始发送后将在此显示日志"
            }

            ListView {
                id: logListView
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                model: logModelList
                spacing: 2
                visible: count > 0

                onCountChanged: {
                    if (logModelList.count > 0) {
                        positionViewAtEnd()
                    }
                }

                delegate: LogItem {
                    width: logListView.width
                    friendName: model.friendName || ""
                    status: model.status || "success"
                    detail: model.detail || ""
                    timestamp: model.timestamp || ""
                }
            }
        }
    }

    // ── 日志数据模型 ──
    ListModel {
        id: logModelList
    }

    // ── 监听 backend 的 logEntryAdded 信号 ──
    Connections {
        target: panelBackend
        function onLogEntryAdded(friend, greeting, status, detail) {
            var now = new Date()
            var ts = now.getHours().toString().padStart(2, "0") + ":"
                   + now.getMinutes().toString().padStart(2, "0") + ":"
                   + now.getSeconds().toString().padStart(2, "0")
            logModelList.append({
                "friendName": friend,
                "status": status,
                "detail": detail,
                "timestamp": ts
            })

            if (status === "success") {
                root.successCount += 1
            } else if (status === "error") {
                root.failureCount += 1
            }
        }
    }

    // 重置与定时器状态监听
    Connections {
        target: panelBackend
        function onPhaseChanged(phase) {
            if (phase === "idle") {
                logModelList.clear()
                root.successCount = 0
                root.failureCount = 0
                root.elapsedTime = 0
                elapsedTimer.stop()
            } else if (phase === "running") {
                elapsedTimer.start()
            } else if (phase === "paused") {
                elapsedTimer.stop()
            } else if (phase === "done") {
                elapsedTimer.stop()
            }
        }
    }

    // 日志导出对话框
    FileDialog {
        id: exportFileDialog
        title: "选择日志导出路径"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Text files (*.txt)"]
        currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            if (panelBackend) {
                var logLines = []
                logLines.push("=== 五阿哥群发助手发送日志 ===")
                logLines.push("任务完成状态: " + (summaryCard.isCompleted ? "全部完成" : "用户中止/未完成"))
                logLines.push("成功数: " + root.successCount + " 人")
                logLines.push("失败数: " + root.failureCount + " 人")
                logLines.push("总耗时: " + summaryCard.formatTime(root.elapsedTime))
                logLines.push("附加文件: " + (panelBackend ? panelBackend.filePaths.join(", ") : "无"))
                logLines.push("--------------------------------")
                for (var i = 0; i < logModelList.count; i++) {
                    var item = logModelList.get(i)
                    logLines.push("[" + item.timestamp + "] 好友: " + item.friendName + " | 状态: " + (item.status === "success" ? "成功" : "失败") + " | 详情: " + item.detail)
                }
                var formattedLogs = logLines.join("\n")
                
                var success = panelBackend.export_logs(exportFileDialog.selectedFile.toString(), formattedLogs)
                if (success) {
                    panelBackend.showToast("日志导出成功！", "success")
                } else {
                    panelBackend.showToast("日志导出失败！", "error")
                }
            }
        }
    }
}

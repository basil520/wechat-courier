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
    property string fatalError: panelBackend ? panelBackend.fatalError : ""

    color: WxTheme.clBgWindow // 柔和窗体底色

    // 格式化时间辅助函数
    function formatTime(secs) {
        var m = Math.floor(secs / 60)
        var s = secs % 60
        return m.toString().padStart(2, "0") + ":" + s.toString().padStart(2, "0")
    }

    Timer {
        id: elapsedTimer
        interval: 1000
        repeat: true
        onTriggered: root.elapsedTime += 1
    }

    // ── 日志数据模型 ──
    ListModel {
        id: logModelList
    }

    Component.onCompleted: {
        if (panelBackend) {
            if (panelBackend.phase === "running") {
                elapsedTimer.start()
            } else if (panelBackend.phase === "paused" || panelBackend.phase === "done") {
                elapsedTimer.stop()
            }
        }
    }

    // ── 监听 backend 的 logEntryAdded 信号 ──
    Connections {
        target: panelBackend
        ignoreUnknownSignals: true
        
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

    // ── 监听 backend 的 phase 变化 ──
    Connections {
        target: panelBackend
        ignoreUnknownSignals: true

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

    // ── 日志导出对话框 ──
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
                logLines.push("任务完成状态: " + (panelBackend.progressStatus.indexOf("停止") === -1 && panelBackend.progressStatus.indexOf("错误") === -1 ? "全部完成" : "用户中止/未完成"))
                logLines.push("成功数: " + root.successCount + " 人")
                logLines.push("失败数: " + root.failureCount + " 人")
                logLines.push("总耗时: " + root.formatTime(root.elapsedTime))
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ── 顶部横栏：环形进度与统计指标 ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            // 1. 环形进度卡片 (WeChat style)
            Rectangle {
                Layout.preferredWidth: 240
                Layout.preferredHeight: 160
                radius: WxTheme.radiusMedium
                color: WxTheme.clBgPrimary
                border.width: 1
                border.color: WxTheme.clBorder

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    
                    // Circular Progress Canvas
                    Item {
                        width: 90
                        height: 90
                        Layout.alignment: Qt.AlignHCenter

                        Canvas {
                            id: progressCanvas
                            anchors.fill: parent
                            
                            property real displayProgress: 0
                            Behavior on displayProgress {
                                NumberAnimation {
                                    duration: WxTheme.animProgress || 300
                                    easing.type: Easing.OutCubic
                                }
                            }
                            
                            Binding {
                                target: progressCanvas
                                property: "displayProgress"
                                value: (panelBackend ? panelBackend.progressValue : 0) / 100.0
                            }
                            
                            onDisplayProgressChanged: progressCanvas.requestPaint()
                            
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                
                                var centerX = width / 2;
                                var centerY = height / 2;
                                var radius = Math.min(width, height) / 2 - 6;
                                
                                // Draw background circle
                                ctx.beginPath();
                                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI, false);
                                ctx.lineWidth = 6;
                                ctx.strokeStyle = WxTheme.clDivider;
                                ctx.stroke();
                                
                                // Draw progress arc
                                if (displayProgress > 0) {
                                    ctx.beginPath();
                                    var startAngle = -Math.PI / 2;
                                    var endAngle = startAngle + (displayProgress * 2 * Math.PI);
                                    ctx.arc(centerX, centerY, radius, startAngle, endAngle, false);
                                    ctx.lineWidth = 6;
                                    ctx.lineCap = "round";
                                    ctx.strokeStyle = WxTheme.clPrimary;
                                    ctx.stroke();
                                }
                            }
                        }

                        // Centered percentage text
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0
                            Text {
                                text: (panelBackend ? panelBackend.progressValue : 0) + "%"
                                font.family: WxTheme.fontFamily
                                font.pixelSize: 20
                                font.bold: true
                                color: WxTheme.clTextPrimary
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // Progress Status Text below
                    Text {
                        text: panelBackend ? panelBackend.progressStatus : ""
                        font.family: WxTheme.fontFamily
                        font.pixelSize: 12
                        color: WxTheme.clTextSecondary
                        Layout.alignment: Qt.AlignHCenter
                        Layout.maximumWidth: 220
                        elide: Text.ElideRight
                    }
                }
            }

            // 2. 统计指标卡片组 (3 cards in horizontal layout)
            GridLayout {
                columns: 3
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                columnSpacing: 16
                rowSpacing: 16

                // Card 1: 成功发送
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: WxTheme.radiusMedium
                    color: WxTheme.clBgPrimary
                    border.width: 1
                    border.color: WxTheme.clBorder

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        WxIcon {
                            iconSource: "../icons/success.svg"
                            iconSize: 28
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "成功发送"
                            font.family: WxTheme.fontFamily
                            font.pixelSize: 12
                            color: WxTheme.clTextSecondary
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: root.successCount + " 人"
                            font.family: WxTheme.fontFamily
                            font.pixelSize: 22
                            font.bold: true
                            color: WxTheme.clPrimary
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // Card 2: 发送失败
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: WxTheme.radiusMedium
                    color: WxTheme.clBgPrimary
                    border.width: 1
                    border.color: WxTheme.clBorder

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        WxIcon {
                            iconSource: "../icons/error.svg"
                            iconSize: 28
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "发送失败"
                            font.family: WxTheme.fontFamily
                            font.pixelSize: 12
                            color: WxTheme.clTextSecondary
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: root.failureCount + " 人"
                            font.family: WxTheme.fontFamily
                            font.pixelSize: 22
                            font.bold: true
                            color: root.failureCount > 0 ? WxTheme.clDangerNew : WxTheme.clTextHint
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // Card 3: 运行时间
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: WxTheme.radiusMedium
                    color: WxTheme.clBgPrimary
                    border.width: 1
                    border.color: WxTheme.clBorder

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        WxIcon {
                            iconSource: "../icons/info.svg"
                            iconSize: 28
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "总耗时"
                            font.family: WxTheme.fontFamily
                            font.pixelSize: 12
                            color: WxTheme.clTextSecondary
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: root.formatTime(root.elapsedTime)
                            font.family: WxTheme.fontFamily
                            font.pixelSize: 22
                            font.bold: true
                            color: WxTheme.clPrimary
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }

        // ── 错误卡片（如有致命错误）──
        ErrorCard {
            visible: root.fatalError !== ""
            errorText: root.fatalError
            Layout.fillWidth: true
        }

        // ── 中部：实时终端日志列表 ──
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: WxTheme.radiusMedium
            color: WxTheme.clBgPrimary
            border.width: 1
            border.color: WxTheme.clBorder
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Console Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    color: WxTheme.clBgPrimary
                    
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: WxTheme.clDivider
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        Text {
                            text: "实时发送日志"
                            font.family: WxTheme.fontFamily
                            font.pixelSize: WxTheme.fontSizeNormal
                            font.bold: true
                            color: WxTheme.clTextPrimary
                        }

                        Item { Layout.fillWidth: true }

                        // Export logs button
                        Button {
                            id: exportBtn
                            font.family: WxTheme.fontFamily
                            font.pixelSize: 12
                            implicitHeight: 28
                            implicitWidth: 84
                            visible: logModelList.count > 0

                            contentItem: RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                WxIcon {
                                    iconSource: "../icons/export.svg"
                                    iconSize: 14
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                Text {
                                    text: "导出日志"
                                    font: exportBtn.font
                                    color: WxTheme.clTextPrimary
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }

                            background: Rectangle {
                                radius: WxTheme.radiusSmall
                                color: exportBtn.pressed ? WxTheme.clDivider : (exportBtn.hovered ? WxTheme.clBgSecondary : "transparent")
                                border.width: 1
                                border.color: WxTheme.clBorder
                            }

                            onClicked: {
                                exportFileDialog.open()
                            }
                        }
                    }
                }

                // Logs View Area
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    EmptyState {
                        anchors.centerIn: parent
                        visible: logListView.count === 0
                        iconText: "📋"
                        title: "暂无实时日志"
                        subtitle: "发送任务启动后将在此实时输出进度详情"
                    }

                    ListView {
                        id: logListView
                        anchors.fill: parent
                        anchors.margins: 10
                        clip: true
                        model: logModelList
                        spacing: 6
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
                            itemBackend: root.panelBackend
                        }
                    }
                }
            }
        }

        // ── 底部控制按钮组 (Sticky Bottom) ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            color: "transparent"

            RowLayout {
                anchors.centerIn: parent
                spacing: 16

                ActionButtons {
                    id: dashboardActionButtons
                    btnBackend: root.panelBackend
                }

                // Extra WeChat-style Back to Config button in done phase
                Button {
                    id: backToConfigBtn
                    text: "返回配置"
                    visible: panelBackend ? (panelBackend.phase === "done") : false
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeNormal
                    implicitHeight: 32
                    implicitWidth: 96

                    contentItem: Text {
                        text: backToConfigBtn.text
                        font: backToConfigBtn.font
                        color: WxTheme.clTextPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: WxTheme.radiusSmall
                        border.width: 1
                        border.color: WxTheme.clBorder
                        color: backToConfigBtn.pressed ? WxTheme.clDivider : (backToConfigBtn.hovered ? WxTheme.clBgSecondary : WxTheme.clBgPrimary)
                    }

                    onClicked: {
                        if (panelBackend) {
                            panelBackend.reset()
                        }
                    }
                }
            }
        }
    }
}

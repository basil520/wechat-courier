import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../theme"

Rectangle {
    id: root

    property var panelBackend: null

    color: WxTheme.clBgPrimary

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
        }
    }

    // 重置时清空日志
    Connections {
        target: panelBackend
        function onPhaseChanged(phase) {
            if (phase === "idle") {
                logModelList.clear()
            }
        }
    }
}

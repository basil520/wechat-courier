import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property var mainBackend: null

    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── 主内容区：左 55% 配置 + 右 45% 预览/日志 ──
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            InputPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 55
                panelBackend: root.mainBackend
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: WxTheme.clGlassDivider
            }

            RightPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 45
                panelBackend: root.mainBackend
            }
        }

        // ── 底部操作栏 ──
        ActionBar {
            id: actionBar
            Layout.fillWidth: true
            barBackend: root.mainBackend
            onStartSendRequested: sendConfirmDialog.open()
        }
    }

    ConfirmDialog {
        id: sendConfirmDialog
        anchors.fill: parent
        message: {
            var count = 0
            if (root.mainBackend) {
                var lines = root.mainBackend.friendListText.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].trim() !== "") count++
                }
            }
            return "即将向 " + count + " 位好友发送消息"
                   + (root.mainBackend && root.mainBackend.filePaths.length > 0 ? "，共 " + root.mainBackend.filePaths.length + " 个文件" : "")
                   + "。是否继续？"
        }
        confirmText: "确认发送"
        cancelText: "取消"
        onConfirmed: {
            if (root.mainBackend) root.mainBackend.start_sending()
        }
    }
}

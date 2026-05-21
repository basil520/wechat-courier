import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property var panelBackend: null

    color: "transparent"

    // 内部 Tab 索引
    property int currentTab: 0

    // Tab 自动切换逻辑
    Connections {
        target: panelBackend
        ignoreUnknownSignals: true

        function onPhaseChanged(phase) {
            if (phase === "running") {
                // 自动切换到「发送日志」Tab
                root.currentTab = 1
            } else if (phase === "idle") {
                // 重置后切回「预览」Tab
                root.currentTab = 0
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Tab 栏 ──
        WxTabBar {
            Layout.fillWidth: true
            tabs: ["预览", "发送日志"]
            currentIndex: root.currentTab
            showNotificationDot: panelBackend ? panelBackend.phase === "running" : false
            onTabClicked: function(index) {
                root.currentTab = index
            }
        }

        // ── Tab 内容区 ──
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentTab

            ChatPreview {
                panelBackend: root.panelBackend
            }

            SendLogPanel {
                panelBackend: root.panelBackend
            }
        }
    }
}

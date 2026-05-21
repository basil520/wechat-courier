import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root
    
    // backend 从 App.qml 传入
    property var mainBackend: null

    color: WxTheme.clBgPrimary

    // 追踪是否处于发送执行阶段 (只要不是 idle 阶段，即代表正处于发送中、暂停中或已完成)
    property bool isExecutionActive: mainBackend ? (mainBackend.phase !== "idle") : false

    Item {
        anchors.fill: parent
        clip: true

        // ── 1. Setup View (编辑配置界面) ──
        Rectangle {
            id: setupView
            width: parent.width
            height: parent.height
            color: WxTheme.clBgPrimary
            
            // 视差横滑与渐隐
            x: root.isExecutionActive ? -parent.width * 0.3 : 0
            opacity: root.isExecutionActive ? 0.0 : 1.0
            visible: opacity > 0

            Behavior on x {
                NumberAnimation {
                    duration: WxTheme.animSlow || 250
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: WxTheme.animSlow || 250
                    easing.type: Easing.OutCubic
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: WxTheme.spLarge
                spacing: WxTheme.spLarge

                InputPanel {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 200
                    panelBackend: root.mainBackend
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: WxTheme.clDivider
                }

                PreviewPanel {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 150
                    panelBackend: root.mainBackend
                }
            }
        }

        // ── 2. Dashboard View (仪表盘执行界面) ──
        DashboardView {
            id: dashboardView
            width: parent.width
            height: parent.height
            panelBackend: root.mainBackend

            // 视差横滑与渐显
            x: root.isExecutionActive ? 0 : parent.width * 0.3
            opacity: root.isExecutionActive ? 1.0 : 0.0
            visible: opacity > 0

            Behavior on x {
                NumberAnimation {
                    duration: WxTheme.animSlow || 250
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: WxTheme.animSlow || 250
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}

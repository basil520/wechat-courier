import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import "components"
import "theme"

ApplicationWindow {
    id: root

    width: 960
    height: 780
    minimumWidth: 800
    minimumHeight: 650
    visible: true
    title: "五阿哥群发助手"

    background: Rectangle {
        color: WxTheme.clBgPrimary
    }

    // 窗口居中
    Component.onCompleted: {
        root.x = (Screen.width - root.width) / 2
        root.y = (Screen.height - root.height) / 2
        if (typeof backend !== "undefined" && backend) {
            root.title = backend.versionInfo
        }
    }

    Connections {
        target: typeof backend !== "undefined" ? backend : null
        function onVersionInfoChanged() {
            root.title = backend.versionInfo
        }
    }

    onClosing: function(closeEvent) {
        if (typeof backend !== "undefined" && backend) {
            if (backend.phase === "running" || backend.phase === "paused") {
                closeEvent.accepted = false
                closeConfirmDialog.open()
            }
        }
    }

    // 关闭确认对话框
    ConfirmDialog {
        id: closeConfirmDialog
        message: "发送任务正在进行中，关闭窗口将中断发送。是否确认关闭？"
        isDanger: true
        confirmText: "确认关闭"
        cancelText: "取消"
        onConfirmed: Qt.quit()
    }

    App {
        anchors.fill: parent
        appBackend: typeof backend !== "undefined" ? backend : null
    }

    // 全局 Toast 提示
    Toast {
        id: globalToast
    }

    Connections {
        target: typeof backend !== "undefined" ? backend : null
        function onShowToast(message, type) {
            globalToast.show(message, type)
        }
    }

    // 启动加载动画遮罩
    Rectangle {
        id: startupLoader
        anchors.fill: parent
        color: WxTheme.clBgWindow
        z: 10000
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: WxTheme.animSlow }
        }

        Column {
            anchors.centerIn: parent
            spacing: WxTheme.spMedium

            // 微信绿旋转加载环
            BusyIndicator {
                id: busyInd
                anchors.horizontalCenter: parent.horizontalCenter
                running: startupLoader.visible
                contentItem: Item {
                    implicitWidth: 40
                    implicitHeight: 40
                    Rectangle {
                        id: rect
                        anchors.fill: parent
                        color: "transparent"
                        border.color: WxTheme.clPrimary
                        border.width: 3
                        radius: 20
                    }
                    RotationAnimator {
                        target: rect
                        from: 0
                        to: 360
                        duration: 1000
                        running: busyInd.running
                        loops: Animation.Infinite
                    }
                }
            }

            Text {
                text: "五阿哥群发助手"
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeNormal + 2
                font.bold: true
                color: WxTheme.clTextPrimary
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                text: "正在初始化应用..."
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeSmall
                color: WxTheme.clTextSecondary
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Timer {
            interval: 800
            running: true
            repeat: false
            onTriggered: {
                startupLoader.opacity = 0.0
            }
        }
    }
}

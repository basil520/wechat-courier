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
}

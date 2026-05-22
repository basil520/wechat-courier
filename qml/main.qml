import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
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
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowSystemMenuHint | Qt.WindowMinMaxButtonsHint

    background: Rectangle {
        color: WxTheme.clWindowTint
        Behavior on color {
            ColorAnimation { duration: WxTheme.animSlow }
        }
    }

    function syncWindowVisuals() {
        if (typeof backend !== "undefined" && backend) {
            backend.updateWindowVisuals(root.winId, WxTheme.isDark, WxTheme.glassEnabled, WxTheme.glassOpacity)
        }
    }

    // 监听窗口视觉变化，调用后端 Win32 API 动态刷新原生材质
    Connections {
        target: WxTheme
        ignoreUnknownSignals: true
        function onIsDarkChanged() {
            root.syncWindowVisuals()
        }
        function onGlassEnabledChanged() {
            root.syncWindowVisuals()
        }
        function onGlassOpacityChanged() {
            root.syncWindowVisuals()
        }
    }

    // 窗口居中并初始化 DWM 原生效果
    Component.onCompleted: {
        root.x = (Screen.width - root.width) / 2
        root.y = (Screen.height - root.height) / 2
        if (typeof backend !== "undefined" && backend) {
            root.title = backend.versionInfo
            WxTheme.glassEnabled = backend.glassEnabled
            WxTheme.glassOpacity = backend.glassOpacity
            root.syncWindowVisuals()
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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        WxTitleBar {
            id: customTitleBar
            Layout.fillWidth: true
            window: root
            titleBackend: typeof backend !== "undefined" ? backend : null
        }

        App {
            Layout.fillWidth: true
            Layout.fillHeight: true
            appBackend: typeof backend !== "undefined" ? backend : null
        }
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

    component ResizeHandle: MouseArea {
        property int resizeEdges: Qt.LeftEdge

        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        z: 9000
        onPressed: {
            if (root.visibility !== Window.FullScreen) {
                root.startSystemResize(resizeEdges)
            }
        }
    }

    ResizeHandle {
        resizeEdges: Qt.LeftEdge
        width: 6
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeHorCursor
    }

    ResizeHandle {
        resizeEdges: Qt.RightEdge
        width: 6
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeHorCursor
    }

    ResizeHandle {
        resizeEdges: Qt.TopEdge
        height: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        cursorShape: Qt.SizeVerCursor
    }

    ResizeHandle {
        resizeEdges: Qt.BottomEdge
        height: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeVerCursor
    }

    ResizeHandle {
        resizeEdges: Qt.LeftEdge | Qt.TopEdge
        width: 10
        height: 10
        anchors.left: parent.left
        anchors.top: parent.top
        cursorShape: Qt.SizeFDiagCursor
    }

    ResizeHandle {
        resizeEdges: Qt.RightEdge | Qt.TopEdge
        width: 10
        height: 10
        anchors.right: parent.right
        anchors.top: parent.top
        cursorShape: Qt.SizeBDiagCursor
    }

    ResizeHandle {
        resizeEdges: Qt.LeftEdge | Qt.BottomEdge
        width: 10
        height: 10
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeBDiagCursor
    }

    ResizeHandle {
        resizeEdges: Qt.RightEdge | Qt.BottomEdge
        width: 10
        height: 10
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeFDiagCursor
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

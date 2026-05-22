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

    property string snapPreviewMode: ""
    property rect snapPreviewRect: Qt.rect(0, 0, 0, 0)
    property rect normalGeometry: Qt.rect(0, 0, 960, 780)
    property rect _dragRestoreGeometry: Qt.rect(0, 0, 960, 780)
    property bool _windowGestureActive: false
    property bool _applyingWindowLayout: false
    property real _dragStartWindowX: 0
    property real _dragStartWindowY: 0
    property real _dragStartGlobalX: 0
    property real _dragStartGlobalY: 0
    property int snapEdgeThreshold: 28

    function screenGeometry() {
        if (root.screen && root.screen.availableGeometry.width > 0) {
            return root.screen.availableGeometry
        }
        return Qt.rect(0, 0, Screen.width, Screen.height)
    }

    function captureNormalGeometry() {
        if (!root._windowGestureActive
                && !root._applyingWindowLayout
                && root.visibility === Window.Windowed
                && root.width >= root.minimumWidth
                && root.height >= root.minimumHeight) {
            root.normalGeometry = Qt.rect(root.x, root.y, root.width, root.height)
        }
    }

    function rememberNormalGeometry() {
        if (root.visibility === Window.Windowed) {
            root.normalGeometry = Qt.rect(root.x, root.y, root.width, root.height)
        }
    }

    function snapRectForMode(mode) {
        var g = root.screenGeometry()
        if (mode === "left") {
            return Qt.rect(g.x, g.y, Math.max(root.minimumWidth, Math.round(g.width / 2)), g.height)
        }
        if (mode === "right") {
            var halfWidth = Math.max(root.minimumWidth, Math.round(g.width / 2))
            return Qt.rect(g.x + g.width - halfWidth, g.y, halfWidth, g.height)
        }
        return Qt.rect(g.x, g.y, g.width, g.height)
    }

    function showSnapPreview(mode) {
        root.snapPreviewMode = mode
        root.snapPreviewRect = root.snapRectForMode(mode)
    }

    function hideSnapPreview() {
        root.snapPreviewMode = ""
        root.snapPreviewRect = Qt.rect(0, 0, 0, 0)
    }

    function updateSnapPreviewForPoint(globalX, globalY) {
        var g = root.screenGeometry()
        if (globalY <= g.y + root.snapEdgeThreshold) {
            root.showSnapPreview("top")
        } else if (globalX <= g.x + root.snapEdgeThreshold) {
            root.showSnapPreview("left")
        } else if (globalX >= g.x + g.width - root.snapEdgeThreshold) {
            root.showSnapPreview("right")
        } else {
            root.hideSnapPreview()
        }
    }

    function applyWindowGeometry(rect) {
        root._applyingWindowLayout = true
        root.showNormal()
        root.width = Math.max(root.minimumWidth, Math.round(rect.width))
        root.height = Math.max(root.minimumHeight, Math.round(rect.height))
        root.x = Math.round(rect.x)
        root.y = Math.round(rect.y)
        root._applyingWindowLayout = false
        root.normalGeometry = Qt.rect(root.x, root.y, root.width, root.height)
    }

    function applySnapMode(mode) {
        root.hideSnapPreview()
        if (root.visibility !== Window.Windowed) {
            root.showNormal()
        }
        if (mode === "top" || mode === "maximize") {
            if (!root._windowGestureActive) root.rememberNormalGeometry()
            root.showMaximized()
            return
        }
        if (mode === "left" || mode === "right") {
            if (!root._windowGestureActive) root.rememberNormalGeometry()
            var target = root.snapRectForMode(mode)
            root._applyingWindowLayout = true
            root.showNormal()
            root.width = Math.max(root.minimumWidth, Math.round(target.width))
            root.height = Math.max(root.minimumHeight, Math.round(target.height))
            root.x = Math.round(target.x)
            root.y = Math.round(target.y)
            root._applyingWindowLayout = false
        }
    }

    function centerAndRestore() {
        var g = root.screenGeometry()
        var targetWidth = Math.max(root.minimumWidth, Math.min(root.normalGeometry.width, g.width - 48))
        var targetHeight = Math.max(root.minimumHeight, Math.min(root.normalGeometry.height, g.height - 48))
        root.applyWindowGeometry(Qt.rect(
            g.x + Math.round((g.width - targetWidth) / 2),
            g.y + Math.round((g.height - targetHeight) / 2),
            targetWidth,
            targetHeight
        ))
    }

    function enterFullScreenPreview() {
        if (root.visibility !== Window.FullScreen) {
            root.rememberNormalGeometry()
            root.hideSnapPreview()
            root.showFullScreen()
        }
    }

    function exitFullScreenPreview() {
        if (root.visibility === Window.FullScreen) {
            root.applyWindowGeometry(root.normalGeometry)
        }
    }

    function toggleFullScreenPreview() {
        if (root.visibility === Window.FullScreen) {
            root.exitFullScreenPreview()
        } else {
            root.enterFullScreenPreview()
        }
    }

    function beginTitleBarDrag(localX, localY) {
        if (root.visibility === Window.FullScreen) {
            return false
        }

        var globalX = root.x + localX
        var globalY = root.y + localY
        var grabOffsetX = localX
        var grabOffsetY = localY

        root._dragRestoreGeometry = Qt.rect(root.x, root.y, root.width, root.height)
        if (root.visibility === Window.Maximized) {
            var ratio = root.width > 0 ? Math.max(0.08, Math.min(0.92, localX / root.width)) : 0.5
            root.showNormal()
            root.width = Math.max(root.minimumWidth, root.normalGeometry.width)
            root.height = Math.max(root.minimumHeight, root.normalGeometry.height)
            grabOffsetX = root.width * ratio
            root.x = Math.round(globalX - grabOffsetX)
            root.y = Math.round(globalY - grabOffsetY)
            root._dragRestoreGeometry = Qt.rect(root.x, root.y, root.width, root.height)
        }

        root._windowGestureActive = true
        root._dragStartWindowX = root.x
        root._dragStartWindowY = root.y
        root._dragStartGlobalX = root.x + grabOffsetX
        root._dragStartGlobalY = root.y + grabOffsetY
        root.hideSnapPreview()
        return true
    }

    function updateTitleBarDrag(deltaX, deltaY) {
        if (!root._windowGestureActive) return
        root.x = Math.round(root._dragStartWindowX + deltaX)
        root.y = Math.round(root._dragStartWindowY + deltaY)
        root.updateSnapPreviewForPoint(
            root._dragStartGlobalX + deltaX,
            root._dragStartGlobalY + deltaY
        )
    }

    function finishTitleBarDrag() {
        if (!root._windowGestureActive) return
        var mode = root.snapPreviewMode
        if (mode !== "") {
            root.normalGeometry = root._dragRestoreGeometry
            root.applySnapMode(mode)
            root._windowGestureActive = false
        } else {
            root._windowGestureActive = false
            root.hideSnapPreview()
            root.captureNormalGeometry()
        }
    }

    onXChanged: captureNormalGeometry()
    onYChanged: captureNormalGeometry()
    onWidthChanged: captureNormalGeometry()
    onHeightChanged: captureNormalGeometry()
    onVisibilityChanged: {
        if (root.visibility !== Window.FullScreen) {
            root.hideSnapPreview()
        }
    }

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
            WxTheme.isDark = backend.isDark
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
        function onIsDarkChanged() {
            WxTheme.isDark = backend.isDark
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
            visible: root.visibility !== Window.FullScreen
            z: 100
            window: root
            titleBackend: typeof backend !== "undefined" ? backend : null
        }

        App {
            Layout.fillWidth: true
            Layout.fillHeight: true
            appBackend: typeof backend !== "undefined" ? backend : null
        }
    }

    Shortcut {
        sequence: "F11"
        onActivated: root.toggleFullScreenPreview()
    }

    Shortcut {
        sequence: "Esc"
        enabled: root.visibility === Window.FullScreen
        onActivated: root.exitFullScreenPreview()
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

    Window {
        id: snapPreviewWindow
        x: root.snapPreviewRect.x
        y: root.snapPreviewRect.y
        width: root.snapPreviewRect.width
        height: root.snapPreviewRect.height
        visible: root.snapPreviewMode !== ""
        color: "transparent"
        flags: Qt.ToolTip | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowTransparentForInput
        opacity: visible ? 1.0 : 0.0

        Rectangle {
            anchors.fill: parent
            anchors.margins: 10
            radius: 8
            color: WxTheme.clPrimary
            opacity: 0.18
            border.color: WxTheme.clPrimary
            border.width: 2
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

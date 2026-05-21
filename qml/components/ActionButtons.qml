import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../theme"

Item {
    id: root

    property var btnBackend: null
    property string phase: btnBackend ? btnBackend.phase : "idle"

    signal startRequested()

    height: 32
    implicitHeight: 32
    implicitWidth: {
        switch (phase) {
            case "idle": return _btnWidth
            case "running": return _btnWidth * 2 + WxTheme.spSmall
            case "paused": return _btnWidth * 2 + WxTheme.spSmall
            case "done": return _btnWidth
            default: return _btnWidth
        }
    }

    // 统一按钮宽度（以最长文字"开始发送"为基准）
    property int _btnWidth: 96

    component WxButton: Button {
        id: btn
        property bool isPrimary: false
        property bool isDanger: false

        font.family: WxTheme.fontFamily
        font.pixelSize: WxTheme.fontSizeNormal
        implicitHeight: 32
        implicitWidth: root._btnWidth

        // Bouncy spring scale for visual premium click feel
        scale: btn.pressed ? 0.95 : (btn.hovered ? 1.05 : 1.0)
        Behavior on scale {
            NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
        }

        contentItem: Text {
            text: btn.text
            font: btn.font
            color: isPrimary || isDanger ? "#ffffff" : WxTheme.clTextPrimary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: isPrimary || isDanger ? height / 2 : WxTheme.radiusSmall
            color: {
                if (isDanger) {
                    return btn.hovered ? WxTheme.clDangerNewHover : WxTheme.clDangerNew
                }
                if (isPrimary) {
                    if (btn.pressed) return WxTheme.clPrimaryPress
                    return btn.hovered ? WxTheme.clPrimaryHover : WxTheme.clPrimary
                }
                if (btn.pressed) return WxTheme.clDivider
                return btn.hovered ? WxTheme.clBgSecondary : WxTheme.clBgPrimary
            }
            border.width: isPrimary || isDanger ? 0 : 1
            border.color: WxTheme.clBorder
        }

        padding: 0
    }

    // 使用 StackLayout 按阶段分组，避免按钮切换时布局跳动
    StackLayout {
        id: stack
        anchors.fill: parent
        currentIndex: {
            switch (root.phase) {
                case "idle": return 0
                case "running": return 1
                case "paused": return 2
                case "done": return 3
                default: return 0
            }
        }

        // idle 状态
        Row {
            spacing: WxTheme.spSmall
            WxButton {
                text: "开始发送"
                isPrimary: true
                onClicked: root.startRequested()
            }
        }

        // running 状态
        Row {
            spacing: WxTheme.spSmall
            WxButton {
                text: "暂停"
                onClicked: { if (btnBackend) btnBackend.pause_sending() }
            }
            WxButton {
                text: "停止"
                isDanger: true
                onClicked: { if (btnBackend) btnBackend.stop_sending() }
            }
        }

        // paused 状态
        Row {
            spacing: WxTheme.spSmall
            WxButton {
                text: "继续"
                isPrimary: true
                onClicked: { if (btnBackend) btnBackend.resume_sending() }
            }
            WxButton {
                text: "停止"
                isDanger: true
                onClicked: { if (btnBackend) btnBackend.stop_sending() }
            }
        }

        // done 状态
        Row {
            spacing: WxTheme.spSmall
            WxButton {
                text: "重新开始"
                onClicked: { if (btnBackend) btnBackend.reset() }
            }
        }
    }

    // 淡入淡出动画
    OpacityAnimator {
        id: fadeIn
        target: stack
        from: 0
        to: 1
        duration: WxTheme.animSlow
        easing.type: Easing.OutQuad
    }

    OpacityAnimator {
        id: fadeOut
        target: stack
        from: 1
        to: 0
        duration: WxTheme.animSlow
        easing.type: Easing.InQuad
    }

    onPhaseChanged: {
        // 当 phase 改变时触发淡入淡出
        fadeOut.start()
    }

    Connections {
        target: fadeOut
        function onFinished() {
            // fadeOut 完成后，StackLayout 已经因为 currentIndex 绑定而切换了内容
            fadeIn.start()
        }
    }
}

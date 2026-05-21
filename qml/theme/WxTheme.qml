pragma Singleton
import QtQuick

QtObject {
    // ═══════════════════════════════
    //  颜色 — 微信风格
    // ═══════════════════════════════
    readonly property color clPrimary: "#07c160"
    readonly property color clPrimaryHover: "#06ad56"
    readonly property color clPrimaryPress: "#059a4c"
    readonly property color clBubbleBg: "#95ec69"
    readonly property color clFileCardBg: "#f5f5f5"
    readonly property color clLogOk: "#2e7d32"
    readonly property color clLogErr: "#c62828"
    readonly property color clTextPrimary: "#191919"
    readonly property color clTextSecondary: "#666666"
    readonly property color clTextHint: "#999999"
    readonly property color clBgPrimary: "#ffffff"
    readonly property color clBgSecondary: "#f7f7f7"
    readonly property color clBorder: "#e5e5e5"
    readonly property color clDivider: "#ededed"
    readonly property color clWarningBg: "#fff3e0"
    readonly property color clTooltipBg: "#ffffe0"
    readonly property color clDanger: "#d9534f"
    readonly property color clDangerHover: "#c9302c"

    // ═══════════════════════════════
    //  Phase 2 新增 — 扩展色彩
    // ═══════════════════════════════
    readonly property color clPrimaryDisabled: "#a0e6b9"
    readonly property color clBgWindow: "#f5f5f5"
    readonly property color clBgHover: "#f7f7f7"
    readonly property color clBgSelected: "#e6f7ed"
    readonly property color clBgInput: "#f5f5f5"
    readonly property color clBorderFocus: "#07c160"
    readonly property color clBubbleTail: "#95ec69"
    readonly property color clTextLink: "#576b95"
    readonly property color clToastBg: "#4c4c4c"
    readonly property color clToastText: "#ffffff"
    readonly property color clDangerNew: "#fa5151"
    readonly property color clDangerNewHover: "#f13e3a"
    readonly property color clWarning: "#ffc300"
    readonly property color clShadow: "#000000"

    // ═══════════════════════════════
    //  字体
    // ═══════════════════════════════
    readonly property string fontFamily: "Microsoft YaHei"
    readonly property string fontFamilyLog: "Consolas, Cascadia Code, monospace"
    readonly property int fontSizeNormal: 13
    readonly property int fontSizeSmall: 12
    readonly property int fontSizeTiny: 11
    readonly property int fontSizeLog: 12

    // ═══════════════════════════════
    //  圆角
    // ═══════════════════════════════
    readonly property int radiusSmall: 4
    readonly property int radiusMedium: 6
    readonly property int radiusLarge: 8

    // ═══════════════════════════════
    //  间距
    // ═══════════════════════════════
    readonly property int spTiny: 4
    readonly property int spSmall: 8
    readonly property int spMedium: 12
    readonly property int spLarge: 16

    // ═══════════════════════════════
    //  Phase 2 新增 — 动画时长
    // ═══════════════════════════════
    readonly property int animFast: 80
    readonly property int animNormal: 120
    readonly property int animSlow: 200
    readonly property int animProgress: 300

    // ═══════════════════════════════
    //  Phase 2 新增 — 阴影参数（不透明度百分比）
    // ═══════════════════════════════
    readonly property real shadowOpacityLight: 0.04
    readonly property real shadowOpacityMedium: 0.06
    readonly property real shadowOpacityHeavy: 0.12
    readonly property int shadowOffsetY: 2
    readonly property int shadowBlurLight: 8
    readonly property int shadowBlurMedium: 12
    readonly property int shadowBlurHeavy: 16

    // ═══════════════════════════════
    //  Phase 1 (V4) 新增 — 扩展主题常量
    // ═══════════════════════════════
    readonly property color clChatBg: "#ebebeb"
    readonly property color clTabActive: "#07c160"
    readonly property color clTabInactive: "#999999"
    readonly property color clProgressTrack: "#e9e9e9"
    readonly property color clSwitchTrackOff: "#dcdfe6"
    readonly property color clSwitchThumb: "#ffffff"

    readonly property int fontSizeXSmall: 10
    readonly property int fontSizeTitle: 15

    readonly property int controlHeight: 28
    readonly property int tabHeight: 36
    readonly property int statusBarHeight: 24
    readonly property int actionBarHeight: 40
    readonly property int chatBubbleMaxWidth: 260
    readonly property int chatFileCardMaxWidth: 220
    readonly property int chatFileCardHeight: 44

    readonly property int spXLarge: 20
}

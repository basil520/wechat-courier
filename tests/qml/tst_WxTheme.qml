import QtQuick
import QtTest
import "../../qml/theme"

TestCase {
    name: "WxTheme"

    function test_primary_color() {
        compare(WxTheme.clPrimary, "#07c160")
    }

    function test_primary_hover_color() {
        compare(WxTheme.clPrimaryHover, "#06ad56")
    }

    function test_bubble_bg_color() {
        compare(WxTheme.clBubbleBg, "#95ec69")
    }

    function test_bg_primary_color() {
        compare(WxTheme.clBgPrimary, "#ffffff")
    }

    function test_bg_secondary_color() {
        compare(WxTheme.clBgSecondary, "#f7f7f7")
    }

    function test_text_primary_color() {
        compare(WxTheme.clTextPrimary, "#191919")
    }

    function test_text_hint_color() {
        compare(WxTheme.clTextHint, "#999999")
    }

    function test_danger_color() {
        compare(WxTheme.clDanger, "#d9534f")
    }

    function test_font_family() {
        compare(WxTheme.fontFamily, "Microsoft YaHei")
    }

    function test_font_size_normal() {
        compare(WxTheme.fontSizeNormal, 13)
    }

    function test_font_size_tiny() {
        compare(WxTheme.fontSizeTiny, 11)
    }

    function test_radius_small() {
        compare(WxTheme.radiusSmall, 4)
    }

    function test_radius_large() {
        compare(WxTheme.radiusLarge, 8)
    }

    function test_spacing_small() {
        compare(WxTheme.spSmall, 8)
    }

    function test_spacing_large() {
        compare(WxTheme.spLarge, 16)
    }

    // Phase 2 新增常量测试
    function test_danger_new_color() {
        compare(WxTheme.clDangerNew, "#fa5151")
    }

    function test_bg_input_color() {
        compare(WxTheme.clBgInput, "#f5f5f5")
    }

    function test_toast_bg_color() {
        compare(WxTheme.clToastBg, "#4c4c4c")
    }

    function test_anim_fast() {
        compare(WxTheme.animFast, 80)
    }

    function test_anim_slow() {
        compare(WxTheme.animSlow, 200)
    }

    function test_shadow_opacity_medium() {
        compare(WxTheme.shadowOpacityMedium, 0.06)
    }
}

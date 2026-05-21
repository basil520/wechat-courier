import QtQuick
import QtTest
import "../../qml/components"
import "../../qml/theme"

TestCase {
    name: "WxTitleBar"

    QtObject {
        id: mockBackend
        property bool glassEnabled: true
        property int glassOpacity: 72
        function showToast(message, type) {}
    }

    WxTitleBar {
        id: titleBar
        width: 640
        titleBackend: mockBackend
    }

    function cleanup() {
        WxTheme.glassEnabled = true
        WxTheme.glassOpacity = 72
        mockBackend.glassEnabled = true
        mockBackend.glassOpacity = 72
    }

    function test_titlebar_height() {
        compare(titleBar.height, 40)
    }

    function test_glass_enabled_updates_backend_and_theme() {
        titleBar.setGlassEnabled(false)

        compare(WxTheme.glassEnabled, false)
        compare(mockBackend.glassEnabled, false)
    }

    function test_glass_opacity_clamps_to_supported_range() {
        titleBar.setGlassOpacity(10, false)
        compare(WxTheme.glassOpacity, 45)
        compare(mockBackend.glassOpacity, 45)

        titleBar.setGlassOpacity(95, false)
        compare(WxTheme.glassOpacity, 90)
        compare(mockBackend.glassOpacity, 90)
    }
}

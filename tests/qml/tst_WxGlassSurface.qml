import QtQuick
import QtTest
import "../../qml/components"
import "../../qml/theme"

TestCase {
    name: "WxGlassSurface"

    function test_surface_can_be_created_with_material_tokens() {
        var component = Qt.createComponent("../../qml/components/WxGlassSurface.qml")
        compare(component.status, Component.Ready, component.errorString())

        var surface = component.createObject(null, {
            "fillColor": WxTheme.clFieldFill,
            "borderColor": WxTheme.clSurfaceBorder,
            "focused": true
        })

        verify(surface !== null)
        compare(surface.fillColor, WxTheme.clFieldFill)
        compare(surface.borderColor, WxTheme.clSurfaceBorder)
        compare(surface.focused, true)
        surface.destroy()
    }
}

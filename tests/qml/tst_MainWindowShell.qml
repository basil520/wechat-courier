import QtQuick
import QtQuick.Window
import QtTest

TestCase {
    name: "MainWindowShell"

    function test_main_qml_loads_with_frameless_flag() {
        var component = Qt.createComponent("../../qml/main.qml")
        compare(component.status, Component.Ready, component.errorString())

        var windowObject = component.createObject(null)
        verify(windowObject !== null)
        verify((windowObject.flags & Qt.FramelessWindowHint) !== 0)

        windowObject.destroy()
    }
}

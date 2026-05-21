import QtQuick
import QtQuick.Layouts
import "components"
import "theme"

Rectangle {
    // backend 从 main.qml 传入
    property var appBackend: null

    color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        MainLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            mainBackend: appBackend
        }

        StatusBar {
            Layout.fillWidth: true
            compBackend: appBackend
        }
    }
}

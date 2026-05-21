import QtQuick
import QtQuick.Layouts
import "components"
import "theme"

Rectangle {
    // backend 从 main.qml 传入
    property var appBackend: null

    color: WxTheme.clBgPrimary

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        StatusBar {
            Layout.fillWidth: true
            compBackend: appBackend
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: WxTheme.clDivider
        }

        MainLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            mainBackend: appBackend
        }
    }
}

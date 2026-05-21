import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    // backend 从 App.qml 传入
    property var mainBackend: null

    color: WxTheme.clBgPrimary

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 上半部分：左右分栏 (6:4 比例)
        RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: WxTheme.spLarge
        spacing: WxTheme.spLarge

        InputPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 200
            panelBackend: mainBackend
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: WxTheme.clDivider
        }

        PreviewPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 150
            panelBackend: mainBackend
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: WxTheme.clDivider
    }

    ProgressPanel {
        Layout.fillWidth: true
        Layout.preferredHeight: 180
        Layout.margins: WxTheme.spLarge
        panelBackend: mainBackend
    }
    }
}

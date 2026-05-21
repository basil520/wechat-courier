import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: root

    property var tabs: ["Tab 1", "Tab 2"]
    property int currentIndex: 0
    property bool showNotificationDot: false

    signal tabClicked(int index)

    implicitHeight: WxTheme.tabHeight
    color: "transparent"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: root.tabs

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Tab 文字 + 通知点
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: WxTheme.fontFamily
                            font.pixelSize: WxTheme.fontSizeSmall
                            font.bold: root.currentIndex === index
                            color: root.currentIndex === index ? WxTheme.clTextPrimary : WxTheme.clTabInactive
                        }

                        // 通知圆点
                        Rectangle {
                            anchors.left: parent.horizontalCenter
                            anchors.leftMargin: modelData.length * 6 + 4
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6
                            height: 6
                            radius: 3
                            color: WxTheme.clDangerNew
                            visible: root.showNotificationDot && index === 1 && root.currentIndex !== 1
                        }
                    }

                    // 底部指示器
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 2
                        color: root.currentIndex === index ? WxTheme.clTabActive : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: WxTheme.animNormal }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.currentIndex !== index) {
                            root.tabClicked(index)
                        }
                    }
                }
            }
        }
    }
}

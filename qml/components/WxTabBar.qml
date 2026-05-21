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

    // Bottom border line for the entire tab bar to match WeChat style
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: WxTheme.clDivider
        z: -1
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Container for tabs with dynamic sliding underline
        Item {
            id: tabsContainer
            Layout.preferredWidth: root.tabs.length * 100
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Repeater {
                    model: root.tabs

                    Item {
                        Layout.preferredWidth: 100
                        Layout.fillHeight: true

                        // Tab Text + Notification Red Dot
                        Item {
                            anchors.fill: parent

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: WxTheme.fontFamily
                                font.pixelSize: WxTheme.fontSizeSmall
                                font.bold: root.currentIndex === index
                                color: root.currentIndex === index ? WxTheme.clTextPrimary : WxTheme.clTabInactive

                                Behavior on color {
                                    ColorAnimation { duration: WxTheme.animNormal }
                                }
                            }

                            // Notification Dot
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

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.currentIndex !== index) {
                                    root.tabClicked(index)
                                }
                            }
                        }
                    }
                }
            }

            // Sliding indicator line at the bottom
            Rectangle {
                id: indicatorLine
                anchors.bottom: parent.bottom
                height: 2
                width: 100
                color: WxTheme.clTabActive
                x: root.currentIndex * 100

                Behavior on x {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutQuint
                    }
                }
            }
        }

        // Spacer to push the theme toggle button to the far right
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // Theme Toggle Button
        Item {
            Layout.preferredWidth: 40
            Layout.fillHeight: true

            Rectangle {
                id: themeToggleBtn
                anchors.centerIn: parent
                width: 28
                height: 28
                radius: 14
                color: WxTheme.isDark ? "#2c313a" : "#f0f2f5"
                border.color: WxTheme.clBorder
                border.width: 1

                scale: hoverArea.containsMouse ? 1.1 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                }

                WxIcon {
                    id: themeIcon
                    anchors.centerIn: parent
                    iconSource: WxTheme.isDark ? "../icons/sun.svg" : "../icons/moon.svg"
                    iconColor: WxTheme.isDark ? "#ffc300" : "#666666"
                    hoverColor: WxTheme.isDark ? "#ffd600" : "#07c160"
                    iconSize: 16
                    hoverScale: false // Handled by parent scale

                    Behavior on rotation {
                        NumberAnimation { duration: 350; easing.type: Easing.OutQuint }
                    }
                }

                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        themeIcon.rotation += 360
                        WxTheme.isDark = !WxTheme.isDark
                    }
                }
            }
        }
    }
}


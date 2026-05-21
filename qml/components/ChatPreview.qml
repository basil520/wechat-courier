import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../theme"

Rectangle {
    id: root

    property var panelBackend: null

    color: WxTheme.clChatBg

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── 1. 顶部微信风格标题栏 ──
        Rectangle {
            id: mockHeader
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: WxTheme.clBgPrimary

            // Bottom Divider
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: WxTheme.clDivider
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 8

                Text {
                    text: panelBackend && panelBackend.previewFriend !== "" 
                        ? panelBackend.previewFriend 
                        : "微信消息预览"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeTitle
                    font.bold: true
                    color: WxTheme.clTextPrimary
                    Layout.fillWidth: true
                }

                // Options triple-dots icon
                WxIcon {
                    iconSource: "../icons/settings.svg"
                    iconSize: 18
                    iconColor: WxTheme.clTextSecondary
                    hoverColor: WxTheme.clPrimary
                }
            }
        }

        // ── 2. 聊天记录区 ──
        Flickable {
            id: chatFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: chatColumn.height

            // Scroll indicator style
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            Column {
                id: chatColumn
                width: parent.width
                spacing: WxTheme.spMedium

                // Date Label
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        var now = new Date()
                        return now.getFullYear() + "年" + (now.getMonth() + 1) + "月" + now.getDate() + "日"
                    }
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeTiny
                    color: WxTheme.clTextHint
                    topPadding: WxTheme.spLarge
                }

                // Empty State when no target friend selected
                EmptyState {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !panelBackend || panelBackend.previewFriend === ""
                    iconSource: "../icons/chat_empty.svg"
                    title: "暂无消息预览"
                    subtitle: "请在左侧添加好友并编写模板"
                }

                // Text Bubble (Outgoing, right-aligned)
                Row {
                    width: chatColumn.width
                    visible: panelBackend ? (panelBackend.previewFriend !== "" && panelBackend.previewMessage !== "") : false
                    layoutDirection: Qt.RightToLeft
                    spacing: 0
                    rightPadding: 16
                    leftPadding: 16

                    WeChatBubble {
                        isOutgoing: true
                        messageText: panelBackend ? panelBackend.previewMessage : ""
                        isError: {
                            if (!panelBackend) return false
                            var msg = panelBackend.previewMessage
                            return msg.indexOf("格式有误") >= 0 || msg.indexOf("请在左侧输入") >= 0
                        }
                    }
                }

                // File Cards (Outgoing, right-aligned)
                Repeater {
                    model: panelBackend ? panelBackend.previewFileNames : []
                    delegate: Row {
                        width: chatColumn.width
                        visible: panelBackend ? panelBackend.previewFriend !== "" : false
                        layoutDirection: Qt.RightToLeft
                        spacing: 0
                        rightPadding: 16
                        leftPadding: 16

                        WxChatFileCard {
                            fileName: typeof modelData === "string" ? modelData : ""
                            fileType: {
                                var name = fileName.toLowerCase()
                                if (name.endsWith(".pdf")) return "pdf"
                                if (/\.(jpg|jpeg|png|gif|bmp|webp)$/.test(name)) return "image"
                                if (/\.(doc|docx)$/.test(name)) return "doc"
                                if (/\.(xls|xlsx)$/.test(name)) return "xls"
                                return "other"
                            }
                        }
                    }
                }

                Item { height: WxTheme.spMedium }
            }
        }

        // ── 3. 模拟底部输入框 ──
        Rectangle {
            id: mockInputArea
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            color: WxTheme.isDark ? "#1c2024" : "#f5f5f5"

            // Top Border line
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: WxTheme.clDivider
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4

                // Simulated toolbar
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20
                    spacing: 16

                    WxIcon {
                        iconSource: "../icons/chat_empty.svg"
                        iconSize: 16
                        iconColor: WxTheme.clTextSecondary
                        hoverColor: WxTheme.clPrimary
                    }

                    WxIcon {
                        iconSource: "../icons/folder_open.svg"
                        iconSize: 16
                        iconColor: WxTheme.clTextSecondary
                        hoverColor: WxTheme.clPrimary
                    }

                    WxIcon {
                        iconSource: "../icons/file.svg"
                        iconSize: 16
                        iconColor: WxTheme.clTextSecondary
                        hoverColor: WxTheme.clPrimary
                    }

                    WxIcon {
                        iconSource: "../icons/clock.svg"
                        iconSize: 16
                        iconColor: WxTheme.clTextSecondary
                        hoverColor: WxTheme.clPrimary
                    }

                    Item { Layout.fillWidth: true }
                }

                // Middle Mock text field displaying greeting & stats
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Column {
                        anchors.fill: parent
                        spacing: 2

                        Text {
                            text: panelBackend && panelBackend.previewFriend !== ""
                                ? "目标好友: " + panelBackend.previewFriend + "  |  称呼变量: " + (panelBackend.previewGreeting || "[无]")
                                : "等待在左侧选择好友..."
                            font.family: WxTheme.fontFamily
                            font.pixelSize: WxTheme.fontSizeTiny
                            font.bold: true
                            color: WxTheme.clPrimary
                        }

                        Text {
                            text: "预览消息内容和附件如上。实际群发时，程序将循环此界面进行全自动安全投递。"
                            font.family: WxTheme.fontFamily
                            font.pixelSize: WxTheme.fontSizeTiny
                            color: WxTheme.clTextSecondary
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                    }
                }

                // Bottom row with Send Button
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 64
                        height: 24
                        radius: 4
                        color: panelBackend && panelBackend.previewFriend !== "" ? WxTheme.clPrimary : (WxTheme.isDark ? "#282d35" : "#e9e9e9")
                        border.color: WxTheme.clBorder
                        border.width: 1

                        scale: hoverArea.containsMouse ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "发送(S)"
                            font.family: WxTheme.fontFamily
                            font.pixelSize: WxTheme.fontSizeTiny
                            font.bold: true
                            color: panelBackend && panelBackend.previewFriend !== "" ? "#ffffff" : WxTheme.clTextHint
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: panelBackend && panelBackend.previewFriend !== ""
                            cursorShape: panelBackend && panelBackend.previewFriend !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                        }
                    }
                }
            }
        }
    }
}

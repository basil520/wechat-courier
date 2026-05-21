import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../theme"

Rectangle {
    id: root

    property var panelBackend: null

    color: WxTheme.clPanelFill

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── 1. 顶部微信风格标题栏 ──
        WxGlassSurface {
            id: mockHeader
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: 0
            fillColor: WxTheme.clToolbarFill
            borderColor: "transparent"
            highlightEnabled: true

            // Bottom Divider
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: WxTheme.clSurfaceBorder
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 8

                // Clickable Area for Title Selector
                Item {
                    id: titleClickContainer
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    RowLayout {
                        id: clickableTitleRow
                        anchors.fill: parent
                        spacing: 4

                        Text {
                            text: panelBackend && panelBackend.previewFriend !== "" 
                                ? panelBackend.previewFriend 
                                : "微信消息预览"
                            font.family: WxTheme.fontFamily
                            font.pixelSize: WxTheme.fontSizeTitle
                            font.bold: true
                            color: WxTheme.clTextPrimary
                            elide: Text.ElideRight
                            Layout.maximumWidth: parent.width - 48
                        }

                        // Emerald green small down arrow icon if selectable
                        Text {
                            text: "▾"
                            font.pixelSize: 16
                            color: WxTheme.clPrimary
                            font.bold: true
                            visible: panelBackend && panelBackend.previewFriend !== ""
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: panelBackend && panelBackend.previewFriend !== ""
                        hoverEnabled: enabled
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            previewSelectorPopup.open()
                        }
                    }
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
        WxGlassSurface {
            id: mockInputArea
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            radius: 0
            fillColor: WxTheme.clToolbarFill
            borderColor: "transparent"
            highlightEnabled: true

            // Top Border line
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: WxTheme.clSurfaceBorder
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

    // ── 4. 预览好友选择弹窗 (Preview Contact Selector Popup) ──
    Popup {
        id: previewSelectorPopup
        y: mockHeader.height + 4
        x: 16
        width: Math.min(240, parent.width - 32)
        height: Math.min(220, friendSelectionList.count * 32 + 50)
        padding: 8
        modal: false
        focus: true

        background: WxGlassSurface {
            fillColor: WxTheme.clPanelFill
            borderColor: WxTheme.clSurfaceBorder
            radius: WxTheme.radiusMedium
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            Text {
                text: "选择要预览的好友"
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeTiny
                font.bold: true
                color: WxTheme.clTextHint
                Layout.leftMargin: 8
                Layout.topMargin: 4
            }

            ListView {
                id: friendSelectionList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(150, friendSelectionList.count * 32)
                clip: true
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                model: {
                    if (!panelBackend || panelBackend.friendListText.trim() === "") return []
                    var lines = panelBackend.friendListText.split("\n")
                    var list = []
                    for (var i = 0; i < lines.length; i++) {
                        var cleaned = lines[i].trim()
                        if (cleaned !== "") {
                            list.push({ "name": cleaned, "index": i })
                        }
                    }
                    return list
                }

                delegate: Rectangle {
                    width: friendSelectionList.width
                    height: 32
                    radius: WxTheme.radiusSmall
                    color: modelData.index === (panelBackend ? panelBackend.previewIndex : 0)
                        ? WxTheme.clBgSelected
                        : (mouseArea.containsMouse ? WxTheme.clBgHover : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        Text {
                            text: modelData.name
                            font.family: WxTheme.fontFamily
                            font.pixelSize: WxTheme.fontSizeNormal - 1
                            font.bold: modelData.index === (panelBackend ? panelBackend.previewIndex : 0)
                            color: modelData.index === (panelBackend ? panelBackend.previewIndex : 0)
                                ? WxTheme.clPrimary
                                : WxTheme.clTextPrimary
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: WxTheme.clPrimary
                            visible: modelData.index === (panelBackend ? panelBackend.previewIndex : 0)
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (panelBackend) {
                                panelBackend.previewIndex = modelData.index
                            }
                            previewSelectorPopup.close()
                        }
                    }
                }
            }
        }
    }
}

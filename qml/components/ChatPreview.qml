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

        // ── 聊天区 ──
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: chatColumn.height

            Column {
                id: chatColumn
                width: parent.width
                spacing: WxTheme.spMedium

                // 日期标签
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

                // 空状态
                EmptyState {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !panelBackend || panelBackend.previewFriend === ""
                    iconSource: "../icons/chat_empty.svg"
                    title: "暂无预览内容"
                    subtitle: "请在左侧输入名单和模板"
                }

                // 消息气泡（右对齐，我发出的）
                Row {
                    width: parent.width
                    visible: panelBackend ? panelBackend.previewFriend !== "" : false
                    layoutDirection: Qt.RightToLeft
                    spacing: 0

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

                // 文件卡片列表（右对齐，嵌入对话流）
                Repeater {
                    model: panelBackend ? panelBackend.previewFileNames : []
                    delegate: Row {
                        width: chatColumn.width
                        visible: panelBackend ? panelBackend.previewFriend !== "" : false
                        layoutDirection: Qt.RightToLeft
                        spacing: 0

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

        // ── 底部好友信息 ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: WxTheme.clBgPrimary

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: WxTheme.spMedium
                anchors.rightMargin: WxTheme.spMedium
                spacing: WxTheme.spSmall

                Text {
                    text: "目标好友:"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeTiny
                    color: WxTheme.clTextHint
                }

                Text {
                    text: panelBackend ? panelBackend.previewFriend : ""
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeTiny
                    color: WxTheme.clTextSecondary
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "称呼:"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeTiny
                    color: WxTheme.clTextHint
                }

                Text {
                    text: panelBackend ? panelBackend.previewGreeting : ""
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeTiny
                    color: WxTheme.clTextSecondary
                }
            }
        }
    }
}

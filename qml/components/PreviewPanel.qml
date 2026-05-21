import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../theme"

Rectangle {
    id: root

    property var panelBackend: null

    color: WxTheme.clBgPrimary

    ColumnLayout {
        anchors.fill: parent
        spacing: WxTheme.spSmall

        // ── 面板标题 ──
        Text {
            text: "效果预览"
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeNormal
            font.bold: true
            color: WxTheme.clTextPrimary
        }

        Text {
            text: "发送给名单中第一个联系人的消息效果："
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeSmall
            color: WxTheme.clTextSecondary
        }

        // ── 目标好友 + 称呼 ──
        RowLayout {
            spacing: WxTheme.spSmall
            Text {
                text: "目标好友:"
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeNormal
                color: WxTheme.clTextSecondary
            }
            Text {
                text: panelBackend ? panelBackend.previewFriend : ""
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeNormal
                color: WxTheme.clTextPrimary
            }
            Text {
                text: "提取称呼:"
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeNormal
                color: WxTheme.clTextSecondary
            }
            Text {
                text: panelBackend ? panelBackend.previewGreeting : ""
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeNormal
                color: WxTheme.clTextPrimary
            }
        }

        // ── 预览区 ──
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width - 4
                spacing: WxTheme.spMedium

                // 空状态
                EmptyState {
                    visible: !panelBackend || panelBackend.previewFriend === ""
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    iconText: "💬"
                    title: "暂无预览内容"
                    subtitle: "请在左侧输入名单和模板"
                }

                // 消息气泡
                WeChatBubble {
                    visible: panelBackend ? panelBackend.previewFriend !== "" : false
                    messageText: panelBackend ? panelBackend.previewMessage : ""
                    isError: {
                        if (!panelBackend) return false
                        var msg = panelBackend.previewMessage
                        return msg.indexOf("格式有误") >= 0 || msg.indexOf("请在左侧输入") >= 0
                    }
                }

                // 多文件合并提示
                Rectangle {
                    Layout.fillWidth: true
                    visible: panelBackend ? panelBackend.previewFileCount > 1 : false
                    implicitHeight: visible ? mergeHintText.implicitHeight + 16 : 0

                    Text {
                        id: mergeHintText
                        anchors.centerIn: parent
                        text: panelBackend ? "共 " + panelBackend.previewFileCount + " 个文件，将合并发送" : ""
                        font.family: WxTheme.fontFamily
                        font.pixelSize: WxTheme.fontSizeSmall
                        color: WxTheme.clTextHint
                    }
                }

                // 文件卡片列表
                Repeater {
                    model: panelBackend ? panelBackend.previewFileNames : []
                    delegate: WeChatFileCard {
                        Layout.fillWidth: true
                        fileName: typeof modelData === "string" ? modelData : ""
                        fileSize: ""
                        fileType: {
                            var name = fileName.toLowerCase()
                            if (name.endsWith(".pdf")) return "pdf"
                            if (/\.(jpg|jpeg|png|gif|bmp|webp)$/.test(name)) return "image"
                            if (/\.(doc|docx|txt|xls|xlsx|ppt|pptx)$/.test(name)) return "doc"
                            return "other"
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}

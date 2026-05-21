import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import "../theme"

Rectangle {
    id: root

    property var panelBackend: null

    color: WxTheme.clBgPrimary

    // 计算好友数（非空行）
    property int _friendCount: {
        if (!panelBackend) return 0
        var lines = panelBackend.friendListText.split("\n")
        var count = 0
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].trim() !== "") count++
        }
        return count
    }

    // 计算文件数
    property int _fileCount: panelBackend ? panelBackend.filePaths.length : 0

    ColumnLayout {
        anchors.fill: parent
        spacing: WxTheme.spSmall

        // ── 面板标题 ──
        Text {
            text: "编辑发送内容"
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeNormal
            font.bold: true
            color: WxTheme.clTextPrimary
        }

        // ── 好友名单 ──
        Text {
            text: "接收好友名单（每行一个）"
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeSmall
            color: WxTheme.clTextSecondary
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            Layout.minimumHeight: 40
            clip: true

            TextArea {
                id: friendsInput
                text: panelBackend ? panelBackend.friendListText : ""
                onTextChanged: {
                    if (panelBackend) panelBackend.friendListText = text
                    if (friendListError.text !== "" && text.trim() !== "") {
                        friendListError.text = ""
                    }
                }
                enabled: panelBackend ? panelBackend.inputsEnabled : false
                placeholderText: "25届初二-郑子轩妈妈\n张永琪爸爸\n王小明"
                placeholderTextColor: WxTheme.clTextHint
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeNormal
                color: enabled ? WxTheme.clTextPrimary : WxTheme.clTextSecondary
                wrapMode: TextArea.Wrap
                background: Rectangle {
                    radius: WxTheme.radiusMedium
                    border.width: 1
                    border.color: friendListError.text !== "" ? WxTheme.clDangerNew
                        : (friendsInput.activeFocus ? WxTheme.clPrimary : WxTheme.clBorder)
                    color: WxTheme.clBgPrimary
                }
                padding: 10
            }
        }

        // 好友名单错误提示
        Text {
            id: friendListError
            text: ""
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeSmall
            color: WxTheme.clDangerNew
            visible: text !== ""
        }

        // ── 消息模板 ──
        Text {
            text: "消息模板（{name} 占位符）"
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeSmall
            color: WxTheme.clTextSecondary
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            Layout.minimumHeight: 30
            clip: true

            TextArea {
                id: templateInput
                text: panelBackend ? panelBackend.templateText : ""
                onTextChanged: {
                    if (panelBackend) panelBackend.templateText = text
                    if (templateError.text !== "" && text.trim() !== "") {
                        templateError.text = ""
                    }
                }
                enabled: panelBackend ? panelBackend.inputsEnabled : false
                placeholderText: "{name}，您好！\n\n（请在此处输入您的自定义消息内容...）"
                placeholderTextColor: WxTheme.clTextHint
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeNormal
                color: enabled ? WxTheme.clTextPrimary : WxTheme.clTextSecondary
                wrapMode: TextArea.Wrap
                background: Rectangle {
                    radius: WxTheme.radiusMedium
                    border.width: 1
                    border.color: templateError.text !== "" ? WxTheme.clDangerNew
                        : (templateInput.activeFocus ? WxTheme.clPrimary : WxTheme.clBorder)
                    color: WxTheme.clBgPrimary
                }
                padding: 10
            }
        }

        // 模板错误提示
        Text {
            id: templateError
            text: ""
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeSmall
            color: WxTheme.clDangerNew
            visible: text !== ""
        }

        // ── 文件选择 ──
        RowLayout {
            Layout.fillWidth: true
            spacing: WxTheme.spSmall

            Text {
                text: "附加文件:"
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeSmall
                color: WxTheme.clTextSecondary
            }

            Button {
                text: "选择文件..."
                enabled: panelBackend ? panelBackend.inputsEnabled : false
                onClicked: fileDialog.open()

                contentItem: Text {
                    text: parent.text
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeSmall
                    color: WxTheme.clTextPrimary
                }

                background: Rectangle {
                    radius: WxTheme.radiusSmall
                    border.width: 1
                    border.color: WxTheme.clBorder
                    color: parent.hovered ? WxTheme.clBgSecondary : WxTheme.clBgPrimary
                }
                padding: 8
            }

            FileDialog {
                id: fileDialog
                title: "选择要发送的文件"
                fileMode: FileDialog.OpenFiles
                onAccepted: {
                    if (panelBackend) {
                        for (var i = 0; i < fileDialog.selectedFiles.length; i++) {
                            panelBackend.add_file_path("file:///" + fileDialog.selectedFiles[i])
                        }
                    }
                }
            }
        }

        // 文件列表（带独立删除）
        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(fileListView.contentHeight, 160)
            Layout.minimumHeight: 0
            visible: fileListView.count > 0
            clip: true

            ListView {
                id: fileListView
                width: parent.width
                height: contentHeight
                model: panelBackend ? panelBackend.filePathModel : null
                spacing: WxTheme.spTiny

                delegate: FileItem {
                    width: ListView.view.width
                    fileName: {
                        var p = (typeof model.display === "string") ? model.display : ""
                        return p.split("/").pop().split("\\").pop()
                    }
                    fileSize: panelBackend && panelBackend.fileSizes.length > index
                              ? panelBackend.fileSizes[index] : ""
                    fileType: {
                        var name = fileName.toLowerCase()
                        if (name.endsWith(".pdf")) return "pdf"
                        if (/\.(jpg|jpeg|png|gif|bmp|webp)$/.test(name)) return "image"
                        if (/\.(doc|docx|txt|xls|xlsx|ppt|pptx)$/.test(name)) return "doc"
                        return "other"
                    }
                    fileIndex: index
                    onRemoveRequested: function(idx) {
                        if (panelBackend) panelBackend.remove_file_at(idx)
                    }
                }
            }
        }

        // 空文件提示
        Text {
            visible: !fileListView.visible
            text: "尚未选择文件"
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeSmall
            color: WxTheme.clTextHint
            Layout.leftMargin: WxTheme.spSmall
        }

        // ── 转发模式 ──
        RowLayout {
            Layout.fillWidth: true
            spacing: WxTheme.spTiny

            CheckBox {
                id: forwardCheck
                checked: panelBackend ? panelBackend.useForward : false
                onCheckedChanged: { if (panelBackend) panelBackend.useForward = checked }
                enabled: panelBackend ? panelBackend.inputsEnabled : false

                indicator: Rectangle {
                    implicitWidth: 16
                    implicitHeight: 16
                    radius: WxTheme.radiusSmall
                    border.width: 1
                    border.color: forwardCheck.checked ? WxTheme.clPrimary : WxTheme.clBorder
                    color: forwardCheck.checked ? WxTheme.clPrimary : WxTheme.clBgPrimary

                    Text {
                        visible: forwardCheck.checked
                        anchors.centerIn: parent
                        text: "✓"
                        color: "#ffffff"
                        font.pixelSize: 10
                    }
                }

                contentItem: Text {
                    text: "通过『文件传输助手』转发（先上传 1 次，后续好友走合并转发）"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeTiny
                    color: WxTheme.clTextSecondary
                    leftPadding: forwardCheck.indicator.width + 4
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Text {
                text: "  ?"
                font.family: WxTheme.fontFamily
                font.pixelSize: WxTheme.fontSizeSmall
                color: WxTheme.clTextHint

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: tooltip.visible = true
                    onExited: tooltip.visible = false
                }

                ToolTip {
                    id: tooltip
                    visible: false
                    delay: 300
                    text: "勾选后：文件先发到文件传输助手，每个好友通过「多选-合并转发」分发，\n对每位好友只需 1 次对话框操作，文案作为留言一起送达。\n未勾选则每个好友都重新打开聊天+重新上传文件。"
                }
            }
        }

        // ── 按钮组 ──
        ActionButtons {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            Layout.minimumHeight: 32
            btnBackend: panelBackend
            onStartRequested: {
                // 输入校验
                var hasError = false
                if (friendsInput.text.trim() === "") {
                    friendListError.text = "请输入好友名单"
                    hasError = true
                }
                if (templateInput.text.trim() === "") {
                    templateError.text = "请输入消息模板"
                    hasError = true
                }
                if (hasError) return

                // 弹出确认对话框
                sendConfirmDialog.open()
            }
        }

        Item { Layout.fillHeight: true }
    }

    // 文件列表刷新
    Connections {
        target: panelBackend
        function onFilePathsChanged() {
            fileListView.forceLayout()
        }
    }

    // 发送确认对话框
    ConfirmDialog {
        id: sendConfirmDialog
        message: "即将向 " + root._friendCount + " 位好友发送消息"
               + (root._fileCount > 0 ? "，共 " + root._fileCount + " 个文件" : "")
               + "。是否继续？"
        confirmText: "确认发送"
        cancelText: "取消"
        onConfirmed: {
            if (panelBackend) panelBackend.start_sending()
        }
    }
}

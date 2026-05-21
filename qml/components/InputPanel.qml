import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import "../theme"

Rectangle {
    id: root

    property var panelBackend: null

    // Calculate count of valid friends (non-empty lines)
    property int _friendCount: {
        if (!panelBackend) return 0
        var lines = panelBackend.friendListText.split("\n")
        var count = 0
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].trim() !== "") count++
        }
        return count
    }

    // Calculate count of attached files
    property int _fileCount: panelBackend ? panelBackend.filePaths.length : 0

    color: WxTheme.clBgPrimary

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: WxTheme.spLarge
        spacing: WxTheme.spSmall

        // ═══════════════════════════════
        //  1. 固定头部 (Fixed Header)
        // ═══════════════════════════════
        Text {
            text: "编辑发送内容"
            font.family: WxTheme.fontFamily
            font.pixelSize: WxTheme.fontSizeNormal + 1
            font.bold: true
            color: WxTheme.clTextPrimary
            Layout.fillWidth: true
        }

        // ═══════════════════════════════
        //  2. 局部滚动区 (Scrollable Inputs)
        // ═══════════════════════════════
        ScrollView {
            id: contentScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: contentScroll.availableWidth - 4
                spacing: WxTheme.spSmall

                // ── 好友名单 ──
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "接收好友名单（每行一个）"
                        font.family: WxTheme.fontFamily
                        font.pixelSize: WxTheme.fontSizeSmall
                        font.bold: true
                        color: WxTheme.clTextSecondary
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root._friendCount > 0 ? root._friendCount + " 位好友" : ""
                        font.family: WxTheme.fontFamily
                        font.pixelSize: WxTheme.fontSizeTiny
                        color: WxTheme.clPrimary
                    }
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    Layout.minimumHeight: 60
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
                        padding: 10

                        // Focus glow ring background
                        background: Rectangle {
                            id: friendsBg
                            radius: WxTheme.radiusMedium
                            border.width: friendsInput.activeFocus ? 1.5 : 1
                            border.color: friendListError.text !== "" ? WxTheme.clDangerNew
                                : (friendsInput.activeFocus ? WxTheme.clPrimary : WxTheme.clBorder)
                            color: WxTheme.clBgPrimary

                            // Soft radial glow ring
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -3
                                radius: friendsBg.radius + 3
                                color: "transparent"
                                border.color: friendListError.text !== "" ? WxTheme.clDangerNew : WxTheme.clPrimary
                                border.width: 3
                                
                                property real pulseOpacity: 0.25
                                opacity: friendsInput.activeFocus ? pulseOpacity : 0.0
                                
                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }
                                
                                SequentialAnimation on pulseOpacity {
                                    running: friendsInput.activeFocus
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0.15; to: 0.35; duration: 1500; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: 0.35; to: 0.15; duration: 1500; easing.type: Easing.InOutSine }
                                }
                            }
                        }

                        // Connect right-click custom context menu
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    friendsInput.forceActiveFocus()
                                    friendsContextMenu.popup()
                                }
                            }
                        }
                    }
                }

                // Friends Error
                Text {
                    id: friendListError
                    text: ""
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeSmall
                    color: WxTheme.clDangerNew
                    visible: text !== ""
                    Layout.fillWidth: true
                }

                // ── 消息模板 ──
                Text {
                    text: "消息模板（使用 {name} 占位符）"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeSmall
                    font.bold: true
                    color: WxTheme.clTextSecondary
                    Layout.fillWidth: true
                }

                TemplateToolbar {
                    Layout.fillWidth: true
                    charCount: templateInput.text.length
                    onInsertRequested: function(placeholderText) {
                        templateInput.insert(templateInput.cursorPosition, placeholderText)
                        templateInput.forceActiveFocus()
                    }
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    Layout.minimumHeight: 50
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
                        padding: 10

                        // Focus glow ring background
                        background: Rectangle {
                            id: templateBg
                            radius: WxTheme.radiusMedium
                            border.width: templateInput.activeFocus ? 1.5 : 1
                            border.color: templateError.text !== "" ? WxTheme.clDangerNew
                                : (templateInput.activeFocus ? WxTheme.clPrimary : WxTheme.clBorder)
                            color: WxTheme.clBgPrimary

                            // Soft radial glow ring
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -3
                                radius: templateBg.radius + 3
                                color: "transparent"
                                border.color: templateError.text !== "" ? WxTheme.clDangerNew : WxTheme.clPrimary
                                border.width: 3
                                
                                property real pulseOpacity: 0.25
                                opacity: templateInput.activeFocus ? pulseOpacity : 0.0
                                
                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }
                                
                                SequentialAnimation on pulseOpacity {
                                    running: templateInput.activeFocus
                                    loops: Animation.Infinite
                                    NumberAnimation { from: 0.15; to: 0.35; duration: 1500; easing.type: Easing.InOutSine }
                                    NumberAnimation { from: 0.35; to: 0.15; duration: 1500; easing.type: Easing.InOutSine }
                                }
                            }
                        }

                        // Connect right-click custom context menu
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    templateInput.forceActiveFocus()
                                    templateContextMenu.popup()
                                }
                            }
                        }
                    }
                }

                // Template Error
                Text {
                    id: templateError
                    text: ""
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeSmall
                    color: WxTheme.clDangerNew
                    visible: text !== ""
                    Layout.fillWidth: true
                }

                // ── 文件选择 ──
                RowLayout {
                    Layout.fillWidth: true
                    spacing: WxTheme.spSmall

                    Text {
                        text: "附加文件列表"
                        font.family: WxTheme.fontFamily
                        font.pixelSize: WxTheme.fontSizeSmall
                        font.bold: true
                        color: WxTheme.clTextSecondary
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "+ 选择文件"
                        enabled: panelBackend ? panelBackend.inputsEnabled : false
                        onClicked: fileDialog.open()

                        contentItem: Text {
                            text: parent.text
                            font.family: WxTheme.fontFamily
                            font.pixelSize: WxTheme.fontSizeSmall
                            font.bold: true
                            color: parent.enabled ? WxTheme.clPrimary : WxTheme.clTextHint
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: WxTheme.radiusSmall
                            border.width: 1
                            border.color: parent.hovered && parent.enabled ? WxTheme.clPrimary : WxTheme.clBorder
                            color: parent.pressed ? WxTheme.clBgSelected : (parent.hovered ? WxTheme.clBgHover : "transparent")

                            Behavior on border.color { ColorAnimation { duration: WxTheme.animNormal } }
                            Behavior on color { ColorAnimation { duration: WxTheme.animNormal } }
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

                // 文件列表
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
                            fileSize: panelBackend ? panelBackend.get_file_size_at(index) : ""
                            fileType: {
                                var name = fileName.toLowerCase()
                                if (name.endsWith(".pdf")) return "pdf"
                                if (/\.(jpg|jpeg|png|gif|bmp|webp)$/.test(name)) return "image"
                                if (/\.(doc|docx|txt|xls|xlsx|ppt|pptx)$/.test(name)) return "doc"
                                return "other"
                            }
                            fileIndex: index
                            filePath: (typeof model.display === "string") ? model.display : ""
                            itemBackend: panelBackend
                            onRemoveRequested: function(idx) {
                                if (panelBackend) panelBackend.remove_file_at(idx)
                            }
                        }
                    }
                }

                // 空文件提示
                Text {
                    visible: !fileListView.visible
                    text: "尚未选择文件（支持多个文件批量发送）"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeSmall
                    color: WxTheme.clTextHint
                    Layout.fillWidth: true
                    Layout.leftMargin: WxTheme.spSmall
                }
            }
        }

        // ═══════════════════════════════
        //  3. 粘性底栏 (Sticky Bottom Panel)
        // ═══════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: WxTheme.clDivider
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: WxTheme.spSmall

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
                            font.bold: true
                        }
                    }

                    contentItem: Text {
                        text: "通过『文件传输助手』转发（先上传1次，后续好友走合并转发）"
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

            // ── 发送间隔配置 ──
            RowLayout {
                Layout.fillWidth: true
                spacing: WxTheme.spSmall

                Text {
                    text: "发送间隔（秒）:"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeSmall
                    color: WxTheme.clTextSecondary
                }

                SpinBox {
                    id: minIntervalSpin
                    from: 0
                    to: maxIntervalSpin.value
                    value: panelBackend ? Math.round(panelBackend.sendIntervalMin) : 2
                    onValueChanged: {
                        if (panelBackend) panelBackend.sendIntervalMin = value
                    }
                    enabled: panelBackend ? panelBackend.inputsEnabled : false
                    stepSize: 1
                    implicitWidth: 90
                }

                Text {
                    text: "至"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeSmall
                    color: WxTheme.clTextSecondary
                }

                SpinBox {
                    id: maxIntervalSpin
                    from: minIntervalSpin.value
                    to: 60
                    value: panelBackend ? Math.round(panelBackend.sendIntervalMax) : 3
                    onValueChanged: {
                        if (panelBackend) panelBackend.sendIntervalMax = value
                    }
                    enabled: panelBackend ? panelBackend.inputsEnabled : false
                    stepSize: 1
                    implicitWidth: 90
                }

                Text {
                    text: "（随机延迟，避免封号）"
                    font.family: WxTheme.fontFamily
                    font.pixelSize: WxTheme.fontSizeTiny
                    color: WxTheme.clTextHint
                    Layout.fillWidth: true
                }
            }

            Item { Layout.preferredHeight: 4 }

            // ── 按钮组 (Fixed Bottom Actions) ──
            ActionButtons {
                id: actionsBlock
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                Layout.minimumHeight: 32
                btnBackend: panelBackend
                onStartRequested: {
                    // Quick Frontend Validations
                    var hasError = false
                    if (friendsInput.text.trim() === "") {
                        friendListError.text = "请输入接收好友名单"
                        hasError = true
                    }
                    if (templateInput.text.trim() === "") {
                        templateError.text = "请输入消息模板"
                        hasError = true
                    }
                    if (hasError) return

                    // Fire sending confirm popup
                    sendConfirmDialog.open()
                }
            }
        }
    }

    // ── Context Menus ──

    // Friends Context Menu
    WxContextMenu {
        id: friendsContextMenu
        WxContextMenuItem {
            text: "剪切"
            iconSource: "../icons/trash.svg" // We can load svg here!
            shortcutText: "Ctrl+X"
            enabled: friendsInput.selectionStart !== friendsInput.selectionEnd
            onTriggered: friendsInput.cut()
        }
        WxContextMenuItem {
            text: "复制"
            iconSource: "../icons/export.svg"
            shortcutText: "Ctrl+C"
            enabled: friendsInput.selectionStart !== friendsInput.selectionEnd
            onTriggered: friendsInput.copy()
        }
        WxContextMenuItem {
            text: "粘贴"
            shortcutText: "Ctrl+V"
            enabled: friendsInput.canPaste
            onTriggered: friendsInput.paste()
        }
        MenuSeparator {
            background: Rectangle {
                implicitHeight: 1
                color: WxTheme.clDivider
            }
        }
        WxContextMenuItem {
            text: "清空名单"
            iconSource: "../icons/trash.svg"
            iconColor: WxTheme.clDangerNew
            hoverIconColor: WxTheme.clDangerNewHover
            onTriggered: friendsInput.text = ""
        }
    }

    // Template Context Menu
    WxContextMenu {
        id: templateContextMenu
        WxContextMenuItem {
            text: "剪切"
            shortcutText: "Ctrl+X"
            enabled: templateInput.selectionStart !== templateInput.selectionEnd
            onTriggered: templateInput.cut()
        }
        WxContextMenuItem {
            text: "复制"
            shortcutText: "Ctrl+C"
            enabled: templateInput.selectionStart !== templateInput.selectionEnd
            onTriggered: templateInput.copy()
        }
        WxContextMenuItem {
            text: "粘贴"
            shortcutText: "Ctrl+V"
            enabled: templateInput.canPaste
            onTriggered: templateInput.paste()
        }
        MenuSeparator {
            background: Rectangle {
                implicitHeight: 1
                color: WxTheme.clDivider
            }
        }
        WxContextMenuItem {
            text: "插入 {name} 姓名"
            iconSource: "../icons/info.svg"
            onTriggered: {
                templateInput.insert(templateInput.cursorPosition, "{name}")
                templateInput.forceActiveFocus()
            }
        }
        WxContextMenuItem {
            text: "清空模板"
            iconSource: "../icons/trash.svg"
            iconColor: WxTheme.clDangerNew
            hoverIconColor: WxTheme.clDangerNewHover
            onTriggered: templateInput.text = ""
        }
    }

    // Refresh File Lists on Changes
    Connections {
        target: panelBackend
        function onFilePathsChanged() {
            fileListView.forceLayout()
        }
    }

    // Sending Confirm Popup
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

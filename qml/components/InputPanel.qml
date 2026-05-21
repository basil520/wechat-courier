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
                    spacing: WxTheme.spSmall
                    Text {
                        text: "接收好友名单（每行一个）"
                        font.family: WxTheme.fontFamily
                        font.pixelSize: WxTheme.fontSizeSmall
                        font.bold: true
                        color: WxTheme.clTextSecondary
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "✨ 智能去重"
                        font.family: WxTheme.fontFamily
                        font.pixelSize: WxTheme.fontSizeTiny
                        font.bold: true
                        color: panelBackend && panelBackend.inputsEnabled ? WxTheme.clTextLink : WxTheme.clTextHint
                        visible: friendsInput.text.trim() !== ""
                        
                        scale: cleanMouseArea.containsMouse ? 1.08 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100 } }

                        MouseArea {
                            id: cleanMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: panelBackend ? panelBackend.inputsEnabled : false
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                var txt = friendsInput.text
                                var lines = txt.split("\n")
                                var uniqueLines = []
                                var seen = {}
                                var duplicatesCount = 0
                                
                                for (var i = 0; i < lines.length; i++) {
                                    var cleaned = lines[i].trim()
                                    if (cleaned !== "") {
                                        if (!seen[cleaned]) {
                                            seen[cleaned] = true
                                            uniqueLines.push(cleaned)
                                        } else {
                                            duplicatesCount++
                                        }
                                    }
                                }
                                
                                var cleanedText = uniqueLines.join("\n")
                                friendsInput.text = cleanedText
                                if (panelBackend) panelBackend.friendListText = cleanedText
                                
                                if (typeof globalToast !== "undefined" && globalToast) {
                                    if (duplicatesCount > 0) {
                                        globalToast.show("✨ 已成功去重！清理了 " + duplicatesCount + " 个重复好友", "success")
                                    } else {
                                        globalToast.show("✨ 名单格式已自动净化规范", "info")
                                    }
                                }
                            }
                        }
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
                        placeholderText: "张三\n李四\n王五"
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
                            removable: panelBackend ? panelBackend.inputsEnabled : true
                            onRemoveRequested: function(idx) {
                                if (panelBackend) panelBackend.remove_file_at(idx)
                            }
                        }
                    }
                }

                // Drag & Drop Area / Attachment Box
                Rectangle {
                    id: dropAttachmentBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: fileListView.count > 0 ? 36 : 72
                    radius: WxTheme.radiusMedium
                    color: dropArea.containsDrag ? WxTheme.clBgSelected : (WxTheme.isDark ? "#1f2328" : "#fafafa")
                    border.width: dropArea.containsDrag ? 1.5 : 1
                    border.color: dropArea.containsDrag ? WxTheme.clPrimary : WxTheme.clBorder
                    visible: panelBackend ? panelBackend.inputsEnabled : false
                    
                    Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    DropArea {
                        id: dropArea
                        anchors.fill: parent
                        keys: ["text/uri-list"]
                        
                        onDropped: function(drop) {
                            if (drop.hasUrls && panelBackend && panelBackend.inputsEnabled) {
                                for (var i = 0; i < drop.urls.length; i++) {
                                    var urlStr = drop.urls[i].toString()
                                    panelBackend.add_file_path(urlStr)
                                }
                                if (typeof globalToast !== "undefined" && globalToast) {
                                    globalToast.show("✨ 已成功添加拖拽文件！", "success")
                                }
                            }
                        }
                    }

                    // Content layout when files are present (minimizes layout usage)
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: fileListView.count > 0

                        WxIcon {
                            iconSource: "../icons/folder_open.svg"
                            iconSize: 14
                            iconColor: dropArea.containsDrag ? WxTheme.clPrimary : WxTheme.clTextHint
                            hoverScale: false
                        }

                        Text {
                            text: dropArea.containsDrag ? "松开以添加文件..." : "可拖拽外部文件到此处继续添加..."
                            font.family: WxTheme.fontFamily
                            font.pixelSize: WxTheme.fontSizeTiny
                            color: dropArea.containsDrag ? WxTheme.clPrimary : WxTheme.clTextSecondary
                        }
                    }

                    // Content layout when empty
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        visible: fileListView.count === 0

                        WxIcon {
                            iconSource: "../icons/folder_open.svg"
                            iconSize: 20
                            iconColor: dropArea.containsDrag ? WxTheme.clPrimary : WxTheme.clTextHint
                            hoverScale: false
                        }

                        Text {
                            text: dropArea.containsDrag ? "松开即可添加文件 📂" : "支持拖拽外部文件至此区域快速添加"
                            font.family: WxTheme.fontFamily
                            font.pixelSize: WxTheme.fontSizeTiny
                            color: dropArea.containsDrag ? WxTheme.clPrimary : WxTheme.clTextSecondary
                        }
                    }
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
            iconSource: "../icons/cut.svg"
            shortcutText: "Ctrl+X"
            enabled: friendsInput.selectionStart !== friendsInput.selectionEnd
            onTriggered: friendsInput.cut()
        }
        WxContextMenuItem {
            text: "复制"
            iconSource: "../icons/copy.svg"
            shortcutText: "Ctrl+C"
            enabled: friendsInput.selectionStart !== friendsInput.selectionEnd
            onTriggered: friendsInput.copy()
        }
        WxContextMenuItem {
            text: "粘贴"
            iconSource: "../icons/paste.svg"
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
            text: "全选"
            iconSource: "../icons/select_all.svg"
            shortcutText: "Ctrl+A"
            onTriggered: friendsInput.selectAll()
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
            iconSource: "../icons/cut.svg"
            shortcutText: "Ctrl+X"
            enabled: templateInput.selectionStart !== templateInput.selectionEnd
            onTriggered: templateInput.cut()
        }
        WxContextMenuItem {
            text: "复制"
            iconSource: "../icons/copy.svg"
            shortcutText: "Ctrl+C"
            enabled: templateInput.selectionStart !== templateInput.selectionEnd
            onTriggered: templateInput.copy()
        }
        WxContextMenuItem {
            text: "粘贴"
            iconSource: "../icons/paste.svg"
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
            text: "插入 {name}"
            iconSource: "../icons/text_cursor.svg"
            onTriggered: {
                templateInput.insert(templateInput.cursorPosition, "{name}")
                templateInput.forceActiveFocus()
            }
        }
        WxContextMenuItem {
            text: "全选"
            iconSource: "../icons/select_all.svg"
            shortcutText: "Ctrl+A"
            onTriggered: templateInput.selectAll()
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

    // 发送中灰化遮罩
    Rectangle {
        anchors.fill: parent
        color: WxTheme.clBgPrimary
        opacity: panelBackend && !panelBackend.inputsEnabled ? 0.03 : 0.0
        visible: opacity > 0
        z: 10
    }
}

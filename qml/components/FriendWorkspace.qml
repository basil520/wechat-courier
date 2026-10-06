import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQml.Models
import "../theme"
import "TableWidths.js" as TableWidths

Item {
    id: root
    objectName: "friendWorkspace"
    property var appBackend: null
    readonly property var friendBackend: appBackend ? appBackend.friends : null
    readonly property var taskBackend: appBackend ? appBackend.task : null
    readonly property bool interactionLocked: !!(taskBackend && taskBackend.active)
    readonly property bool contactsBusy: !!(appBackend && appBackend.contacts && appBackend.contacts.busy)
    readonly property bool friendSubmitAvailable: !!(taskBackend && taskBackend.acceptanceEnabled || appBackend && appBackend.agent && appBackend.agent.friendSubmitEnabled === true)
    readonly property bool ownsTask: !!(taskBackend && taskBackend.kind === "friend_add")
    property bool monitorDismissed: false
    readonly property bool monitorVisible: root.ownsTask && !root.monitorDismissed
    property int contextRow: -1
    property int currentRow: -1
    property int previewRevision: 0
    readonly property int tableRowHeight: 40
    readonly property var columnWidths: TableWidths.expand([44, 60, 112, 186, 126, 240, 180, 110], friendTable.width, 1158, [2, 3, 5, 6])
    readonly property int tableContentWidth: columnWidths.reduce(function (sum, value) {
        return sum + value;
    }, 0)
    property var activeCellEditor: null
    property var activeTextMenu: null
    property int currentFieldIndex: 0
    function refreshTableLayout() {
        if (root.visible) {
            friendTable.forceLayout();
            friendTable.contentX = Math.min(friendTable.contentX, Math.max(0, root.tableContentWidth - friendTable.width));
        }
    }
    onColumnWidthsChanged: Qt.callLater(root.refreshTableLayout)
    onVisibleChanged: {
        if (visible)
            Qt.callLater(root.refreshTableLayout);
        else
            friendPreviewDialog.close();
    }
    readonly property var currentPreview: {
        var revision = previewRevision;
        return friendBackend && currentRow >= 0 ? friendBackend.model.preview(currentRow) : ({});
    }
    readonly property string currentAccount: {
        var revision = previewRevision;
        return currentRow >= 0 && currentRow < previewModel.items.count ? previewModel.items.get(currentRow).model.account || "" : "";
    }
    DelegateModel {
        id: previewModel
        model: root.friendBackend ? root.friendBackend.model : null
        delegate: Item {}
    }

    Connections {
        target: root.friendBackend ? root.friendBackend.model : null
        ignoreUnknownSignals: true
        function onCountsChanged() {
            if (root.currentRow >= root.friendBackend.model.count)
                root.currentRow = root.friendBackend.model.count - 1;
            if (root.currentRow < 0 && root.friendBackend.model.count > 0)
                root.currentRow = 0;
            ++root.previewRevision;
        }
        function onModelReset() {
            root.cancelCellEdit();
            root.currentRow = root.friendBackend.model.count > 0 ? 0 : -1;
            ++root.previewRevision;
            rangeStart.text = "1";
            rangeEnd.text = String(Math.max(1, Math.min(root.friendBackend.model.count, root.friendBackend.batchLimit)));
            Qt.callLater(function () {
                friendTable.forceLayout();
                if (root.friendBackend && root.friendBackend.model.count > 0)
                    friendTable.positionViewAtRow(0, TableView.Contain);
                else
                    friendTable.contentY = 0;
            });
        }
    }
    Component.onCompleted: {
        if (root.friendBackend && root.friendBackend.model.count > 0)
            root.currentRow = 0;
    }

    function insertPlaceholder(value) {
        if (root.interactionLocked || !root.friendBackend)
            return;
        globalGreetingField.insert(globalGreetingField.cursorPosition, value);
        root.friendBackend.defaultGreeting = globalGreetingField.text;
        globalGreetingField.forceActiveFocus();
    }

    function startTask() {
        if (root.interactionLocked)
            return;
        if (taskBackend)
            taskBackend.startFriends();
    }

    function dismissMonitor() {
        root.monitorDismissed = true;
        if (root.taskBackend && root.taskBackend.riskStopModelRow >= 0) {
            root.currentRow = root.taskBackend.riskStopModelRow;
            Qt.callLater(function () {
                friendTable.forceLayout();
                friendTable.positionViewAtRow(root.currentRow, TableView.Contain);
            });
        }
    }

    Connections {
        target: root.taskBackend
        ignoreUnknownSignals: true
        function onActiveChanged() {
            if (root.taskBackend.active && root.ownsTask)
                root.monitorDismissed = false;
        }
        function onKindChanged() {
            if (root.taskBackend.active && root.ownsTask)
                root.monitorDismissed = false;
        }
    }

    function requestFriendStart() {
        if (root.interactionLocked || !root.friendSubmitAvailable)
            return;
        root.commitCellEdit();
        if (root.taskBackend && root.taskBackend.acceptanceEnabled) {
            root.startTask();
            return;
        }
        friendSubmitConfirmDialog.open();
    }

    function confirmFriendSubmission() {
        if (root.interactionLocked || !root.friendSubmitAvailable || !root.taskBackend || root.taskBackend.acceptanceEnabled)
            return;
        root.startTask();
    }

    onInteractionLockedChanged: {
        if (root.interactionLocked) {
            root.cancelCellEdit();
            if (root.activeTextMenu)
                root.activeTextMenu.close();
            friendContextMenu.close();
            friendSubmitConfirmDialog.close();
            friendPreviewDialog.close();
        }
    }

    function appendManualRecord() {
        if (root.interactionLocked || !root.friendBackend)
            return -1;
        root.commitCellEdit();
        var row = root.friendBackend.model.appendEmptyRecord();
        if (row >= 0) {
            root.currentRow = row;
            Qt.callLater(function () {
                if (root.friendBackend && row < root.friendBackend.model.count) {
                    friendTable.forceLayout();
                    friendTable.positionViewAtRow(row, TableView.Contain);
                }
            });
        }
        return row;
    }

    function removeContextRecord() {
        if (root.interactionLocked || !root.friendBackend || root.contextRow < 0)
            return false;
        root.cancelCellEdit();
        var removed = root.friendBackend.model.removeRecord(root.contextRow);
        root.contextRow = -1;
        return removed;
    }

    function clearFriendTable() {
        if (root.interactionLocked || !root.friendBackend || root.friendBackend.model.count === 0)
            return false;
        friendContextMenu.close();
        root.cancelCellEdit();
        root.contextRow = -1;
        return root.friendBackend.model.clearRecords();
    }

    function openTableContextMenu(row) {
        if (root.interactionLocked || !root.friendBackend)
            return;
        root.contextRow = row >= 0 && row < root.friendBackend.model.count ? row : -1;
        if (root.contextRow >= 0)
            root.currentRow = root.contextRow;
        friendContextMenu.popup();
    }

    function cancelCellEdit() {
        if (root.activeCellEditor)
            root.activeCellEditor.cancelEdit();
    }

    function commitCellEdit() {
        if (root.activeCellEditor)
            root.activeCellEditor.commitEdit();
    }

    function activateEditor(editor, fieldIndex) {
        if (root.interactionLocked)
            return false;
        if (root.activeCellEditor && root.activeCellEditor !== editor)
            root.activeCellEditor.commitEdit();
        root.activeCellEditor = editor;
        root.currentRow = editor.modelRow;
        root.currentFieldIndex = fieldIndex;
        return true;
    }

    function moveToEditableCell(row, fieldIndex, direction) {
        if (root.interactionLocked || !root.friendBackend)
            return;
        var position = row * 4 + fieldIndex + direction;
        if (position < 0 || position >= root.friendBackend.model.count * 4)
            return;
        var nextRow = Math.floor(position / 4);
        var nextField = position % 4;
        root.currentRow = nextRow;
        root.currentFieldIndex = nextField;
        friendTable.positionViewAtRow(nextRow, TableView.Contain);
        Qt.callLater(function () {
            friendTable.forceLayout();
            var cell = friendTable.itemAtCell(Qt.point(0, nextRow));
            if (cell) {
                var editor = cell.editors[nextField];
                var point = editor.mapToItem(friendTable.contentItem, 0, 0);
                if (point.x < friendTable.contentX)
                    friendTable.contentX = point.x;
                else if (point.x + editor.width > friendTable.contentX + friendTable.width)
                    friendTable.contentX = point.x + editor.width - friendTable.width;
                editor.beginEdit();
            }
        });
    }

    function openCellTextMenu(editor) {
        if (root.interactionLocked)
            return;
        friendContextMenu.close();
        root.activeTextMenu = editor.ContextMenu.menu;
        root.activeTextMenu.popup();
    }

    component FriendIconButton: ToolButton {
        id: iconButton
        property string tooltipText: ""
        implicitWidth: 36
        implicitHeight: 36
        icon.color: WxTheme.clTextSecondary
        icon.width: 16
        icon.height: 16
        hoverEnabled: true
        opacity: enabled ? 1 : 0.45
        background: Rectangle {
            radius: 6
            color: iconButton.down || iconButton.hovered ? WxTheme.clBgHover : "transparent"
            border.width: iconButton.visualFocus ? 1 : 0
            border.color: WxTheme.clBorderFocus
        }
        WxToolTip { visible: iconButton.hovered && text.length > 0; text: iconButton.tooltipText }
    }

    component PreviewField: RowLayout {
        property string caption: ""
        property string valueText: ""
        property string valueObjectName: ""
        spacing: 8
        Text {
            text: parent.caption
            color: WxTheme.clTextHint
            font.family: WxTheme.fontFamily
            font.pixelSize: 12
        }
        Text {
            objectName: parent.valueObjectName
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: parent.valueText
            textFormat: Text.PlainText
            color: WxTheme.clTextSecondary
            font.family: WxTheme.fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
            WxToolTip {
                visible: previewValueHover.containsMouse && text.length > 0
                text: previewValueHover.parent.text
            }
            MouseArea {
                id: previewValueHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }
        }
    }

    component FriendCellEditor: WxTextField {
        id: cellEditor
        property int modelRow: -1
        property int fieldIndex: -1
        property string fieldName: ""
        property string committedText: ""
        property bool editing: false
        readOnly: !editing
        enabled: !root.interactionLocked
        selectByMouse: editing
        implicitHeight: 36
        font.family: WxTheme.fontFamily
        font.pixelSize: WxTheme.fontSizeNormal
        color: WxTheme.clTextPrimary
        padding: 8
        onCommittedTextChanged: {
            if (!editing)
                text = committedText;
        }
        Component.onCompleted: text = committedText
        Component.onDestruction: {
            if (root.activeCellEditor === cellEditor)
                root.activeCellEditor = null;
        }

        function resumeFocus() {
            forceActiveFocus();
        }
        function beginEdit() {
            if (!root.activateEditor(cellEditor, fieldIndex))
                return;
            text = committedText;
            editing = true;
            forceActiveFocus();
            selectAll();
        }
        function commitEdit() {
            if (!editing)
                return;
            var value = text;
            editing = false;
            if (root.activeCellEditor === cellEditor)
                root.activeCellEditor = null;
            if (!root.interactionLocked && root.friendBackend && value !== committedText)
                root.friendBackend.model.setCell(modelRow, fieldName, value);
            text = committedText;
        }
        function cancelEdit() {
            editing = false;
            text = committedText;
            if (root.activeCellEditor === cellEditor)
                root.activeCellEditor = null;
        }
        onActiveFocusChanged: {
            if (activeFocus) {
                root.currentRow = modelRow;
                root.currentFieldIndex = fieldIndex;
            } else if (editing && !cellEditor.ContextMenu.menu.visible)
                commitEdit();
        }
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function (event) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (editing)
                    commitEdit();
                else
                    beginEdit();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape && editing) {
                cancelEdit();
                event.accepted = true;
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                commitEdit();
                root.moveToEditableCell(modelRow, fieldIndex, event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier) ? -1 : 1);
                event.accepted = true;
            }
        }
        background: Rectangle {
            color: cellEditor.editing ? WxTheme.clBgPrimary : "transparent"
            border.color: cellEditor.editing ? WxTheme.clBorderFocus : "transparent"
            radius: WxTheme.radiusSmall
        }
        MouseArea {
            anchors.fill: parent
            visible: !cellEditor.editing
            acceptedButtons: Qt.LeftButton
            onClicked: cellEditor.forceActiveFocus()
            onDoubleClicked: cellEditor.beginEdit()
        }
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: root.monitorVisible ? 1 : 0

        Item {
            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    id: friendHeader
                    objectName: "friendHeader"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        spacing: 16
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 4
                            Text {
                                text: "工作区 / 好友"
                                color: WxTheme.clTextSecondary
                                font.family: WxTheme.fontFamily
                                font.pixelSize: 12
                            }
                            Text {
                                objectName: "friendPageTitle"
                                Layout.fillWidth: true
                                text: "自动发送好友申请"
                                color: WxTheme.clTextPrimary
                                font.family: WxTheme.fontFamily
                                font.pixelSize: 20
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                        }
                        WxButton {
                            text: "下载模板"
                            iconName: "export"
                            enabled: !root.interactionLocked
                            onClicked: {
                                if (!root.interactionLocked)
                                    templateDialog.open();
                            }
                        }
                        WxButton {
                            objectName: "importFriendsButton"
                            Accessible.name: root.taskBackend && root.taskBackend.acceptanceEnabled ? "importFriendsButton" : text
                            text: "导入 Excel / CSV"
                            iconName: "excel"
                            enabled: !root.interactionLocked
                            onClicked: {
                                if (!root.interactionLocked)
                                    importDialog.open();
                            }
                        }
                    }
                }

                Rectangle {
                    id: friendTools
                    objectName: "friendTools"
                    readonly property bool compact: width - 48 < 1040
                    readonly property string notice: root.friendBackend ? root.friendBackend.model.selectionError || root.friendBackend.model.importError || root.friendBackend.model.importWarning || "" : ""
                    Layout.fillWidth: true
                    Layout.preferredHeight: (compact ? 96 : 56) + (notice ? 24 : 0)
                    color: WxTheme.clBgPrimary
                    Rectangle {
                        anchors.top: parent.top
                        width: parent.width
                        height: 1
                        color: WxTheme.clDivider
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: WxTheme.clDivider
                    }
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        anchors.topMargin: 10
                        anchors.bottomMargin: 10
                        spacing: 4
                        GridLayout {
                            Layout.fillWidth: true
                            columns: friendTools.compact ? 2 : 3
                            columnSpacing: 16
                            rowSpacing: 4
                            RowLayout {
                                Layout.row: 0
                                Layout.column: 0
                                spacing: 12
                                Text {
                                    text: root.friendBackend ? "共 " + root.friendBackend.model.count + " 条" : "共 0 条"
                                    color: WxTheme.clTextSecondary
                                    font.family: WxTheme.fontFamily
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: "有效 " + (root.friendBackend ? root.friendBackend.model.validCount : 0)
                                    color: WxTheme.clTextSecondary
                                    font.family: WxTheme.fontFamily
                                    font.pixelSize: 12
                                }
                                Text {
                                    readonly property int invalidCount: root.friendBackend ? root.friendBackend.model.count - root.friendBackend.model.validCount : 0
                                    text: "异常 " + invalidCount
                                    color: invalidCount ? WxTheme.clDangerNew : WxTheme.clTextHint
                                    font.family: WxTheme.fontFamily
                                    font.pixelSize: 12
                                }
                            }
                            RowLayout {
                                Layout.row: 0
                                Layout.column: friendTools.compact ? 1 : 2
                                Layout.fillWidth: true
                                spacing: 12
                                Item {
                                    Layout.fillWidth: true
                                }
                                Text {
                                    objectName: "friendSelectionCount"
                                    text: root.friendBackend ? "已选择 " + root.friendBackend.model.selectedCount + " / " + root.friendBackend.batchLimit : "已选择 0 / 100"
                                    color: WxTheme.clTextPrimary
                                    font.family: WxTheme.fontFamily
                                    font.pixelSize: WxTheme.fontSizeSmall
                                    font.weight: Font.Medium
                                }
                                FriendIconButton {
                                    objectName: "clearFriendTableButton"
                                    Accessible.name: "清空表格"
                                    text: ""
                                    icon.source: "../icons/trash.svg"
                                    tooltipText: "清空表格"
                                    enabled: root.friendBackend && root.friendBackend.model.count > 0 && !root.interactionLocked
                                    onClicked: {
                                        if (!root.interactionLocked)
                                            root.clearFriendTable();
                                    }
                                }
                            }
                            RowLayout {
                                Layout.row: friendTools.compact ? 1 : 0
                                Layout.column: friendTools.compact ? 0 : 1
                                Layout.columnSpan: friendTools.compact ? 2 : 1
                                spacing: 8
                                Text {
                                    text: "序号"
                                    color: WxTheme.clTextSecondary
                                    font.family: WxTheme.fontFamily
                                    font.pixelSize: 12
                                }
                                WxTextField {
                                    id: rangeStart
                                    objectName: "friendRangeStart"
                                    Accessible.name: objectName
                                    Layout.preferredWidth: 64
                                    text: "1"
                                    enabled: !root.interactionLocked
                                    validator: IntValidator {
                                        bottom: 1
                                        top: 1000000
                                    }
                                    selectByMouse: true
                                }
                                Text {
                                    text: "至"
                                    color: WxTheme.clTextHint
                                    font.family: WxTheme.fontFamily
                                    font.pixelSize: 12
                                }
                                WxTextField {
                                    id: rangeEnd
                                    objectName: "friendRangeEnd"
                                    Accessible.name: objectName
                                    Layout.preferredWidth: 64
                                    text: String(root.friendBackend ? Math.max(1, Math.min(root.friendBackend.model.count, root.friendBackend.batchLimit)) : 1)
                                    enabled: !root.interactionLocked
                                    validator: IntValidator {
                                        bottom: 1
                                        top: 1000000
                                    }
                                    selectByMouse: true
                                }
                                WxButton {
                                    objectName: "selectFriendRangeButton"
                                    Accessible.name: objectName
                                    text: "选择区间"
                                    iconName: "check"
                                    enabled: !!root.friendBackend && !root.interactionLocked
                                    onClicked: root.friendBackend.model.selectRange(rangeStart.acceptableInput ? Number(rangeStart.text) : 0, rangeEnd.acceptableInput ? Number(rangeEnd.text) : 0)
                                }
                                WxButton {
                                    objectName: "clearFriendSelectionButton"
                                    text: "清除选择"
                                    quiet: true
                                    enabled: !!root.friendBackend && !root.interactionLocked
                                    onClicked: root.friendBackend.model.clearSelection()
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: friendTools.notice.length > 0
                            text: friendTools.notice
                            elide: Text.ElideRight
                            color: root.friendBackend && (root.friendBackend.model.selectionError || root.friendBackend.model.importError) ? WxTheme.clDangerNew : WxTheme.clWarningText
                            font.family: WxTheme.fontFamily
                            font.pixelSize: 12
                            WxToolTip {
                                visible: rangeErrorHover.containsMouse && text.length > 0
                                text: rangeErrorHover.parent.text
                            }
                            MouseArea {
                                id: rangeErrorHover
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.preferredHeight: 36
                    color: WxTheme.clBgSecondary
                    clip: true
                    Row {
                        objectName: "friendTableHeaderContent"
                        x: -friendTable.contentX
                        width: root.tableContentWidth
                        height: parent.height
                        spacing: 0
                        Repeater {
                            model: ["选择", "序号", "姓名", "账号", "后缀", "打招呼语", "自动备注", "状态"]
                            Text {
                                required property int index
                                required property string modelData
                                width: root.columnWidths[index]
                                height: 36
                                leftPadding: 8
                                verticalAlignment: Text.AlignVCenter
                                text: modelData
                                color: WxTheme.clTextSecondary
                                font.family: WxTheme.fontFamily
                                font.pixelSize: WxTheme.fontSizeSmall
                                font.weight: Font.Medium
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Rectangle {
                        anchors.fill: parent
                        color: WxTheme.clBgPrimary
                    }
                    TableView {
                        id: friendTable
                        objectName: "friendImportTable"
                        anchors.fill: parent
                        clip: true
                        model: root.friendBackend ? root.friendBackend.model : null
                        contentWidth: root.tableContentWidth
                        columnWidthProvider: function (column) {
                            return root.tableContentWidth;
                        }
                        rowHeightProvider: function (row) {
                            return root.tableRowHeight;
                        }
                        ScrollBar.horizontal: WxScrollBar {
                            objectName: "friendTableHorizontalScrollBar"
                            policy: ScrollBar.AsNeeded
                        }
                        ScrollBar.vertical: WxScrollBar {
                            objectName: "friendTableVerticalScrollBar"
                            policy: ScrollBar.AsNeeded
                        }
                        delegate: Rectangle {
                            id: friendRow
                            required property int row
                            required property string itemId
                            required property string account
                            required property string friendName
                            required property string relationshipChoice
                            required property string greeting
                            required property string remark
                            required property bool valid
                            required property string error
                            required property string status
                            required property bool selected
                            readonly property bool riskStoppedRow: !!(root.taskBackend && root.taskBackend.riskStopItemId === itemId && root.taskBackend.riskStopModelRow >= 0)
                            readonly property var editors: [nameEditor, accountEditor, relationshipEditor, greetingEditor]
                            implicitWidth: root.tableContentWidth
                            implicitHeight: root.tableRowHeight
                            color: riskStoppedRow || !valid ? WxTheme.clDangerSoft : root.currentRow === row || rowHover.hovered ? WxTheme.clBgHover : row % 2 ? WxTheme.clRowAlternate : WxTheme.clBgPrimary
                            HoverHandler {
                                id: rowHover
                            }
                            TableView.onPooled: {
                                for (var index = 0; index < editors.length; ++index)
                                    editors[index].cancelEdit();
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                onClicked: root.currentRow = friendRow.row
                            }
                            Rectangle {
                                width: 3
                                height: parent.height
                                visible: parent.riskStoppedRow || root.currentRow === friendRow.row
                                color: parent.riskStoppedRow ? WxTheme.clDangerNew : WxTheme.clPrimary
                            }
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: WxTheme.clSurfaceBorder
                            }
                            Row {
                                anchors.fill: parent
                                spacing: 0
                                WxCheckBox {
                                    objectName: "friendRowCheckBox"
                                    Accessible.name: "选择第 " + (row + 1) + " 行"
                                    width: root.columnWidths[0]
                                    height: root.tableRowHeight
                                    checked: selected
                                    enabled: valid && !root.interactionLocked
                                    onToggled: {
                                        if (!root.interactionLocked && root.friendBackend)
                                            root.friendBackend.model.setSelected(row, checked);
                                    }
                                }
                                Text {
                                    text: String(row + 1).padStart(2, "0")
                                    width: root.columnWidths[1]
                                    height: root.tableRowHeight
                                    leftPadding: 8
                                    verticalAlignment: Text.AlignVCenter
                                    color: riskStoppedRow ? WxTheme.clDangerNew : WxTheme.clTextSecondary
                                    font.family: WxTheme.fontFamily
                                    font.pixelSize: WxTheme.fontSizeNormal
                                }
                                FriendCellEditor {
                                    id: nameEditor
                                    objectName: "friendNameField"
                                    Accessible.name: "好友姓名"
                                    width: root.columnWidths[2]
                                    height: 36
                                    y: 2
                                    modelRow: friendRow.row
                                    fieldIndex: 0
                                    fieldName: "name"
                                    committedText: friendName
                                }
                                FriendCellEditor {
                                    id: accountEditor
                                    objectName: "friendAccountField"
                                    Accessible.name: root.taskBackend && root.taskBackend.acceptanceEnabled ? "friendAccountField" : "好友账号"
                                    width: root.columnWidths[3]
                                    height: 36
                                    y: 2
                                    modelRow: friendRow.row
                                    fieldIndex: 1
                                    fieldName: "account"
                                    committedText: account
                                }
                                FriendRelationshipSelector {
                                    id: relationshipEditor
                                    objectName: "friendRelationshipSelector"
                                    Accessible.name: "好友后缀"
                                    width: root.columnWidths[4]
                                    height: 36
                                    y: 2
                                    modelRow: friendRow.row
                                    cellMode: true
                                    choice: relationshipChoice
                                    options: root.friendBackend ? root.friendBackend.relationshipOptions : []
                                    enabled: !root.interactionLocked
                                    onActiveFocusChanged: {
                                        if (activeFocus)
                                            root.currentRow = row;
                                    }
                                    onEditStarted: root.activateEditor(relationshipEditor, 2)
                                    onEditEnded: {
                                        if (root.activeCellEditor === relationshipEditor)
                                            root.activeCellEditor = null;
                                    }
                                    onNavigate: function (direction) {
                                        root.moveToEditableCell(row, 2, direction);
                                    }
                                    onChosen: function (value) {
                                        if (!root.interactionLocked && root.friendBackend) {
                                            root.currentRow = row;
                                            root.friendBackend.model.setCell(row, "relationship", value);
                                        }
                                    }
                                }
                                FriendCellEditor {
                                    id: greetingEditor
                                    objectName: "friendGreetingField"
                                    Accessible.name: "好友打招呼语"
                                    width: root.columnWidths[5]
                                    height: 36
                                    y: 2
                                    modelRow: friendRow.row
                                    fieldIndex: 3
                                    fieldName: "greeting"
                                    committedText: greeting
                                    placeholderText: "使用全局默认值"
                                }
                                WxTextField {
                                    objectName: "friendRemarkField"
                                    Accessible.name: "自动备注"
                                    width: root.columnWidths[6]
                                    height: 36
                                    y: 2
                                    text: remark
                                    readOnly: true
                                    selectByMouse: true
                                    onActiveFocusChanged: {
                                        if (activeFocus)
                                            root.currentRow = row;
                                    }
                                    enabled: !root.interactionLocked
                                    color: WxTheme.clTextPrimary
                                    placeholderTextColor: WxTheme.clTextHint
                                    font.family: WxTheme.fontFamily
                                    font.pixelSize: WxTheme.fontSizeNormal
                                    background: Rectangle {
                                        color: parent.activeFocus ? WxTheme.clFieldFill : "transparent"
                                        border.color: parent.activeFocus ? WxTheme.clBorderFocus : "transparent"
                                        radius: WxTheme.radiusSmall
                                    }
                                }
                                Item {
                                    width: root.columnWidths[7]
                                    height: root.tableRowHeight
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: Math.min(parent.width - 12, statusText.implicitWidth + 18)
                                        height: 24
                                        radius: WxTheme.radiusSmall
                                        color: riskStoppedRow || !valid || status === "error" ? WxTheme.clDangerSoft : status === "working" ? WxTheme.clInfoSoft : status === "success" ? WxTheme.clSuccessSoft : status === "unknown" ? WxTheme.clWarningSoft : WxTheme.clNeutralSoft
                                        Text {
                                            id: statusText
                                            anchors.centerIn: parent
                                            width: parent.width - 12
                                            text: riskStoppedRow ? (root.taskBackend.riskStopKind === "friend_frequency" ? "频繁限制" : "风控停止") : !valid ? error : status === "working" ? "执行中" : status === "success" ? (root.taskBackend && root.taskBackend.acceptanceEnabled ? "预检完成" : "已提交") : status === "error" ? "执行异常" : status === "unknown" ? "结果未知" : status === "stopped" ? "未执行" : (root.taskBackend && root.taskBackend.acceptanceEnabled ? "预检通过" : "待提交")
                                            elide: Text.ElideRight
                                            color: !valid || status === "error" ? WxTheme.clDangerNew : status === "working" ? WxTheme.clInfo : status === "success" ? WxTheme.clSuccessText : status === "unknown" ? WxTheme.clWarningText : WxTheme.clTextSecondary
                                            font.family: WxTheme.fontFamily
                                            font.pixelSize: WxTheme.fontSizeTiny
                                            font.bold: true
                                        }
                                        WxToolTip {
                                            visible: statusHover.containsMouse
                                            text: error || statusText.text
                                        }
                                        MouseArea {
                                            id: statusHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            acceptedButtons: Qt.NoButton
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        objectName: "friendEmptyState"
                        anchors.centerIn: parent
                        visible: !root.friendBackend || root.friendBackend.model.count === 0
                        spacing: 12
                        WxIcon {
                            Layout.alignment: Qt.AlignHCenter
                            iconSource: "../icons/excel.svg"
                            iconSize: 28
                            iconColor: WxTheme.clTextHint
                            hoverScale: false
                        }
                        Text {
                            text: "尚未导入名单"
                            color: WxTheme.clTextSecondary
                            font.family: WxTheme.fontFamily
                            font.pixelSize: 14
                            Layout.alignment: Qt.AlignHCenter
                        }
                        WxButton {
                            objectName: "friendEmptyImportButton"
                            text: "导入名单"
                            iconName: "excel"
                            Layout.alignment: Qt.AlignHCenter
                            enabled: !root.interactionLocked
                            onClicked: if (!root.interactionLocked)
                                importDialog.open()
                        }
                    }

                    MouseArea {
                        id: tableContextOverlay
                        objectName: "friendTableContextOverlay"
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        enabled: !root.interactionLocked
                        z: 10
                        onClicked: function (mouse) {
                            if (root.activeCellEditor) {
                                var editor = root.activeCellEditor;
                                var editorPosition = editor.mapFromItem(tableContextOverlay, mouse.x, mouse.y);
                                if (editorPosition.x >= 0 && editorPosition.x < editor.width && editorPosition.y >= 0 && editorPosition.y < editor.height) {
                                    root.openCellTextMenu(editor.fieldIndex === undefined ? editor.contentItem : editor);
                                    return;
                                }
                            }
                            var contentPosition = friendTable.contentItem.mapFromItem(tableContextOverlay, mouse.x, mouse.y);
                            var cell = friendTable.cellAtPosition(contentPosition.x, contentPosition.y);
                            root.openTableContextMenu(cell.y);
                        }
                    }
                }

                Rectangle {
                    id: friendCompose
                    Layout.fillWidth: true
                    Layout.preferredHeight: composeLayout.implicitHeight + 24
                    color: WxTheme.clBgPrimary
                    Rectangle {
                        anchors.top: parent.top
                        width: parent.width
                        height: 1
                        color: WxTheme.clDivider
                    }
                    ColumnLayout {
                        id: composeLayout
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        anchors.topMargin: 12
                        anchors.bottomMargin: 12
                        spacing: 8
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Text {
                                text: "全局打招呼语"
                                color: WxTheme.clTextSecondary
                                font.family: WxTheme.fontFamily
                                font.pixelSize: 12
                            }
                            WxTextField {
                                id: globalGreetingField
                                objectName: "globalFriendGreetingField"
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                placeholderText: "例如：{称呼}，您好，我是老师。"
                                text: root.friendBackend ? root.friendBackend.defaultGreeting : ""
                                enabled: !root.interactionLocked
                                onTextEdited: {
                                    if (!root.interactionLocked && root.friendBackend)
                                        root.friendBackend.defaultGreeting = text;
                                }
                                color: WxTheme.clTextPrimary
                            }
                            Text {
                                text: "后缀"
                                color: WxTheme.clTextSecondary
                                font.family: WxTheme.fontFamily
                                font.pixelSize: 12
                            }
                            FriendRelationshipSelector {
                                objectName: "globalRelationshipSelector"
                                Layout.preferredWidth: 140
                                allowGlobal: false
                                choice: root.friendBackend ? (root.friendBackend.defaultRelationship || "无") : "妈妈"
                                options: root.friendBackend ? root.friendBackend.relationshipOptions : []
                                enabled: !root.interactionLocked
                                onChosen: function (value) {
                                    if (!root.interactionLocked && root.friendBackend)
                                        root.friendBackend.defaultRelationship = value;
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            Text {
                                text: "占位符"
                                color: WxTheme.clTextHint
                                font.family: WxTheme.fontFamily
                                font.pixelSize: 12
                            }
                            WxButton {
                                text: "{姓名}"
                                quiet: true
                                font.pixelSize: 12
                                enabled: !root.interactionLocked
                                onClicked: root.insertPlaceholder(text)
                            }
                            WxButton {
                                text: "{后缀}"
                                quiet: true
                                font.pixelSize: 12
                                enabled: !root.interactionLocked
                                onClicked: root.insertPlaceholder(text)
                            }
                            WxButton {
                                objectName: "insertAddressPlaceholder"
                                text: "{称呼}"
                                quiet: true
                                font.pixelSize: 12
                                enabled: !root.interactionLocked
                                onClicked: root.insertPlaceholder(text)
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            Text {
                                objectName: "friendCurrentAccount"
                                Layout.minimumWidth: 0
                                Layout.maximumWidth: friendCompose.width * 0.4
                                text: root.currentRow < 0 ? "未定位记录" : "第 " + (root.currentRow + 1) + " 行 · " + root.currentAccount
                                textFormat: Text.PlainText
                                color: WxTheme.clTextSecondary
                                font.family: WxTheme.fontFamily
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                WxToolTip {
                                    visible: currentAccountHover.containsMouse
                                    text: currentAccountHover.parent.text
                                }
                                MouseArea {
                                    id: currentAccountHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                            FriendIconButton {
                                objectName: "friendFullPreviewButton"
                                text: ""
                                icon.source: "../icons/info.svg"
                                icon.color: "transparent"
                                tooltipText: "查看完整申请内容"
                                Accessible.name: "查看完整申请内容"
                                enabled: root.currentRow >= 0 && !root.interactionLocked
                                onClicked: friendPreviewDialog.open()
                            }
                        }
                        Item {
                            objectName: "friendContentPreview"
                            readonly property string text: root.currentRow < 0 ? "未定位记录"
                                : "第 " + (root.currentRow + 1) + " 行预览：" + (root.currentPreview.error
                                    || "打招呼语：" + (root.currentPreview.greeting == null ? "保留微信原文" : root.currentPreview.greeting || "")
                                        + "    ｜    备注：" + (root.currentPreview.remark || ""))
                            Layout.fillWidth: true
                            implicitHeight: root.currentPreview.error ? 20 : previewValues.implicitHeight
                            GridLayout {
                                id: previewValues
                                width: parent.width
                                columns: width < 880 ? 1 : 2
                                rowSpacing: 4
                                columnSpacing: 24
                                visible: !root.currentPreview.error
                                PreviewField {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.preferredWidth: 3
                                    caption: "打招呼语"
                                    valueObjectName: "friendPreviewGreeting"
                                    valueText: root.currentRow < 0 ? "" : root.currentPreview.greeting == null ? "保留微信原文" : root.currentPreview.greeting || ""
                                }
                                PreviewField {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 0
                                    Layout.preferredWidth: 1
                                    caption: "备注"
                                    valueObjectName: "friendPreviewRemark"
                                    valueText: root.currentRow < 0 ? "" : root.currentPreview.remark || ""
                                }
                            }
                            Text {
                                width: parent.width
                                visible: !!root.currentPreview.error
                                text: root.currentPreview.error || ""
                                textFormat: Text.PlainText
                                color: WxTheme.clDangerNew
                                font.family: WxTheme.fontFamily
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                WxToolTip {
                                    visible: previewErrorHover.containsMouse
                                    text: previewErrorHover.parent.text
                                }
                                MouseArea {
                                    id: previewErrorHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: friendActionBar
                    objectName: "friendActionBar"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    color: WxTheme.clBgPrimary
                    Rectangle {
                        anchors.top: parent.top
                        width: parent.width
                        height: 1
                        color: WxTheme.clDivider
                    }
                    RowLayout {
                        id: friendActionLayout
                        anchors.fill: parent
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        spacing: 24
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.preferredWidth: 1
                            spacing: 4
                            Text {
                                Layout.fillWidth: true
                                text: root.taskBackend && root.taskBackend.error ? root.taskBackend.error : "等待开始"
                                color: root.taskBackend && root.taskBackend.error ? WxTheme.clDangerNew : WxTheme.clTextPrimary
                                font.family: WxTheme.fontFamily
                                font.pixelSize: WxTheme.fontSizeSmall
                                font.bold: true
                                elide: Text.ElideRight
                                WxToolTip {
                                    visible: taskErrorHover.containsMouse
                                    text: taskErrorHover.parent.text
                                }
                                MouseArea {
                                    id: taskErrorHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.friendBackend ? "请求间隔 " + root.friendBackend.intervalMin + "–" + root.friendBackend.intervalMax + " 秒" + (!root.friendSubmitAvailable ? " · Agent 提交能力不可用" : root.appBackend && root.appBackend.agent.canStartTask && !root.appBackend.agent.automationReady ? " · 会话待恢复" : "") : "随机间隔 15–30 秒"
                                color: WxTheme.clTextHint
                                font.family: WxTheme.fontFamily
                                font.pixelSize: WxTheme.fontSizeTiny
                                elide: Text.ElideRight
                                WxToolTip {
                                    text: parent.text
                                    visible: intervalHover.containsMouse
                                }
                                MouseArea {
                                    id: intervalHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }
                            }
                        }
                        Text {
                            Layout.maximumWidth: 160
                            text: root.taskBackend && root.taskBackend.acceptanceEnabled ? "仅预检，不提交" : "实际提交，无法撤回"
                            color: WxTheme.clWarningText
                            font.family: WxTheme.fontFamily
                            font.pixelSize: WxTheme.fontSizeSmall
                            elide: Text.ElideRight
                        }
                        WxButton {
                            objectName: "startFriendsButton"
                            Layout.alignment: Qt.AlignRight
                            Accessible.name: root.taskBackend && root.taskBackend.acceptanceEnabled ? "startFriendsButton" : text
                            text: (root.taskBackend && root.taskBackend.acceptanceEnabled ? "开始表单预检 " : "开始申请 ") + (root.friendBackend ? root.friendBackend.model.selectedCount : 0) + " 人"
                            enabled: root.appBackend && root.appBackend.agent.canStartTask && !root.interactionLocked && !root.contactsBusy && root.friendSubmitAvailable && root.friendBackend && root.friendBackend.model.selectedCount > 0
                            onClicked: root.requestFriendStart()
                            primary: enabled
                            iconName: "user_plus"
                        }
                    }
                }
            }
        }

        TaskMonitor {
            taskBackend: root.taskBackend
            agentBackend: root.appBackend ? root.appBackend.agent : null
            taskKind: "friend_add"
            onRequestEdit: root.dismissMonitor()
        }
    }

    Popup {
        id: friendPreviewDialog
        objectName: "friendPreviewDialog"
        parent: root
        width: Math.min(720, root.width - 48)
        height: Math.min(420, root.height - 48)
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        padding: 16
        modal: true
        dim: true
        focus: true
        z: 1001
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            color: WxTheme.clBgPrimary
            radius: 8
            border.color: WxTheme.clBorderStrong
        }
        contentItem: ColumnLayout {
            spacing: 12
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: "第 " + (root.currentRow + 1) + " 行 · " + root.currentAccount
                    textFormat: Text.PlainText
                    color: WxTheme.clTextPrimary
                    font.family: WxTheme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
                FriendIconButton {
                    objectName: "friendPreviewCloseButton"
                    text: ""
                    icon.source: "../icons/close.svg"
                    tooltipText: "关闭"
                    Accessible.name: "关闭申请预览"
                    onClicked: friendPreviewDialog.close()
                }
            }
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: WxTheme.clDivider
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.vertical: WxScrollBar {}
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                WxTextArea {
                    objectName: "friendFullPreviewText"
                    width: parent.availableWidth
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.PlainText
                    text: root.currentPreview.error ? root.currentPreview.error : "打招呼语\n" + (root.currentPreview.greeting == null ? "保留微信原文" : root.currentPreview.greeting || "") + "\n\n备注\n" + (root.currentPreview.remark || "")
                    background: null
                    Keys.onEscapePressed: friendPreviewDialog.close()
                }
            }
        }
    }

    ConfirmDialog {
        id: friendSubmitConfirmDialog
        objectName: "friendSubmitConfirmDialog"
        z: 1000
        message: "即将向选中的 " + (root.friendBackend ? root.friendBackend.model.selectedCount : 0) + " 个账号实际提交好友申请。提交后无法撤回，请确认账号和申请内容无误。"
        confirmText: "确认提交"
        cancelText: "取消"
        isDanger: true
        confirmEnabled: !root.interactionLocked && !root.contactsBusy && root.friendSubmitAvailable
        confirmButtonObjectName: "friendSubmitConfirmButton"
        cancelButtonObjectName: "friendSubmitCancelButton"
        onConfirmed: root.confirmFriendSubmission()
    }

    WxContextMenu {
        id: friendContextMenu
        objectName: "friendContextMenu"

        WxContextMenuItem {
            objectName: "addFriendRowMenuItem"
            text: "新增一行"
            enabled: !root.interactionLocked
            onTriggered: root.appendManualRecord()
        }

        MenuSeparator {
            visible: root.contextRow >= 0
            height: visible ? implicitHeight : 0
            background: Rectangle {
                implicitHeight: 1
                color: WxTheme.clDivider
            }
        }

        WxContextMenuItem {
            objectName: "removeFriendRowMenuItem"
            text: "删除此行"
            iconSource: "../icons/trash.svg"
            iconColor: WxTheme.clDangerNew
            hoverIconColor: WxTheme.clDangerNewHover
            visible: root.contextRow >= 0
            height: visible ? implicitHeight : 0
            enabled: !root.interactionLocked
            onTriggered: root.removeContextRecord()
        }
    }

    Connections {
        target: root.activeTextMenu
        function onClosed() {
            Qt.callLater(function () {
                if (!root.interactionLocked && root.activeCellEditor)
                    root.activeCellEditor.resumeFocus();
            });
        }
    }

    FileDialog {
        id: importDialog
        title: "导入好友账号"
        nameFilters: ["Excel / CSV (*.xlsx *.csv)"]
        fileMode: FileDialog.OpenFile
        onAccepted: {
            if (!root.interactionLocked && root.friendBackend)
                root.friendBackend.importFile(selectedFile);
        }
    }

    FileDialog {
        id: templateDialog
        title: "保存好友导入模板"
        nameFilters: ["Excel 文件 (*.xlsx)"]
        fileMode: FileDialog.SaveFile
        defaultSuffix: "xlsx"
        onAccepted: {
            if (!root.interactionLocked && root.friendBackend)
                root.friendBackend.createTemplate(selectedFile);
        }
    }
}

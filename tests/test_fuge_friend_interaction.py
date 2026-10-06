"""Friend-page editing contracts, exercised offscreen without a WeChat connection."""

from __future__ import annotations

import os
from pathlib import Path
import subprocess
import sys
import tempfile

import pytest
from PySide6.QtCore import QObject, QPoint, Property, QSettings, QUrl, qInstallMessageHandler
from PySide6.QtGui import QFont, QFontDatabase, QGuiApplication
from PySide6.QtQuick import QQuickItem, QQuickView
from PySide6.QtQml import QQmlProperty
from PySide6.QtTest import QTest
from PySide6.QtCore import Qt

from app.controllers import FriendController
from app.friend_import import load_friend_records
from tests.test_friend_context_menu_interaction import (
    AppBackend, TaskBackend, _click, _find_item, _type, _view_point,
)

ROOT = Path(__file__).resolve().parents[1]


class OfflineAgent(QObject):
    @Property(bool, constant=True)
    def canStartTask(self):
        return False

    @Property(bool, constant=True)
    def automationReady(self):
        return False

    @Property(bool, constant=True)
    def friendSubmitEnabled(self):
        return False


def exercise(scenario):
    qInstallMessageHandler(lambda kind, context, message: print(message, file=sys.stderr))
    app = QGuiApplication([])
    if os.name == "nt":
        QFontDatabase.addApplicationFont("C:/Windows/Fonts/msyh.ttc")
        app.setFont(QFont("Microsoft YaHei UI", 10))
    with tempfile.TemporaryDirectory() as directory:
        friends = FriendController(QSettings(str(Path(directory) / "settings.ini"), QSettings.IniFormat))
        for row in range(2):
            friends.model.appendEmptyRecord()
            friends.model.setCell(row, "name", f"Student{row}")
            friends.model.setCell(row, "account", f"offline_{row}")
        task = TaskBackend()
        agent = OfflineAgent()
        backend = AppBackend(friends, task, agent)
        view = QQuickView()
        view.setResizeMode(QQuickView.SizeRootObjectToView)
        view.setInitialProperties({"appBackend": backend})
        view.setSource(QUrl.fromLocalFile(str(ROOT / "qml/components/FriendWorkspace.qml")))
        assert view.status() == QQuickView.Ready, [error.toString() for error in view.errors()]
        view.resize(1280, 760)
        view.show()
        QTest.qWait(150)
        root = view.rootObject()
        table = root.findChild(QQuickItem, "friendImportTable")

        def field(name):
            item = _find_item(table.property("contentItem"), name)
            assert item is not None, (name, table.width(), table.height(), table.property("rows"),
                                      table.property("contentWidth"), root.height())
            return item

        def click(item):
            _click(view, item, QPoint(20, int(item.height() / 2)), Qt.LeftButton)

        def edit(item):
            click(item)
            QTest.mouseDClick(view, Qt.LeftButton, Qt.NoModifier,
                             _view_point(item, view, QPoint(20, int(item.height() / 2))))
            QTest.qWait(50)

        def replace(text):
            QTest.keyClick(view, Qt.Key_A, Qt.ControlModifier)
            _type(view, text)
            QTest.qWait(30)

        name = field("friendNameField")
        account = field("friendAccountField")
        greeting = field("friendGreetingField")
        relationship = field("friendRelationshipSelector")
        if scenario == "visual_layout":
            toolbar = root.findChild(QQuickItem, "friendTools")
            assert toolbar is not None, "statistics and range must share a responsive toolbar"
            header = root.findChild(QQuickItem, "friendHeader")
            assert header is not None and abs(header.height() - 72) <= 1
            controls = [root.findChild(QQuickItem, key) for key in (
                "friendRangeStart", "friendRangeEnd", "selectFriendRangeButton",
                "clearFriendSelectionButton", "friendSelectionCount", "clearFriendTableButton")]
            assert all(control is not None for control in controls)
            for width in (1280, 1040, 1039, 744, 896, 1104):
                view.resize(width, 630)
                QTest.qWait(100)
                assert toolbar.property("compact") == (width - 48 < 1040)
                positions = [item.mapToScene(QPoint(0, 0)) for item in controls]
                assert abs(positions[0].y() - positions[1].y()) <= 1
                if not toolbar.property("compact"):
                    assert max(p.y() for p in positions) - min(p.y() for p in positions) < 12
                for item, point in zip(controls, positions):
                    assert 24 <= point.x() <= width - item.width() - 23, item.objectName()
                    assert 0 <= point.y() <= 630 - item.height(), item.objectName()
                assert table.height() >= 180, (width, table.height())
            for control in controls[:4]:
                assert control.height() == 36
            assert root.findChild(QQuickItem, "clearFriendTableButton").property("text") == ""
            assert root.findChild(QQuickItem, "friendActionBar").height() <= 72
        elif scenario == "visual_preview":
            account_label = root.findChild(QQuickItem, "friendCurrentAccount")
            greeting_label = root.findChild(QQuickItem, "friendPreviewGreeting")
            remark_label = root.findChild(QQuickItem, "friendPreviewRemark")
            assert all(label is not None for label in (account_label, greeting_label, remark_label)), "preview must separate identity, greeting and remark"
            friends.defaultGreeting = "Hello {姓名}"
            friends.defaultRelationship = "妈妈"
            QTest.qWait(80)
            assert "offline_0" in account_label.property("text")
            assert greeting_label.property("text") == friends.model.preview(0)["greeting"]
            assert remark_label.property("text") == friends.model.preview(0)["remark"]
            click(account)
            assert QQmlProperty(account.property("background"), "border.color").read().alpha() == 0, "locating is not editing"
            edit(greeting)
            replace("specificgreeting")
            assert greeting_label.property("text") == friends.model.preview(0)["greeting"], "preview must not read an uncommitted draft"
            QTest.keyClick(view, Qt.Key_Return)
            QTest.qWait(80)
            assert greeting_label.property("text") == "specificgreeting"
            root.setProperty("currentRow", 1)
            QTest.qWait(80)
            assert "offline_1" in account_label.property("text")
            assert greeting_label.property("text") == friends.model.preview(1)["greeting"]
            view.resize(744, 630)
            QTest.qWait(80)
            assert remark_label.mapToScene(QPoint()).y() > greeting_label.mapToScene(QPoint()).y()
            friends.model.replace_records(load_friend_records([
                ["姓名", "账号"], *[[f"Student{i}", f"offline_{i}"] for i in range(200)]
            ]))
            root.setProperty("currentRow", 199)
            QTest.qWait(80)
            assert "offline_199" in account_label.property("text"), "preview must work for non-instantiated rows"
            friends.model.setCell(199, "account", "changed_199")
            QTest.qWait(80)
            assert "changed_199" in account_label.property("text")
            assert greeting_label.property("text") == friends.model.preview(199)["greeting"]
            friends.model.setCell(199, "greeting", "Long preview " * 100)
            QTest.qWait(80)
            full_preview = root.findChild(QObject, "friendPreviewDialog")
            click(root.findChild(QQuickItem, "friendFullPreviewButton"))
            assert full_preview.property("opened")
            content = root.findChild(QQuickItem, "friendFullPreviewText")
            assert content.property("readOnly")
            assert friends.model.preview(199)["greeting"] in content.property("text")
            assert friends.model.selectedCount == 0, "preview must not select or start a task"
            QTest.keyClick(view, Qt.Key_Escape)
            QTest.qWait(100)
            assert not full_preview.property("opened")
            click(root.findChild(QQuickItem, "friendFullPreviewButton"))
            task.set_active(True)
            QTest.qWait(100)
            assert not full_preview.property("opened"), "task lock must dismiss the editor preview"
        elif scenario == "visual_states":
            row = account.parentItem().parentItem()
            current_color = row.property("color")
            friends.model.setSelected(0, True)
            QTest.qWait(50)
            assert row.property("color") == current_color, "checking a row must not paint it orange"
            colors = {}
            for outcome, label in (("error", "执行异常"), ("unknown", "结果未知"), ("success", "已提交")):
                friends.model.apply_event({"itemId": friends.model.record_at(0).item_id,
                                          "outcome": outcome, "step": "submit_verified"})
                QTest.qWait(50)
                pending = [row]
                tag = None
                while pending:
                    item = pending.pop()
                    if item.property("text") == label:
                        tag = item.parentItem()
                        break
                    pending.extend(item.childItems())
                assert tag is not None, label
                colors[outcome] = tag.property("color").name()
            assert colors["error"] == "#fff0f1"
            assert len(set(colors.values())) == 3, "failure, unknown and success must have distinct visual states"
        elif scenario == "visual_empty":
            empty = root.findChild(QQuickItem, "friendEmptyState")
            assert empty is not None
            assert not empty.isVisible()
            friends.model.clearRecords()
            QTest.qWait(80)
            assert empty.isVisible()
            assert root.findChild(QQuickItem, "friendEmptyImportButton").property("enabled")
            assert root.findChild(QQuickItem, "friendTableHeaderContent").width() == root.property("tableContentWidth")
            assert root.findChild(QQuickItem, "friendCurrentAccount").property("text") == "未定位记录"
            task.set_active(True)
            QTest.qWait(80)
            assert not root.findChild(QQuickItem, "friendEmptyImportButton").property("enabled")
        elif scenario == "clear":
            button = root.findChild(QQuickItem, "clearFriendTableButton")
            point = button.mapToScene(QPoint(0, 0))
            image = view.grabWindow()
            ink = sum(image.pixelColor(x, y).lightness() < 150
                      for y in range(round(point.y()) + 8, round(point.y() + button.height()) - 8)
                      for x in range(round(point.x()) + 8, round(point.x() + button.width()) - 8))
            assert ink > 12, "clear command must remain visible with the software renderer"
            task.set_active(True)
            QTest.qWait(50)
            assert not button.property("enabled")
            click(button)
            assert friends.model.count == 2
            task.set_active(False)
            QTest.qWait(50)
            click(button)
            assert friends.model.count == 0
        elif scenario == "drafts":
            click(name)
            assert name.property("readOnly") is True, "single click must only locate"
            assert root.property("currentRow") == 0
            edit(name)
            assert name.property("readOnly") is False
            replace("draft")
            assert friends.model.record_at(0).name == "Student0", "draft leaked into setCell"
            QTest.keyClick(view, Qt.Key_Escape)
            QTest.qWait(50)
            assert friends.model.record_at(0).name == "Student0"
            assert name.property("text") == "Student0"
            QTest.keyClick(view, Qt.Key_Return)
            replace("saved")
            QTest.keyClick(view, Qt.Key_Return)
            QTest.qWait(50)
            assert friends.model.record_at(0).name == "saved"
            assert name.property("readOnly") is True
            edit(greeting)
            replace("hello")
            assert friends.model.record_at(0).greeting == ""
            click(root.findChild(QQuickItem, "globalFriendGreetingField"))
            assert friends.model.record_at(0).greeting == "hello", "blur must save"
        elif scenario == "navigation":
            edit(name)
            replace("next")
            QTest.keyClick(view, Qt.Key_Tab)
            QTest.qWait(50)
            assert friends.model.record_at(0).name == "next"
            assert account.property("activeFocus") is True
            assert account.property("readOnly") is False
            replace("changed")
            QTest.keyClick(view, Qt.Key_Tab)
            QTest.qWait(50)
            assert friends.model.record_at(0).account == "changed"
            assert relationship.property("activeFocus") or relationship.property("editing")
            QTest.keyClick(view, Qt.Key_Tab)
            QTest.qWait(50)
            assert greeting.property("activeFocus") is True
            replace("last")
            QTest.keyClick(view, Qt.Key_Tab)
            QTest.qWait(50)
            assert friends.model.record_at(0).greeting == "last"
            assert root.property("currentRow") == 1, "Tab must skip derived remark/status"
            QTest.keyClick(view, Qt.Key_Backtab, Qt.ShiftModifier)
            QTest.qWait(50)
            assert root.property("currentRow") == 0
        elif scenario == "lock":
            edit(account)
            replace("unsaved")
            assert friends.model.record_at(0).account == "offline_0"
            task.set_active(True)
            QTest.qWait(50)
            QTest.keyClick(view, Qt.Key_Return)
            assert friends.model.record_at(0).account == "offline_0"
            assert not account.property("enabled")
            task.set_active(False)
            QTest.qWait(50)
            assert account.property("text") == "offline_0", "lock must discard pending draft"
            checkbox = field("friendRowCheckBox")
            click(checkbox)
            assert friends.model.record_at(0).selected is True
            assert account.property("readOnly") is True, "checkbox must not open an editor"
        elif scenario == "menus":
            edit(account)
            replace("draft")
            _click(view, account, QPoint(20, 15), Qt.RightButton)
            menu = root.property("activeTextMenu")
            assert menu is not None and menu.property("visible") is True
            assert root.findChild(QObject, "friendContextMenu").property("visible") is False
            assert friends.model.record_at(0).account == "offline_0"
            actions = {item.property("text"): item for item in menu.findChildren(QQuickItem)
                       if item.property("text") in ("撤销", "重做", "剪切", "复制", "粘贴", "删除", "全选")}
            assert set(actions) == {"撤销", "重做", "剪切", "复制", "粘贴", "删除", "全选"}
            click(actions["全选"])
            QTest.qWait(200)
            assert account.property("selectedText") == "draft"
            app.clipboard().setText("pasted")
            _click(view, account, QPoint(20, 15), Qt.RightButton)
            click(actions["粘贴"])
            QTest.qWait(200)
            assert account.property("text") == "pasted"
            assert friends.model.record_at(0).account == "offline_0", "menu actions must only edit the draft"
            QTest.keyClick(view, Qt.Key_Escape)
            _click(view, table, QPoint(30, 20), Qt.RightButton)
            assert root.findChild(QObject, "friendContextMenu").property("visible") is True, (
                account.property("activeFocus"), account.property("editing"), menu.property("visible"))
        elif scenario == "widths":
            font = account.property("font").pixelSize()
            assert abs(float(table.property("contentWidth")) - table.width()) <= 1, "wide rows must fill the viewport"
            view.resize(680, 700)
            QTest.qWait(100)
            narrow_widths = [field(n).width() for n in ("friendNameField", "friendAccountField", "friendGreetingField")]
            assert all(actual >= minimum for actual, minimum in zip(narrow_widths, (112, 186, 240)))
            assert abs(float(table.property("contentWidth")) - 1158) <= 1
            assert account.property("font").pixelSize() == font == 14
            assert float(table.property("contentWidth")) > table.width()
            table.setProperty("contentX", 280)
            QTest.qWait(50)
            header = root.findChild(QQuickItem, "friendTableHeaderContent")
            assert header is not None and header.x() == -280
            assert name.height() == 36
            assert root.property("tableRowHeight") == 40
            for width in (1560, 960, 1320):
                view.resize(width, 700)
                QTest.qWait(100)
                assert abs(float(table.property("contentWidth")) - max(table.width(), 1158)) <= 1
                header = root.findChild(QQuickItem, "friendTableHeaderContent")
                assert abs(header.width() - float(table.property("contentWidth"))) <= 1
                for editor_name, header_index in (("friendNameField", 2), ("friendAccountField", 3), ("friendGreetingField", 5)):
                    editor = field(editor_name)
                    headers = [item for item in header.childItems() if item.property("text") is not None]
                    assert abs(editor.width() - headers[header_index].width()) <= 1
            assert root.findChild(QQuickItem, "friendPageTitle").property("text") == "自动发送好友申请"
            for width in (744, 1104):
                view.resize(width, 680)
                table.setProperty("contentX", 0)
                QTest.qWait(100)
                for object_name in ("importFriendsButton", "friendRangeStart", "friendRangeEnd",
                                    "selectFriendRangeButton", "globalFriendGreetingField", "startFriendsButton"):
                    control = root.findChild(QQuickItem, object_name)
                    position = control.mapToScene(QPoint(0, 0))
                    assert 0 <= position.x() and position.x() + control.width() <= width + 1, object_name
                    assert 0 <= position.y() and position.y() + control.height() <= 681, object_name
                start = root.findChild(QQuickItem, "startFriendsButton")
                assert start.mapToScene(QPoint(0, 0)).x() + start.width() >= width - 25, "primary action must align to footer edge"
                if os.environ.get("FUGE_FRIEND_SCREENSHOT"):
                    path = Path(os.environ["FUGE_FRIEND_SCREENSHOT"])
                    assert view.grabWindow().save(str(path.with_stem(f"{path.stem}-{width}")))
        elif scenario == "relationship":
            click(relationship)
            assert relationship.property("editing"), "single click must edit a custom suffix"
            replace("Guardian")
            assert friends.model.record_at(0).relationship is None
            QTest.keyClick(view, Qt.Key_Escape)
            QTest.qWait(50)
            assert friends.model.record_at(0).relationship is None
            click(relationship)
            replace("Guardian")
            QTest.keyClick(view, Qt.Key_Return)
            QTest.qWait(50)
            assert friends.model.record_at(0).relationship == "guardian", (
                friends.model.record_at(0).relationship, relationship.property("editText"), relationship.property("editing"))
            click(relationship)
            click(relationship)  # focus editable input again
            QTest.keyClick(view, Qt.Key_A, Qt.ControlModifier)
            QTest.keyClick(view, Qt.Key_Backspace)
            click(root.findChild(QQuickItem, "globalFriendGreetingField"))
            assert friends.model.record_at(0).relationship == "", "empty custom suffix means explicit none"
            _click(view, relationship, QPoint(int(relationship.width()) - 12, 15), Qt.LeftButton)
            assert QQmlProperty(relationship, "popup.visible").read(), "single arrow click must open choices"
            QTest.keyClick(view, Qt.Key_Home)
            QTest.keyClick(view, Qt.Key_Return)
            QTest.qWait(100)
            assert friends.model.record_at(0).relationship is None, ("follow-global choice must remain distinct from none",
                relationship.property("currentIndex"), relationship.property("highlightedIndex"),
                relationship.property("editText"), relationship.property("editing"),
                QQmlProperty(relationship, "popup.visible").read())
            _click(view, relationship, QPoint(int(relationship.width()) - 12, 15), Qt.LeftButton)
            QTest.keyClick(view, Qt.Key_Home)
            QTest.keyClick(view, Qt.Key_Down)
            QTest.keyClick(view, Qt.Key_Down)
            QTest.keyClick(view, Qt.Key_Return)
            QTest.qWait(100)
            assert friends.model.record_at(0).relationship == "爸爸", (
                "preset suffix must still commit", friends.model.record_at(0).relationship,
                relationship.property("currentIndex"), relationship.property("editing"), relationship.property("editText"))
            _click(view, relationship, QPoint(int(relationship.width()) - 12, 15), Qt.LeftButton)
            QTest.keyClick(view, Qt.Key_Escape)
            QTest.qWait(100)
            assert friends.model.record_at(0).relationship == "爸爸"
            click(relationship)
            replace("unsaved")
            task.set_active(True)
            QTest.qWait(50)
            assert friends.model.record_at(0).relationship == "爸爸"
            assert not relationship.property("editing")
        elif scenario == "relationship_reuse":
            friends.model.replace_records(load_friend_records([
                ["姓名", "账号"], *[[f"Student{i}", f"offline_{i}"] for i in range(200)]
            ]))
            QTest.qWait(100)
            relationship = field("friendRelationshipSelector")
            click(relationship)
            replace("discardonscroll")
            table.setProperty("contentY", 4800)
            QTest.qWait(180)
            assert friends.model.record_at(0).relationship is None, "pooling must discard the old draft"

            def suffix_at(row):
                pending = [table.property("contentItem")]
                while pending:
                    item = pending.pop()
                    if item.objectName() == "friendRelationshipSelector" and item.property("modelRow") == row:
                        return item
                    pending.extend(item.childItems())
                raise AssertionError(f"suffix editor for row {row} was not instantiated")

            reused = suffix_at(120)
            assert not reused.property("editing")
            assert reused.property("choice") == "使用全局"
            click(reused)
            replace("Guardian")
            QTest.keyClick(view, Qt.Key_Return)
            QTest.qWait(80)
            assert friends.model.record_at(120).relationship == "guardian"
            assert friends.model.record_at(0).relationship is None
            table.setProperty("contentY", 0)
            QTest.qWait(150)
            assert suffix_at(0).property("choice") == "使用全局"
        view.hide()
        view.setSource(QUrl())
        app.processEvents()


@pytest.mark.parametrize("scenario", ["drafts", "navigation", "lock", "menus", "widths", "relationship", "relationship_reuse", "clear", "visual_layout", "visual_preview", "visual_states", "visual_empty"])
def test_friend_page_interaction(scenario):
    result = subprocess.run(
        [sys.executable, str(Path(__file__).resolve()), scenario], cwd=ROOT,
        env={**os.environ, "QT_QPA_PLATFORM": "offscreen", "QT_QUICK_BACKEND": "software",
             "QT_QPA_FONTDIR": "C:/Windows/Fonts" if os.name == "nt" else os.environ.get("QT_QPA_FONTDIR", ""),
             "PYTHONPATH": str(ROOT)}, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=25,
    )
    assert result.returncode == 0, result.stdout + result.stderr


if __name__ == "__main__":
    exercise(sys.argv[1])

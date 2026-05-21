# -*- coding: utf-8 -*-
"""BackendController 单元测试"""

import pytest

from app.backend import BackendController
from app.constants import PHASE_IDLE, PHASE_RUNNING, PHASE_PAUSED, PHASE_DONE


class TestBackendPhase:
    def test_initial_phase_is_idle(self, backend):
        assert backend.phase == PHASE_IDLE

    def test_set_phase_emits_signal(self, backend, qtbot):
        with qtbot.waitSignal(backend.phaseChanged, timeout=1000) as blocker:
            backend.phase = PHASE_RUNNING
        assert blocker.args == [PHASE_RUNNING]

    def test_set_same_phase_no_emit(self, backend, qtbot):
        backend.phase = PHASE_RUNNING
        with qtbot.assertNotEmitted(backend.phaseChanged, wait=200):
            backend.phase = PHASE_RUNNING


class TestBackendProperties:
    def test_friend_list_text_notify(self, backend, qtbot):
        with qtbot.waitSignal(backend.friendListTextChanged, timeout=1000):
            backend.friendListText = "Alice\nBob"

    def test_template_text_notify(self, backend, qtbot):
        with qtbot.waitSignal(backend.templateTextChanged, timeout=1000):
            backend.templateText = "Hi {name}"

    def test_use_forward_notify(self, backend, qtbot):
        with qtbot.waitSignal(backend.useForwardChanged, timeout=1000):
            backend.useForward = True

    def test_file_paths_notify_on_add(self, backend, qtbot):
        with qtbot.waitSignal(backend.filePathsChanged, timeout=1000):
            backend.add_file_path("file:///C:/test/doc.pdf")


class TestBackendInputs:
    def test_friend_list_text_triggers_preview(self, backend, qtbot):
        with qtbot.waitSignal(backend.previewMessageChanged, timeout=1000):
            backend.friendListText = "Alice\nBob"
            backend.templateText = "{name}, hi"

    def test_empty_input_no_preview_crash(self, backend):
        # 先设置非空值触发预览，再清空
        backend.friendListText = "Alice"
        backend.templateText = "Hi"
        backend.friendListText = ""
        backend.templateText = ""
        assert backend.previewFriend == ""
        assert backend.previewMessage == "请在左侧输入名单和消息模板即可在此预览效果"

    def test_preview_with_placeholder(self, backend):
        backend.friendListText = "王小明"
        backend.templateText = "{name}，你好！"
        assert backend.previewGreeting == "小明"
        assert backend.previewMessage == "小明，你好！"

    def test_preview_without_placeholder(self, backend):
        backend.friendListText = "王小明"
        backend.templateText = "大家好"
        assert backend.previewMessage == "大家好"

    def test_preview_invalid_placeholder(self, backend):
        backend.friendListText = "王小明"
        backend.templateText = "{invalid}"
        assert "格式有误" in backend.previewMessage

    def test_friend_list_text_clears_fatal_error(self, backend, qtbot):
        backend.friendListText = ""
        backend.templateText = ""
        backend.start_sending()
        assert backend.fatalError != ""
        with qtbot.waitSignal(backend.fatalErrorChanged, timeout=1000):
            backend.friendListText = "Alice"
        assert backend.fatalError == ""

    def test_template_text_clears_fatal_error(self, backend, qtbot):
        backend.friendListText = ""
        backend.templateText = ""
        backend.start_sending()
        assert backend.fatalError != ""
        with qtbot.waitSignal(backend.fatalErrorChanged, timeout=1000):
            backend.templateText = "Hello"
        assert backend.fatalError == ""


class TestBackendStartValidation:
    def test_start_with_empty_friends(self, backend):
        backend.friendListText = ""
        backend.templateText = "hello"
        backend.start_sending()
        assert backend.phase == PHASE_IDLE
        assert "不能为空" in backend.fatalError

    def test_start_with_empty_template(self, backend):
        backend.friendListText = "Alice"
        backend.templateText = ""
        backend.start_sending()
        assert backend.phase == PHASE_IDLE
        assert "不能为空" in backend.fatalError

    def test_start_clears_previous_fatal_error(self, backend):
        backend.friendListText = ""
        backend.templateText = ""
        backend.start_sending()
        assert backend.fatalError != ""
        backend.friendListText = "Alice"
        backend.templateText = "Hi"
        backend.start_sending()
        # 致命错误应在成功启动后被清除
        assert backend.fatalError == ""


class TestBackendStartSending:
    def test_start_sending_transitions_to_running(self, backend, qtbot):
        backend.friendListText = "Alice\nBob"
        backend.templateText = "Hello {name}"
        with qtbot.waitSignal(backend.phaseChanged, timeout=1000):
            backend.start_sending()
        assert backend.phase == PHASE_RUNNING
        assert backend.inputsEnabled is False
        assert backend.progressValue == 0.0

    def test_start_sending_creates_worker(self, backend):
        backend.friendListText = "Alice"
        backend.templateText = "Hi"
        backend.start_sending()
        assert backend._worker is not None
        assert backend._worker.friends == ["Alice"]
        assert backend._worker.message_template == "Hi"


class TestBackendPauseResume:
    def test_pause_transitions_to_paused(self, backend, qtbot):
        backend.friendListText = "Alice\nBob"
        backend.templateText = "Hi"
        backend.start_sending()
        worker = backend._worker
        worker.pause = lambda: None
        with qtbot.waitSignal(backend.phaseChanged, timeout=1000):
            backend.pause_sending()
        assert backend.phase == PHASE_PAUSED
        assert backend.progressStatus == "已暂停"

    def test_resume_transitions_to_running(self, backend, qtbot):
        backend.friendListText = "Alice\nBob"
        backend.templateText = "Hi"
        backend.start_sending()
        worker = backend._worker
        worker.pause = lambda: None
        worker.resume = lambda: None
        backend.pause_sending()
        with qtbot.waitSignal(backend.phaseChanged, timeout=1000):
            backend.resume_sending()
        assert backend.phase == PHASE_RUNNING
        assert backend.progressStatus == "运行中"


class TestBackendStop:
    def test_stop_transitions_to_done(self, backend, qtbot):
        backend.friendListText = "Alice\nBob"
        backend.templateText = "Hi"
        backend.start_sending()
        worker = backend._worker
        worker.request_stop = lambda: None
        with qtbot.waitSignal(backend.phaseChanged, timeout=1000):
            backend.stop_sending()
        assert backend.phase == PHASE_DONE
        assert backend.inputsEnabled is True


class TestBackendFileManagement:
    def test_add_file_path(self, backend):
        backend.add_file_path("file:///C:/Users/test/hello.pdf")
        assert len(backend.filePaths) == 1
        assert backend.filePaths[0] == "C:/Users/test/hello.pdf"
        assert len(backend.fileSizes) == 1

    def test_add_file_path_windows(self, backend):
        """Windows 路径应去掉 file:/// 前缀和首字母斜杠"""
        backend.add_file_path("file:///D:/docs/report.pdf")
        assert backend.filePaths[0] == "D:/docs/report.pdf"

    def test_add_duplicate_file(self, backend):
        backend.add_file_path("file:///C:/test/doc.pdf")
        backend.add_file_path("file:///C:/test/doc.pdf")
        assert len(backend.filePaths) == 1

    def test_remove_file(self, backend):
        backend.add_file_path("file:///C:/test/a.pdf")
        backend.add_file_path("file:///C:/test/b.pdf")
        backend.remove_file_at(0)
        assert len(backend.filePaths) == 1
        assert backend.filePaths[0] == "C:/test/b.pdf"
        assert len(backend.fileSizes) == 1

    def test_remove_invalid_index(self, backend):
        backend.add_file_path("file:///C:/test/a.pdf")
        backend.remove_file_at(99)
        assert len(backend.filePaths) == 1

    def test_reset_clears_files(self, backend):
        backend.add_file_path("file:///C:/test/a.pdf")
        backend.add_file_path("file:///C:/test/b.pdf")
        backend.reset()
        assert len(backend.filePaths) == 0
        assert len(backend.fileSizes) == 0

    def test_file_path_model_is_string_list_model(self, backend):
        from PySide6.QtCore import QStringListModel
        assert isinstance(backend.filePathModel, QStringListModel)

    def test_file_path_model_row_count(self, backend):
        backend.add_file_path("file:///C:/test/a.pdf")
        backend.add_file_path("file:///C:/test/b.pdf")
        assert backend.filePathModel.rowCount() == 2

    def test_file_path_model_remove_row(self, backend):
        backend.add_file_path("file:///C:/test/a.pdf")
        backend.add_file_path("file:///C:/test/b.pdf")
        backend.remove_file_at(0)
        assert backend.filePathModel.rowCount() == 1
        assert backend.filePathModel.data(backend.filePathModel.index(0)) == "C:/test/b.pdf"


class TestBackendReset:
    def test_reset_restores_idle(self, backend):
        backend.friendListText = "Alice"
        backend.templateText = "Hi {name}"
        backend.phase = PHASE_RUNNING
        backend.reset()
        assert backend.phase == PHASE_IDLE
        assert backend.fatalError == ""
        assert backend.inputsEnabled is True
        assert backend.progressValue == 0.0

    def test_reset_stops_running_worker(self, backend):
        backend.friendListText = "Alice"
        backend.templateText = "Hi"
        backend.start_sending()
        assert backend._worker is not None
        backend.reset()
        assert backend._worker is None


class TestBackendSignals:
    def test_log_entry_added_signal(self, backend, qtbot):
        with qtbot.waitSignal(backend.logEntryAdded, timeout=1000):
            backend._on_log_entry("Alice", "Alice", "success", "仅文本")

    def test_fatal_error_changed_signal(self, backend, qtbot):
        with qtbot.waitSignal(backend.fatalErrorChanged, timeout=1000):
            backend._on_fatal_error("连接失败")

    def test_progress_updated_signal(self, backend, qtbot):
        backend.phase = PHASE_RUNNING
        with qtbot.waitSignal(backend.progressValueChanged, timeout=1000):
            backend._on_progress_updated(3, 10)
        assert backend.progressValue == 30.0

    def test_current_friend_signal(self, backend, qtbot):
        with qtbot.waitSignal(backend.currentFriendChanged, timeout=1000):
            backend._on_current_friend("Alice")
        assert backend.currentFriend == "Alice"

    def test_send_finished_transitions_to_done(self, backend, qtbot):
        backend.friendListText = "Alice"
        backend.templateText = "Hi"
        backend.start_sending()
        with qtbot.waitSignal(backend.phaseChanged, timeout=1000):
            backend._on_send_finished()
        assert backend.phase == PHASE_DONE
        assert backend.inputsEnabled is True

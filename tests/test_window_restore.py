# -*- coding: utf-8 -*-
"""WeChat window restore regression tests."""

import pytest

import src.core.window as window_module
from src.core.exceptions import WeChatNotFoundError
from src.core.window import WeChatWindow


def test_activate_hidden_window_uses_win32_fallback_after_tray_restore_fails(monkeypatch):
    manager = WeChatWindow()
    fallback_calls = []
    visibility = iter([False, True])

    monkeypatch.setattr(manager, "_restore_via_tray_icon", lambda: False)
    monkeypatch.setattr(window_module, "is_window_visible", lambda hwnd: next(visibility, True))
    monkeypatch.setattr(
        window_module,
        "bring_window_to_front",
        lambda hwnd: fallback_calls.append(hwnd) or True,
    )

    assert manager._activate_hwnd(12345) is True
    assert fallback_calls == [12345]


def test_connect_stops_when_wechat_window_stays_invisible(monkeypatch):
    manager = WeChatWindow()

    monkeypatch.setattr(window_module, "check_and_fix_registry", lambda: "unchanged")
    monkeypatch.setattr(window_module, "ensure_screen_reader_flag", lambda: False)
    monkeypatch.setattr(window_module, "find_wechat_window", lambda: 12345)
    monkeypatch.setattr(WeChatWindow, "_activate_hwnd", lambda self, hwnd: False)
    monkeypatch.setattr(window_module, "is_window_visible", lambda hwnd: False)
    monkeypatch.setattr(window_module, "get_window_class", lambda hwnd: "Qt51514QWindowIcon")
    monkeypatch.setattr(WeChatWindow, "_try_click_login_button", lambda self, hwnd: False)
    monkeypatch.setattr(
        window_module,
        "UIAWrapper",
        lambda hwnd: pytest.fail("connect() should not initialize UIA for an invisible window"),
    )

    with pytest.raises(WeChatNotFoundError, match="不可见|无法恢复"):
        manager.connect()

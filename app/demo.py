# -*- coding: utf-8 -*-
"""演示模式 — 非 Windows 环境下的 mock 类"""

import time

_DEMO_MODE = False


class MockChatWindow:
    def send_to(self, *a, **kw):
        time.sleep(0.3)

    def send_file_to(self, *a, **kw):
        pass

    def send_message_and_file_to(self, *a, **kw):
        time.sleep(0.3)

    def upload_files_to_helper(self, *a, **kw):
        time.sleep(0.3)
        return True

    def forward_recent_merge_to(self, *a, **kw):
        time.sleep(0.3)
        return True


class MockWeChatClient:
    def __init__(self, auto_connect=False):
        self.chat_window = MockChatWindow()

    def __enter__(self):
        return self

    def __exit__(self, *a):
        pass

    def disconnect(self):
        pass


try:
    from src import WeChatClient  # noqa: F401
except Exception:
    _DEMO_MODE = True
    WeChatClient = MockWeChatClient  # type: ignore


def is_demo_mode() -> bool:
    return _DEMO_MODE

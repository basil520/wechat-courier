# -*- coding: utf-8 -*-
"""数据模型测试"""

from app.models import FriendItem, SendResult


class TestFriendItem:
    def test_basic_remark(self):
        f = FriendItem("25届初二-郑子轩妈妈")
        assert f.remark == "25届初二-郑子轩妈妈"
        assert f.greeting == "子轩妈妈"

    def test_format_message(self):
        # 3字无后缀 → 取后2字 = "小明"
        f = FriendItem("王小明")
        formatted = f.format_message("{name}，您好！")
        assert formatted == "小明，您好！"

    def test_format_message_no_placeholder(self):
        f = FriendItem("Alice")
        formatted = f.format_message("Hello world")
        assert formatted == "Hello world"

    def test_format_message_invalid_placeholder(self):
        f = FriendItem("Alice")
        formatted = f.format_message("{invalid}")
        # 遇到 KeyError 时应原样返回模板
        assert formatted == "{invalid}"


class TestSendResult:
    def test_success_result(self):
        r = SendResult("Alice", "Alice", "success", "仅文本")
        assert r.friend == "Alice"
        assert r.greeting == "Alice"
        assert r.status == "success"
        assert r.detail == "仅文本"

    def test_error_result(self):
        r = SendResult("Bob", "Bob", "error", "错误：超时")
        assert r.status == "error"
        assert "超时" in r.detail

# -*- coding: utf-8 -*-
"""Runtime import and logging regression tests."""

import builtins
import importlib.util
import logging
import subprocess
import sys
from pathlib import Path

import pytest


ROOT = Path(__file__).resolve().parents[1]


def _clear_logger(name: str) -> None:
    logger = logging.getLogger(name)
    for handler in list(logger.handlers):
        logger.removeHandler(handler)
        handler.close()


def _load_config_with_env(monkeypatch, tmp_path):
    monkeypatch.setenv("LOCALAPPDATA", str(tmp_path / "LocalAppData"))
    monkeypatch.delenv("WECHAT_LOG_FILE", raising=False)
    monkeypatch.delenv("WECHAT_SEND_AUDIT_LOG_FILE", raising=False)

    spec = importlib.util.spec_from_file_location(
        "wxauto_config_under_test",
        ROOT / "src" / "config.py",
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_default_log_paths_use_localappdata(monkeypatch, tmp_path):
    config = _load_config_with_env(monkeypatch, tmp_path)
    log_dir = tmp_path / "LocalAppData" / "WxAuto" / "logs"

    assert Path(config.LOG_FILE) == log_dir / "wx4py.log"
    assert Path(config.SEND_AUDIT_LOG_FILE) == log_dir / "wx4py_send_audit.jsonl"


def test_get_logger_falls_back_when_configured_file_is_not_writable(monkeypatch, tmp_path):
    from src.utils import logger as logger_module

    logger_name = "wxauto.tests.unwritable_log"
    _clear_logger(logger_name)
    configured_path = tmp_path / "Program Files" / "wx4py.log"
    fallback_root = tmp_path / "LocalAppData"
    opened_paths = []
    real_file_handler = logging.FileHandler

    def fake_file_handler(filename, *args, **kwargs):
        opened_paths.append(Path(filename))
        if Path(filename) == configured_path:
            raise PermissionError(13, "Permission denied", str(filename))
        return real_file_handler(filename, *args, **kwargs)

    monkeypatch.setenv("LOCALAPPDATA", str(fallback_root))
    monkeypatch.setattr(logger_module, "LOG_FILE", str(configured_path))
    monkeypatch.setattr(logger_module.logging, "FileHandler", fake_file_handler)

    try:
        logger = logger_module.get_logger(logger_name)
        logger.info("fallback logger is alive")
    finally:
        _clear_logger(logger_name)

    assert configured_path in opened_paths
    assert fallback_root / "WxAuto" / "logs" / "wx4py.log" in opened_paths


def test_frozen_windows_import_failure_is_not_silently_demo_mode(monkeypatch):
    spec = importlib.util.spec_from_file_location(
        "wxauto_demo_import_failure",
        ROOT / "app" / "demo.py",
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None

    real_import = builtins.__import__

    def fake_import(name, globals=None, locals=None, fromlist=(), level=0):
        if name == "src.client":
            raise PermissionError(13, "Permission denied", "wx4py.log")
        return real_import(name, globals, locals, fromlist, level)

    monkeypatch.setattr(sys, "platform", "win32")
    monkeypatch.setattr(sys, "frozen", True, raising=False)
    monkeypatch.setattr(builtins, "__import__", fake_import)

    with pytest.raises(PermissionError):
        spec.loader.exec_module(module)


def test_importing_src_client_does_not_import_ai_module():
    code = "import sys; import src.client; print('src.ai' in sys.modules)"
    result = subprocess.run(
        [sys.executable, "-c", code],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )

    assert result.stdout.strip().splitlines()[-1] == "False"


def test_lazy_src_wechatclient_export_remains_available_without_ai_import():
    code = (
        "import sys; "
        "from src import WeChatClient; "
        "print(WeChatClient.__name__); "
        "print('src.ai' in sys.modules)"
    )
    result = subprocess.run(
        [sys.executable, "-c", code],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )

    lines = result.stdout.strip().splitlines()
    assert lines[-2:] == ["WeChatClient", "False"]

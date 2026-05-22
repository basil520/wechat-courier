# -*- coding: utf-8 -*-
"""Logging helpers."""

import json
import logging
import sys
from pathlib import Path

from ..config import (
    LOG_FILE,
    LOG_FORMAT,
    LOG_LEVEL,
    SEND_AUDIT_LOG_FILE,
    get_default_log_dir,
)


def _ensure_parent_dir(file_path: str) -> None:
    Path(file_path).parent.mkdir(parents=True, exist_ok=True)


def _log_path_candidates(configured_path: str, fallback_name: str):
    configured = Path(configured_path)
    fallback = get_default_log_dir() / fallback_name

    yield configured
    if fallback != configured:
        yield fallback


def _create_file_handler(
    configured_path: str,
    fallback_name: str,
    formatter: logging.Formatter,
):
    for path in _log_path_candidates(configured_path, fallback_name):
        try:
            _ensure_parent_dir(str(path))
            handler = logging.FileHandler(str(path), encoding="utf-8")
            handler.setFormatter(formatter)
            return handler
        except OSError:
            continue
    return None


def get_logger(name: str) -> logging.Logger:
    """Return a configured logger without failing when file logging is unavailable."""
    logger = logging.getLogger(name)

    if not logger.handlers:
        formatter = logging.Formatter(LOG_FORMAT)
        stream_handler = logging.StreamHandler(sys.stdout)
        stream_handler.setFormatter(formatter)
        logger.addHandler(stream_handler)

        file_handler = _create_file_handler(LOG_FILE, "wx4py.log", formatter)
        if file_handler is not None:
            logger.addHandler(file_handler)

        logger.setLevel(getattr(logging, LOG_LEVEL.upper(), logging.INFO))
        logger.propagate = False

    return logger


def get_send_audit_logger() -> logging.Logger:
    """Return the structured send audit logger."""
    logger = logging.getLogger("wx4py.send_audit")

    if not logger.handlers:
        file_handler = _create_file_handler(
            SEND_AUDIT_LOG_FILE,
            "wx4py_send_audit.jsonl",
            logging.Formatter("%(message)s"),
        )
        if file_handler is not None:
            logger.addHandler(file_handler)
        else:
            logger.addHandler(logging.NullHandler())

        logger.setLevel(logging.INFO)
        logger.propagate = False

    return logger


def log_send_audit(payload: dict) -> None:
    """Write one structured send audit entry in JSONL format."""
    get_send_audit_logger().info(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":"))
    )

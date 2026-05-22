# -*- coding: utf-8 -*-
"""Win32 frameless window hit-test tests."""

from app import win32_helper as wh


def test_hit_test_detects_resize_borders():
    metrics = wh.FramelessHitTestMetrics(client_width=960, client_height=780)

    assert wh.hit_test_client_point(2, 2, metrics) == wh.HTTOPLEFT
    assert wh.hit_test_client_point(958, 2, metrics) == wh.HTTOPRIGHT
    assert wh.hit_test_client_point(2, 778, metrics) == wh.HTBOTTOMLEFT
    assert wh.hit_test_client_point(958, 778, metrics) == wh.HTBOTTOMRIGHT
    assert wh.hit_test_client_point(2, 120, metrics) == wh.HTLEFT
    assert wh.hit_test_client_point(958, 120, metrics) == wh.HTRIGHT
    assert wh.hit_test_client_point(120, 2, metrics) == wh.HTTOP
    assert wh.hit_test_client_point(120, 778, metrics) == wh.HTBOTTOM


def test_hit_test_maps_custom_titlebar_regions():
    metrics = wh.FramelessHitTestMetrics(client_width=960, client_height=780)

    assert wh.hit_test_client_point(500, 20, metrics) == wh.HTCAPTION
    assert wh.hit_test_client_point(890, 20, metrics) == wh.HTCLIENT
    assert wh.hit_test_client_point(700, 20, metrics) == wh.HTCLIENT
    assert wh.hit_test_client_point(930, 20, metrics) == wh.HTCLIENT
    assert wh.hit_test_client_point(300, 80, metrics) == wh.HTCLIENT


def test_hit_test_scales_qml_metrics_for_high_dpi():
    metrics = wh.FramelessHitTestMetrics(
        client_width=1920,
        client_height=1560,
        dpi_scale=2.0,
    )

    assert wh.hit_test_client_point(1000, 40, metrics) == wh.HTCAPTION
    assert wh.hit_test_client_point(1780, 40, metrics) == wh.HTCLIENT
    assert wh.hit_test_client_point(1400, 40, metrics) == wh.HTCLIENT


def test_install_api_is_available_without_restoring_native_titlebar():
    assert hasattr(wh, "install_frameless_window_hit_test")
    assert wh.FRAMELESS_SNAP_STYLE_MASK & wh.WS_THICKFRAME
    assert not (wh.FRAMELESS_SNAP_STYLE_MASK & wh.WS_CAPTION)

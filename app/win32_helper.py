# -*- coding: utf-8 -*-
"""Windows Native DWM Visual Controller Module

Provides helper functions using ctypes to apply Windows 11 Mica/Acrylic effects
and immersive dark-mode titlebars to the native PySide6 window frame.
"""

import sys
import ctypes

# Only expose active bindings on Windows
if sys.platform == "win32":
    try:
        from ctypes import wintypes
        dwmapi = ctypes.WinDLL("dwmapi")
    except Exception as e:
        print(f"[win32_helper] Failed to load dwmapi.dll: {e}")
        dwmapi = None
else:
    dwmapi = None

# DWM Window Attributes
DWMWA_USE_IMMERSIVE_DARK_MODE = 20
DWMWA_SYSTEMBACKDROP_TYPE = 38

# Windows 11 System Backdrop Types (DWMWA_SYSTEMBACKDROP_TYPE)
DWMSBT_AUTO = 0
DWMSBT_DISABLE = 1
DWMSBT_MICA = 2        # Mica style (wallpaper colored)
DWMSBT_ACRYLIC = 3     # Acrylic frosted glass style (wallpaper + behind window)
DWMSBT_TABBED = 4      # Mica Alt style


def set_immersive_dark_mode(hwnd_val: int, enabled: bool) -> bool:
    """Forcibly set native window frame border and titlebar to Dark Mode or Light Mode.

    Args:
        hwnd_val: The native HWND window ID integer.
        enabled: True for Immersive Dark mode, False for standard Light mode.
    """
    if not dwmapi or hwnd_val is None or hwnd_val == 0:
        return False
    try:
        value = ctypes.c_int(1 if enabled else 0)
        hr = dwmapi.DwmSetWindowAttribute(
            wintypes.HWND(hwnd_val),
            ctypes.c_uint(DWMWA_USE_IMMERSIVE_DARK_MODE),
            ctypes.byref(value),
            ctypes.sizeof(value)
        )
        return hr == 0
    except Exception as e:
        print(f"[win32_helper] DwmSetWindowAttribute immersive dark failed: {e}")
        return False


def set_window_backdrop(hwnd_val: int, backdrop_type: int) -> bool:
    """Set the modern Windows 11 transparency backdrop effect (Mica or Acrylic).

    Args:
        hwnd_val: The native HWND window ID integer.
        backdrop_type: One of DWMSBT_AUTO, DWMSBT_DISABLE, DWMSBT_MICA, DWMSBT_ACRYLIC, or DWMSBT_TABBED.
    """
    if not dwmapi or hwnd_val is None or hwnd_val == 0:
        return False
    try:
        value = ctypes.c_int(backdrop_type)
        hr = dwmapi.DwmSetWindowAttribute(
            wintypes.HWND(hwnd_val),
            ctypes.c_uint(DWMWA_SYSTEMBACKDROP_TYPE),
            ctypes.byref(value),
            ctypes.sizeof(value)
        )
        return hr == 0
    except Exception as e:
        print(f"[win32_helper] DwmSetWindowAttribute backdrop failed: {e}")
        return False

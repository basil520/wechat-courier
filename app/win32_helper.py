# -*- coding: utf-8 -*-
"""Windows Native DWM Visual Controller Module

Provides helper functions using ctypes to apply Windows 10/11 Acrylic/Mica effects
and immersive dark-mode titlebars to the native PySide6 window frame.
"""

import sys
import ctypes

# Only expose active bindings on Windows
if sys.platform == "win32":
    try:
        from ctypes import wintypes
        dwmapi = ctypes.WinDLL("dwmapi")
        user32 = ctypes.WinDLL("user32")
    except Exception as e:
        print(f"[win32_helper] Failed to load Win32 DLLs: {e}")
        dwmapi = None
        user32 = None
else:
    dwmapi = None
    user32 = None

# DWM Window Attributes
DWMWA_USE_IMMERSIVE_DARK_MODE = 20
DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1 = 19
DWMWA_SYSTEMBACKDROP_TYPE = 38

# Windows 11 System Backdrop Types (DWMWA_SYSTEMBACKDROP_TYPE)
DWMSBT_AUTO = 0
DWMSBT_DISABLE = 1
DWMSBT_MICA = 2        # Mica style (wallpaper colored)
DWMSBT_ACRYLIC = 3     # Acrylic frosted glass style (wallpaper + behind window)
DWMSBT_TABBED = 4      # Mica Alt style

# Windows 10 undocumented Accent Policy structures
class ACCENT_POLICY(ctypes.Structure):
    _fields_ = [
        ("AccentState", ctypes.c_int),
        ("AccentFlags", ctypes.c_int),
        ("GradientColor", ctypes.c_int),
        ("AnimationId", ctypes.c_int)
    ]

class WINDOWCOMPOSITIONATTRIBDATA(ctypes.Structure):
    _fields_ = [
        ("Attribute", ctypes.c_int),
        ("Data", ctypes.c_void_p),
        ("SizeOfData", ctypes.c_size_t)
    ]

# Windows 10 Composition Attributes
WCA_ACCENT_POLICY = 19

# Windows 10 Accent States
ACCENT_DISABLED = 0
ACCENT_ENABLE_GRADIENT = 1
ACCENT_ENABLE_TRANSPARENTGRADIENT = 2
ACCENT_ENABLE_BLURBEHIND = 3
ACCENT_ENABLE_ACRYLICBLURBEHIND = 4


def set_immersive_dark_mode(hwnd_val: int, enabled: bool) -> bool:
    """Forcibly set native window frame border and titlebar to Dark Mode or Light Mode.

    Supports both Windows 11 (attribute 20) and Windows 10 builds (attributes 20 & 19).
    """
    if not dwmapi or hwnd_val is None or hwnd_val == 0:
        return False
    try:
        value = ctypes.c_int(1 if enabled else 0)
        
        # Try modern Windows 11 and Windows 10 20H1+ (attribute 20)
        hr20 = dwmapi.DwmSetWindowAttribute(
            wintypes.HWND(hwnd_val),
            ctypes.c_uint(DWMWA_USE_IMMERSIVE_DARK_MODE),
            ctypes.byref(value),
            ctypes.sizeof(value)
        )
        
        # Try older Windows 10 builds (attribute 19)
        hr19 = dwmapi.DwmSetWindowAttribute(
            wintypes.HWND(hwnd_val),
            ctypes.c_uint(DWMWA_USE_IMMERSIVE_DARK_MODE_BEFORE_20H1),
            ctypes.byref(value),
            ctypes.sizeof(value)
        )
        
        return hr20 == 0 or hr19 == 0
    except Exception as e:
        print(f"[win32_helper] DwmSetWindowAttribute immersive dark failed: {e}")
        return False


def set_window_backdrop_win11(hwnd_val: int, backdrop_type: int) -> bool:
    """Set the modern Windows 11 transparency backdrop effect (Mica or Acrylic)."""
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


def set_window_backdrop_win10(hwnd_val: int, is_dark: bool) -> bool:
    """Apply native Acrylic frosted glass effect on Windows 10 using undocumented user32 APIs."""
    if not user32 or hwnd_val is None or hwnd_val == 0:
        return False
    try:
        accent = ACCENT_POLICY()
        accent.AccentState = ACCENT_ENABLE_ACRYLICBLURBEHIND
        accent.AccentFlags = 2  # Draw background gradient color and blur
        
        # Color formatted as AABBGGRR in hex
        # Windows 10 Acrylic needs an alpha tint for readability
        if is_dark:
            # 80% opacity dark grey/slate (0xcc1c1916)
            accent.GradientColor = 0xcc1c1916
        else:
            # 85% opacity pure white (0xd9ffffff)
            accent.GradientColor = 0xd9ffffff
            
        policy_size = ctypes.sizeof(accent)
        
        data = WINDOWCOMPOSITIONATTRIBDATA()
        data.Attribute = WCA_ACCENT_POLICY
        data.Data = ctypes.addressof(accent)
        data.SizeOfData = policy_size
        
        hr = user32.SetWindowCompositionAttribute(hwnd_val, ctypes.byref(data))
        return hr != 0
    except Exception as e:
        print(f"[win32_helper] SetWindowCompositionAttribute Win10 Acrylic failed: {e}")
        return False


def apply_acrylic_effect(hwnd_val: int, is_dark: bool) -> bool:
    """Intelligently apply native Acrylic frosted glass backdrop based on Windows build version."""
    if sys.platform != "win32" or hwnd_val is None or hwnd_val == 0:
        return False
    try:
        win_version = sys.getwindowsversion()
        # Windows 11 starts at build 22000
        if win_version.major == 10 and win_version.build >= 22000:
            # Windows 11 style
            return set_window_backdrop_win11(hwnd_val, DWMSBT_ACRYLIC)
        else:
            # Windows 10 style
            return set_window_backdrop_win10(hwnd_val, is_dark)
    except Exception as e:
        print(f"[win32_helper] apply_acrylic_effect failed: {e}")
        return False

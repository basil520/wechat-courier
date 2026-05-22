# -*- coding: utf-8 -*-
"""PyInstaller spec — PySide6 + QML 桌面版"""
import os
import sys

from build.pyinstaller_filters import filter_qt_artifacts
from PyInstaller.utils.hooks import collect_submodules

block_cipher = None
ROOT = os.path.dirname(SPECPATH)  # WxAuto/

# ═══════════════════════════════════════
#  comtypes 预生成目录
# ═══════════════════════════════════════
datas = []
comtypes_gen_dir = os.path.join(ROOT, "comtypes_gen")
if os.path.isdir(comtypes_gen_dir):
    datas.append((comtypes_gen_dir, "comtypes/gen"))

# ═══════════════════════════════════════
#  src 包 — 通过 collect_submodules 自动收集为可导入模块
#  不再作为 datas 复制，避免与 frozen archive 中的编译模块冲突
# ═══════════════════════════════════════

# ═══════════════════════════════════════
#  QML 文件与图标资源
# ═══════════════════════════════════════
qml_dir = os.path.join(ROOT, "qml")
for dirpath, dirnames, filenames in os.walk(qml_dir):
    for f in filenames:
        if f == "qmldir" or f.endswith((".qml", ".svg")):
            src_path = os.path.join(dirpath, f)
            rel = os.path.relpath(dirpath, ROOT)
            datas.append((src_path, rel))

# ═══════════════════════════════════════
#  图标
# ═══════════════════════════════════════
icon_path = os.path.join(ROOT, "assets", "app.ico")
if os.path.exists(icon_path):
    datas.append((icon_path, "assets"))

# ═══════════════════════════════════════
#  pywin32 DLL
# ═══════════════════════════════════════
binaries = []
pywin32_dll_names = [
    f"pywintypes{sys.version_info.major}{sys.version_info.minor}.dll",
    f"pythoncom{sys.version_info.major}{sys.version_info.minor}.dll",
]
try:
    import PyInstaller.utils.hooks as hooks
    pywin32_dll_dir = hooks.get_pywin32_dll_dir()
    if pywin32_dll_dir:
        for dll in pywin32_dll_names:
            dll_path = os.path.join(pywin32_dll_dir, dll)
            if os.path.exists(dll_path):
                binaries.append((dll_path, "."))
except Exception:
    pass

if not binaries:
    try:
        import pywintypes
        dll_dir = os.path.dirname(pywintypes.__file__)
        for dll in pywin32_dll_names:
            dll_path = os.path.join(dll_dir, dll)
            if os.path.exists(dll_path):
                binaries.append((dll_path, "."))
    except Exception:
        pass

a = Analysis(
    [os.path.join(ROOT, "main.py")],
    pathex=[ROOT],
    binaries=binaries,
    datas=datas,
    hiddenimports=[
        # PySide6
        "PySide6.QtCore", "PySide6.QtGui",
        "PySide6.QtQuick", "PySide6.QtQml", "PySide6.QtQuickControls2",
        "PySide6.QtNetwork",
        # pywin32
        "win32gui", "win32con", "win32api", "win32process", "win32clipboard",
        "win32file", "win32event", "win32security", "winerror",
        "pythoncom", "pywintypes", "win32com", "win32com.client",
        # comtypes
        "comtypes", "comtypes.client", "comtypes.gen",
        "comtypes.server",
        # src 子包 — 自动收集全部子模块，避免手动遗漏
        *collect_submodules("src"),
        # 第三方
        "PIL", "PIL.Image", "PIL.ImageGrab", "markdown", "pyperclip",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[os.path.join(ROOT, "build", "_comtypes_hook.py")],
    excludes=["tkinter", "streamlit"],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

a.binaries = filter_qt_artifacts(a.binaries)
a.datas = filter_qt_artifacts(a.datas)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="五阿哥群发助手",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    icon=icon_path if os.path.exists(icon_path) else None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    name="五阿哥群发助手",
)

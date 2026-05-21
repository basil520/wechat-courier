# -*- coding: utf-8 -*-
"""一键构建脚本 — PyInstaller 打包 + NSIS 安装器"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT_ROOT = os.path.dirname(ROOT)


def main():
    # 1. 预生成 comtypes 包装
    print("步骤 1/3: 预生成 comtypes 包装...")
    subprocess.run(
        [sys.executable, os.path.join(PROJECT_ROOT, "pregen_comtypes.py")],
        cwd=PROJECT_ROOT, check=True,
    )

    # 2. PyInstaller 打包
    print("步骤 2/3: PyInstaller 打包...")
    subprocess.run([
        sys.executable, "-m", "PyInstaller",
        "--name=五阿哥群发助手",
        "--windowed",
        "--noconfirm",
        "--clean",
        os.path.join(ROOT, "build", "build.spec"),
    ], cwd=ROOT, check=True)

    # 3. NSIS 安装器（可选）
    print("步骤 3/3: 构建 NSIS 安装器...")
    nsis_exe = os.environ.get("NSIS_EXE", "makensis")
    nsi_path = os.path.join(ROOT, "installer", "setup.nsi")
    if os.path.exists(nsi_path):
        try:
            subprocess.run([nsis_exe, nsi_path], cwd=ROOT, check=True)
            print(f"\n安装器已生成：{os.path.join(ROOT, 'dist', '五阿哥群发助手_Setup.exe')}")
        except FileNotFoundError:
            print("未找到 NSIS (makensis)，跳过安装器构建。")
            print("如需构建安装器，请安装 NSIS 并将 makensis 加入 PATH。")
    else:
        print("未找到 setup.nsi，跳过安装器构建。")

    print("\n构建完成！")


if __name__ == "__main__":
    main()

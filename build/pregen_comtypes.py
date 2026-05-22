# -*- coding: utf-8 -*-
"""Pregenerates comtypes wrappers to bundle them inside the frozen executable."""

import os
import sys

def main():
    # Set output directory to be 'comtypes_gen' in the repository root
    ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    target_dir = os.path.join(ROOT, "comtypes_gen")
    os.makedirs(target_dir, exist_ok=True)

    print(f"Pregenerating comtypes wrappers into: {target_dir}")
    # 1. 创建 __init__.py 以使其成为有效的包
    with open(os.path.join(target_dir, "__init__.py"), "w", encoding="utf-8") as f:
        f.write("# Generated comtypes wrappers\n")

    # 2. 清除 sys.modules 中缓存的任何 comtypes.gen 子模块
    for mod_name in list(sys.modules.keys()):
        if mod_name.startswith("comtypes.gen"):
            del sys.modules[mod_name]

    # Configure comtypes to generate code into target_dir
    import comtypes.client
    comtypes.client.gen_dir = target_dir
    
    # 3. 强制覆盖 comtypes.gen.__path__，不使用 site-packages 的缓存
    import comtypes.gen
    comtypes.gen.__path__ = [target_dir]
        
    try:
        # Trigger the generation of UIAutomationCore wrappers
        comtypes.client.GetModule("UIAutomationCore.dll")
        print("Successfully pregenerated comtypes wrappers for UIAutomationCore.dll via comtypes.")
    except Exception as e:
        print(f"comtypes generation failed: {e}. Falling back to copy method...", file=sys.stderr)
        
    # 4. Failsafe/备选方案：如果目录依然为空或生成不完全，从系统的 comtypes/gen 复制文件
    try:
        import shutil
        import importlib.util
        comtypes_spec = importlib.util.find_spec("comtypes")
        if comtypes_spec and comtypes_spec.submodule_search_locations:
            src_gen = os.path.join(comtypes_spec.submodule_search_locations[0], "gen")
            if os.path.isdir(src_gen):
                copied = 0
                for item in os.listdir(src_gen):
                    if item.endswith(".py") and item != "__init__.py":
                        src_file = os.path.join(src_gen, item)
                        dst_file = os.path.join(target_dir, item)
                        if not os.path.exists(dst_file):
                            shutil.copy2(src_file, dst_file)
                            copied += 1
                if copied > 0:
                    print(f"Successfully copied {copied} fallback wrapper files from comtypes site-packages cache.")
    except Exception as copy_err:
        print(f"Fallback copy failed: {copy_err}", file=sys.stderr)

    # 验证最终生成的文件数
    generated_files = [f for f in os.listdir(target_dir) if f.endswith(".py")]
    print(f"Total files in comtypes_gen: {generated_files}")
    if len(generated_files) <= 1: # 只有 __init__.py 
        print("Error: No wrapper modules were generated or copied!", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()

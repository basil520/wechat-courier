# WxAuto — 五阿哥群发助手 (PySide6 + QML)

基于 wx4py 核心库的 Windows 桌面群发助手，使用 PySide6 + Qt Quick (QML) 构建。

## 目录结构

```
WxAuto/
├── main.py                 # 应用入口
├── app/                    # Python 后端
│   ├── backend.py          # BackendController — 状态中枢
│   ├── sender_worker.py    # SenderWorker(QThread) — 发送线程
│   ├── models.py           # 数据模型
│   ├── constants.py        # 常量
│   └── demo.py             # 演示模式 mock
├── qml/                    # QML 前端
│   ├── main.qml            # 根窗口
│   ├── App.qml             # 主应用组件
│   ├── components/         # UI 组件
│   └── theme/              # 主题 (颜色/字体/间距)
├── tests/                  # 测试
├── build/                  # PyInstaller 打包
├── installer/              # NSIS 安装器
└── assets/                 # 图标等静态资源
```

## 开发

```bash
# 安装依赖
pip install -r requirements.txt

# 运行
python main.py

# 测试
pytest tests/ -v
```

## 构建

```bash
python build/build.py
```

## 许可

内部工具。

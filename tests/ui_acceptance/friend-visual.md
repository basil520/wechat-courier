# 好友申请页视觉重构验收

日期：2026-10-06。分支：main。产品版本：1.0.0。对照基线：d9297e6。

## 实施范围

- 正式界面改动集中于 `qml/components/FriendWorkspace.qml`，另更新相关测试及虚构数据截图脚本。
- 页头 72px，保留工作区路径、完整标题、下载模板和导入入口。
- 统计、区间选择、已选数量和清空合并为一个工具区；可用宽度达到 1040px 时单行，否则两行。外侧统一 24px，控件 36px，表格行高 40px。
- 完整八列表格继续使用原列宽分配及横向滚动。表头、数据行、悬停和当前记录标记共用宽度；普通文本只在编辑时显示输入边框。
- 勾选只改变复选框；当前定位使用中性底色与橙色边标；输入异常、执行失败和风控保留独立语义。完整错误仍可悬停查看。
- 空表提供本地图标、尚未导入名单及导入入口，不增加模拟记录。
- 全局模板与后缀保持同一编辑行，占位符紧随其下。当前记录独立显示序号、账号、实际打招呼语和备注；窄窗口上下排版。
- 增加窗口内只读完整预览，长文本可滚动、选择及复制，支持 Escape、关闭按钮和任务锁定时关闭。
- 执行栏 64px，左侧为真实状态和请求间隔，右侧为提交提示及“开始申请 N 人”。原有预检文案、二次确认及启动权限判断保留。
- 保留稳定 `objectName`、只读 `friendContentPreview.text` 验收接口、草稿提交和取消、Tab 导航、后缀单击操作、中文菜单及运行锁定。

未修改其他工作区、共享主题、控制器、模型、RPC、QSettings、业务默认值、产品版本、原生毛玻璃、圆角或渲染后端。

## 行为与回归

- 新增布局、分项预览和空表测试，先观察预期失败，再完成实现；补充勾选与当前定位分离、状态标签语义测试。
- 使用真实好友控制器、临时 QSettings、正式 QML 和虚构数据验证编辑、区间选择、后缀、中文菜单、草稿取消、代理复用、预览及运行锁定。
- 相关联测：34 passed；新增状态测试另行通过，亦包含在最终全量回归中。
- `python -m pytest -o addopts= -q --tb=short`：1672 passed，1 skipped，208.46 秒。
- `python tests/run_qml_tests.py`：204 passed，0 failed，0 skipped。
- `python -m compileall -q app tests scripts`、`python -m compileall -q src`：退出码 0。
- `git diff --check`：退出码 0；仅有仓库既有 LF/CRLF 转换提示，无空白错误。
- 独立全量差异审查未发现实质回归；另以离屏 QML 核查非可见行预览、删除/替换/清空、单双行断点及长预览滚动。复核过程未修改文件或调用真实微信。

## 界面验收

`scripts/verify_fuge_ui.py` 使用正式 `qml/main.qml`、真实 BackendController、临时设置和假 RPC；账号发现替换为虚构数据，不连接微信。

- 100%、150%、200% 三档实际窗口 DPR 断言为 1.0、1.5、2.0，每档 81 个截图场景，共 243 个，各档 QML 加载警告为 0。
- 覆盖请求尺寸 960×680、1320×880、1920×1080及实际最大化、深浅主题、两种侧栏状态。Windows 在高 DPI 下会按屏幕可用区域约束实际窗口尺寸，报告保留实际截图像素尺寸。
- 覆盖空表、单行、200 行、长文本、输入异常、执行错误、完整预览、两类任务监控及设置菜单；虚构任务通知不会调用微信。
- 自动检查表格总宽度、表头同步、关键控件完整边界及截图非空；窄窗口保留横向滚动，不缩小字体或最小列宽。
- 已人工查看宽窗口浅色、最小窗口深色、150% 空表/错误和 200% 完整预览/最小窗口。未发现控件重叠或文本侵入相邻区域。
- 原生普通、最大化、恢复时圆角属性，以及毛玻璃可用状态检查保留；本轮不修改这些实现。

## 截图与记录

- [重构前](../../.artifacts/friend-visual/before/friends-light-1320-collapsed.png)
- [重构后](../../.artifacts/friend-visual/native-100-final/friends-light-1320-collapsed.png)
- [窄窗口深色](../../.artifacts/friend-visual/native-100-final/friends-dark-960-expanded.png)
- [空表](../../.artifacts/friend-visual/native-150/friends-empty-light.png)
- [完整预览](../../.artifacts/friend-visual/native-200/friends-full-preview-dark.png)
- 全量回归：`.artifacts/friend-visual/pytest.log`
- QuickTest：`.artifacts/friend-visual/quicktest.log`
- 截图报告：`.artifacts/friend-visual/native-100-final/verification.json`、`native-150/verification.json`、`native-200/verification.json`

截图和执行日志为本机忽略目录中的验收产物，不含真实联系人、申请或消息内容。

## 交付边界

本轮未操作真实微信、发送消息、提交好友申请或读取真实联系人；未 commit、打包或 push。未执行冻结安装包验收。`QtQml.Models` 使用 Qt 自带模块，现有构建输出包含该模块，但不以历史输出代替本轮构建验证。

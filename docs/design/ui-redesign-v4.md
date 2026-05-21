# UI/UX 全面重设计方案 V4（大范围优化）

> 基于对全部 26 个 QML 文件、后端 API、主题系统和 5 张用户截图的深度审查

---

## 一、现有问题深度诊断

### 1.1 布局与结构问题

| # | 问题 | 严重度 | 位置 | 截图 |
|---|------|--------|------|------|
| L1 | **Dashboard 全屏接管过于生硬** — 点击「开始发送」后整个窗口从配置界面滑走，切换到一个空旷的仪表盘页面。进度环 (90×90) + 3 个统计卡片 (160px高) 占了顶部大量空间，下方日志区反而被压缩 | 🔴严重 | `MainLayout.qml` 的两段视差动画; `DashboardView.qml` 整体布局 | 截图2 |
| L2 | **Dashboard 统计卡片过大** — 每个卡片 `fillWidth × 160px`高，仅展示一个图标+一个数字+一行标签，大量空白浪费。3 张卡片水平排列导致在 800px 窗口下非常拥挤 | 🔴严重 | `DashboardView.qml:237-348` GridLayout 3列 | 截图2 |
| L3 | **「返回配置」按钮孤立** — 仅在 `done` 阶段出现，位于底部正中央，体验割裂。用户在发送中无法回看配置 | 🟡中等 | `DashboardView.qml:496-525` | 截图2 |
| L4 | **左右面板无比例控制** — InputPanel 与 PreviewPanel 使用 `Layout.fillWidth` 等分，但 InputPanel 内容密度远高于 PreviewPanel，应给左侧更多空间 | 🟡中等 | `MainLayout.qml:50-68` RowLayout | 截图3 |
| L5 | **SpinBox 使用默认Qt样式** — 外观为灰色系统按钮加边框，与 WeChat 绿色主题完全不搭，且 `implicitWidth: 90` 过宽 | 🟡中等 | `InputPanel.qml:457-488` | 截图1 |
| L6 | **CheckBox 使用默认Qt样式** — 指示器为 16×16 小方块、未经主题化 | 🟡中等 | `InputPanel.qml:396-410` | 截图1 |
| L7 | **底部配置区拥挤且不对齐** — 转发模式 CheckBox + 帮助文本 + 间隔 SpinBox + 按钮全挤在底部区域，行间距仅 4px | 🟡中等 | `InputPanel.qml:380-524` 底部 sticky 区域 | 截图1 |

### 1.2 预览面板问题

| # | 问题 | 严重度 | 位置 |
|---|------|--------|------|
| P1 | **预览面板过于简陋** — 只有一段文字提示 + 好友名/称呼 + 一个气泡 + 文件卡片列表，没有模拟微信对话界面的沉浸感 | 🔴严重 | `PreviewPanel.qml` 全文 |
| P2 | **文件卡片遮挡消息气泡** — WeChatFileCard (56px高) 在预览列表中直接堆叠，多文件时会把消息气泡推到顶部不可见 | 🔴严重 | `PreviewPanel.qml:110-124` Repeater |
| P3 | **WeChatFileCard 尾部箭头多余** — 每个文件卡片右侧有一个 `arrow_down.svg` 14px 图标，语义不明（不可展开也不可下载）| 🟡中等 | `WeChatFileCard.qml:91-96` |
| P4 | **文件卡片图标过大且生硬** — WeChatFileCard 使用 36px 图标，在预览面板中占比过大，视觉上很沉重 | 🟡中等 | `WeChatFileCard.qml:54` iconSize: 36 |
| P5 | **空状态图标使用 Emoji 文字** — `"💬"` 和 `"📋"` 在不同系统渲染效果差异大 | 🟢次要 | `EmptyState.qml`, `PreviewPanel.qml:77`, `DashboardView.qml:447` |

### 1.3 右键菜单问题

| # | 问题 | 严重度 | 位置 |
|---|------|--------|------|
| M1 | **图标语义错误** — 「剪切」使用 `trash.svg`（垃圾桶），「复制」使用 `export.svg`（下载箭头），完全违反直觉 | 🔴严重 | `InputPanel.qml:533,541` |
| M2 | **图标配置不一致** — 「粘贴」没有图标，但「剪切」「复制」有。部分菜单项有图标部分没有，导致文字对齐参差不齐 | 🔴严重 | `InputPanel.qml:547-549` 粘贴无 iconSource |
| M3 | **菜单项左侧图标对齐错位** — 当 `iconSource === ""` 时 WxIcon 的 `visible: false`，导致有图标项和无图标项的文字水平起始位置不同 | 🟡中等 | `WxContextMenuItem.qml:29` visible: root.iconSource !== "" |
| M4 | **缺少标准操作图标 SVG** — 项目图标库中没有 `cut.svg`、`copy.svg`、`paste.svg`、`folder.svg`、`select_all.svg` 等标准操作图标 | 🟡中等 | `qml/icons/` 目录 |

### 1.4 微交互与动画问题

| # | 问题 | 严重度 | 位置 |
|---|------|--------|------|
| A1 | **视差切换动画体验差** — 配置页往左滑出 30% 宽度 + 淡出，仪表盘从右侧 30% 位置滑入。动画只有 200ms 过短，且两个视图之间没有视觉连续性 | 🟡中等 | `MainLayout.qml:28-95` |
| A2 | **ActionButtons 淡入淡出有 bug** — `onPhaseChanged` 触发 `fadeOut`，fadeOut 完成后触发 `fadeIn`，但 StackLayout 的 `currentIndex` 是在 `fadeOut` 开始时就绑定更新的，而不是在淡出过程中保持旧内容 | 🟡中等 | `ActionButtons.qml:121-150` |
| A3 | **呼吸光环在非焦点时残留** — 焦点移走后 glow ring opacity → 0 的 150ms Behavior，但 `SequentialAnimation` 的 `running: parent.activeFocus` 可能在 macOS/某些环境下有延迟 | 🟢次要 | `InputPanel.qml:123-133` |

### 1.5 组件设计问题

| # | 问题 | 严重度 | 位置 |
|---|------|--------|------|
| C1 | **DashboardView 代码臃肿** — 530 行巨型单文件，包含日志模型、时间计算、文件对话框、进度画布、统计卡片、按钮组，职责严重混乱 | 🟡中等 | `DashboardView.qml` 全文 |
| C2 | **InputPanel 代码臃肿** — 633 行巨型单文件，包含好友列表、模板编辑、文件管理、间隔配置、操作按钮、两个右键菜单、确认对话框 | 🟡中等 | `InputPanel.qml` 全文 |
| C3 | **ProgressPanel.qml 为死代码** — 存在但未被任何地方引用。265 行完全浪费 | 🟢次要 | `ProgressPanel.qml` |
| C4 | **TaskSummaryCard.qml 为死代码** — 存在但未被引用。191 行浪费 | 🟢次要 | `TaskSummaryCard.qml` |
| C5 | **主题常量不完整** — DashboardView 中大量硬编码值（margins: 20, spacing: 16, iconSize: 28, pixelSize: 22）未使用 WxTheme | 🟡中等 | `DashboardView.qml` 多处 |
| C6 | **WeChatBubble 气泡尾巴方向固定** — 尾巴始终在左侧，无法表示「我发出的消息」（应在右侧）| 🟢次要 | `WeChatBubble.qml:14-29` |

---

## 二、设计目标与原则

### 2.1 核心目标

1. **消除全屏切换** — 配置和执行状态应在同一界面内共存，用户始终能看到配置概要
2. **信息密度最大化** — 每个像素都有意义，消除空旷区域
3. **微信原生质感** — 预览面板应模拟真实微信对话窗口
4. **一致的精致感** — 所有控件（SpinBox、CheckBox、Menu）统一 WeChat 主题
5. **代码可维护性** — 拆分巨型文件，删除死代码

### 2.2 设计原则

| 原则 | 说明 |
|------|------|
| **不切页** | 发送过程中不做全屏切换，而是在右侧面板内通过 Tab 切换「预览」和「发送状态」|
| **紧凑** | 统计数据用一行横排卡片展示，不要占 160px 高的竖向卡片 |
| **沉浸预览** | 预览面板模拟微信对话窗口：灰色背景 + 头像 + 气泡 + 文件卡片 |
| **控件统一** | 所有 SpinBox、CheckBox、Switch 使用自定义 WeChat 主题组件 |
| **图标语义正确** | 剪切 = scissors, 复制 = copy, 粘贴 = clipboard |

---

## 三、全新布局架构

### 3.1 整体布局（取消全屏 Dashboard 切换）

```
┌────────────────────────────────────────────────────────────────┐
│  [icon] 五阿哥群发助手 v0.2.1              [演示模式] [─][□][×] │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──── 配置区 (55%) ─────┐ │ ┌──── 预览/状态区 (45%) ────┐   │
│  │                        │ │ │                            │   │
│  │  ▸ 好友名单 (1位好友)  │ │ │  [预览]  [发送日志]  tabs  │   │
│  │  ┌──────────────────┐ │ │ │  ─────────────────────────  │   │
│  │  │ 温江              │ │ │ │                            │   │
│  │  │                  │ │ │ │  (预览 tab — 微信对话模拟)   │   │
│  │  └──────────────────┘ │ │ │  ┌────────────────────┐    │   │
│  │                        │ │ │  │  灰色聊天背景       │    │   │
│  │  ▸ 消息模板            │ │ │  │                    │    │   │
│  │  [+ 插入姓名]   6字   │ │ │  │   ┌─ 绿色气泡 ─┐  │    │   │
│  │  ┌──────────────────┐ │ │ │  │   │ 温江你好    │  │    │   │
│  │  │ {name}你好        │ │ │ │  │   └────────────┘  │    │   │
│  │  │                  │ │ │ │  │                    │    │   │
│  │  └──────────────────┘ │ │ │  │   ┌─ 文件卡片 ─┐  │    │   │
│  │                        │ │ │  │   │ 📄 xxx.docx│  │    │   │
│  │  ▸ 附加文件 (1个)     │ │ │  │   └────────────┘  │    │   │
│  │  ┌──────────────────┐ │ │ │  └────────────────────┘    │   │
│  │  │ 📄 DSE测试.docx  🗑│ │ │ │                            │   │
│  │  └──────────────────┘ │ │ │  (日志 tab — 发送时自动切换)  │   │
│  │  [+ 选择文件]         │ │ │  ┌────────────────────┐    │   │
│  │                        │ │ │  │  ✅ 1人 ❌ 0人 ⏱ 09s│    │   │
│  └────────────────────────┘ │ │  │  ──── 进度条 ────── │    │   │
│                              │ │  │  10:30:01 温江 ✅   │    │   │
│  ┌──── 底部操作栏 ──────────────┤  │  10:30:05 张三 ✅   │    │   │
│  │  ☑ 合并转发  间隔 2~3 秒    │  └────────────────────┘    │   │
│  │                  [开始发送]  │                            │   │
│  └──────────────────────────────┴────────────────────────────┘   │
│  支持微信 4.x 版本。使用前请确保电脑已登录并打开微信。          │
└────────────────────────────────────────────────────────────────┘
```

### 3.2 关键变化

| 变化点 | 旧方案 | 新方案 |
|--------|--------|--------|
| 发送时界面 | 整个窗口切换到 DashboardView | 右侧面板内 Tab 切换到「发送日志」页 |
| 统计数据 | 3个 160px 高的卡片 | 日志 Tab 顶部一行紧凑横排指标 |
| 进度显示 | 90px 环形进度 Canvas | Tab 顶部线性进度条 + 百分比文字 |
| 日志列表 | 挤在 DashboardView 中下方 | 占据整个 Tab 内容区，空间充足 |
| 控制按钮 | DashboardView 底部独立区域 | 左面板底部操作栏（始终可见）|
| 预览面板 | 简单文字 + 卡片列表 | 模拟微信对话窗口界面 |
| 返回配置 | 按钮在 Dashboard 底部 | 不需要！配置始终可见 |

### 3.3 右侧面板 Tab 系统

**Tab 1「预览」**（默认激活）：
- 模拟微信对话窗口界面（灰色背景 `#ebebeb`）
- 顶部显示目标好友名称（模拟微信聊天窗口标题栏）
- 绿色气泡（右对齐，模拟「我发出的消息」）
- 文件卡片（微信风格，内嵌在对话流中）
- 如果消息+文件都为空，显示优雅的空状态 SVG 插图

**Tab 2「发送日志」**（发送开始时自动切换）：
- 顶部：紧凑统计行（成功/失败/耗时/进度百分比），高度 ≤ 48px
- 中部：线性进度条（WeChat 绿色，高度 4px，圆角）
- 主体：全高度日志 ListView，每行 LogItem 保持现有样式
- 底部：「导出日志」按钮（仅 done 阶段出现）

---

## 四、组件级详细设计

### 4.1 新增 SVG 图标

需新增以下标准操作图标到 `qml/icons/`：

| 图标文件 | 用途 | 视觉描述 |
|----------|------|----------|
| `cut.svg` | 右键菜单「剪切」 | 剪刀图形，stroke 风格，currentColor |
| `copy.svg` | 右键菜单「复制」 | 两个重叠矩形，stroke 风格，currentColor |
| `paste.svg` | 右键菜单「粘贴」 | 剪贴板 + 文档，stroke 风格，currentColor |
| `folder_open.svg` | 「打开所在文件夹」 | 打开的文件夹，stroke 风格，currentColor |
| `text_cursor.svg` | 「插入姓名占位符」 | 文本光标/T 字形，stroke 风格，currentColor |
| `clear_all.svg` | 「清空」操作 | 横线 + 清除标记，stroke 风格，currentColor |
| `select_all.svg` | 「全选」操作 | 勾选列表，stroke 风格，currentColor |
| `user.svg` | 好友头像占位 | 圆形人像轮廓，fill 风格，灰色 |
| `send.svg` | 发送按钮 | 纸飞机图形，fill 风格，白色 |
| `clock.svg` | 耗时指标 | 时钟图形，stroke 风格，currentColor |

### 4.2 自定义 SpinBox 主题化 — `WxSpinBox.qml`（新建）

```
┌───────────────────────────────────┐
│  [−]  2  [+]                      │  高度: 28px
└───────────────────────────────────┘
```

**设计要点**：
- 整体高度：28px（比默认 Qt SpinBox 矮）
- 整体宽度：72px（比当前 90px 窄）
- 背景：`clBgInput` (#f5f5f5)，圆角 `radiusSmall` (4px)
- 边框：1px `clBorder`，焦点时 `clBorderFocus`
- 减/加按钮：20×28px，无边框，hover 时背景 `clBgHover`
- 文字：居中，`fontSizeSmall` (12px)，`clTextPrimary`
- 加减按钮内容：用 Text "−" / "+" 而非系统默认箭头
- 按钮与数字之间用 1px `clDivider` 分隔
- 动画：按钮 hover 背景色 80ms ColorAnimation

### 4.3 自定义 CheckBox / Switch 主题化 — `WxSwitch.qml`（新建）

考虑到转发模式是一个开关选项，使用 Switch（拨动开关）比 CheckBox 更现代：

```
┌──────────────────────────┐
│  ○━━━━━    合并转发模式   │  关闭态：灰色轨道
│  ━━━━━●   合并转发模式   │  开启态：WeChat 绿色轨道
└──────────────────────────┘
```

**设计要点**：
- 轨道尺寸：36×20px，圆角 10px（全圆角）
- 轨道颜色：关闭 `#dcdfe6`，开启 `clPrimary` (#07c160)
- 滑块：直径 16px 白色圆形，阴影 `0 1px 3px rgba(0,0,0,0.15)`
- 动画：滑块位置 120ms OutQuad，轨道颜色 120ms ColorAnimation
- 标签：紧跟在 Switch 后面，`fontSizeSmall` (12px)

### 4.4 右键菜单图标修正 — 修改 `InputPanel.qml`

**好友名单右键菜单**：
```
┌─────────────────────────┐
│  ✂ 剪切        Ctrl+X  │  图标: cut.svg
│  📋 复制        Ctrl+C  │  图标: copy.svg
│  📄 粘贴        Ctrl+V  │  图标: paste.svg
│  ────────────────────── │
│  🔲 全选        Ctrl+A  │  图标: select_all.svg
│  🗑 清空名单             │  图标: trash.svg (红色)
└─────────────────────────┘
```

**消息模板右键菜单**：
```
┌─────────────────────────┐
│  ✂ 剪切        Ctrl+X  │  图标: cut.svg
│  📋 复制        Ctrl+C  │  图标: copy.svg
│  📄 粘贴        Ctrl+V  │  图标: paste.svg
│  ────────────────────── │
│  T  插入 {name}         │  图标: text_cursor.svg
│  🔲 全选        Ctrl+A  │  图标: select_all.svg
│  🗑 清空模板             │  图标: trash.svg (红色)
└─────────────────────────┘
```

**WxContextMenuItem 图标对齐修复**：
- 当菜单中任何项有图标时，无图标的项也应预留图标宽度（14px + 8px spacing = 22px leftPadding）
- 实现方案：所有项固定左侧留出 `14 + spSmall = 22px` 的图标位，无图标时显示空白 Item 占位

### 4.5 预览面板重设计 — `PreviewPanel.qml`（重写）

**模拟微信对话窗口**：

```
┌─────────────────────────────────┐
│  [预览]  [发送日志]              │  Tab 栏
├─────────────────────────────────┤
│                                 │
│  ┌─────────── 聊天区 ──────────┐│  背景: #ebebeb
│  │        2026年5月21日         ││  日期居中
│  │                             ││
│  │              ┌── 绿色气泡 ──┐││  右对齐（我发的）
│  │              │ 温江你好     │▶││  绿色尾巴在右侧
│  │              └──────────────┘││
│  │                             ││
│  │              ┌── 文件卡片 ──┐││  右对齐
│  │              │📄 DSE.docx  │││
│  │              │   59.4 KB   │││  紧凑文件卡片
│  │              └──────────────┘││
│  │                             ││
│  └─────────────────────────────┘│
│                                 │
│  目标好友: 温江  称呼: 温江     │  底部小字信息
└─────────────────────────────────┘
```

**设计要点**：

1. **聊天背景**：`#ebebeb` 模拟微信聊天背景
2. **消息气泡改为右对齐**：表示「我」发出的消息。尾巴三角在右侧
3. **文件卡片嵌入对话流**：在气泡下方，也右对齐，宽度限制 ≤ 220px
4. **日期标签**：居中灰色圆角标签 "2026年5月21日"
5. **好友信息**：移到底部，以小字灰色显示
6. **文件卡片简化**：
   - 高度降至 44px（从 56px）
   - 图标 24px（从 36px）
   - 移除右侧 `arrow_down` 箭头
   - 圆角 6px
   - 无外阴影（模拟微信原生文件消息样式）
7. **空状态**：使用 `chat_empty.svg` 替代 `"💬"` Emoji

### 4.6 发送日志 Tab — `SendLogPanel.qml`（新建）

```
┌────────────────────────────────────┐
│  [预览]  [发送日志●]               │  发送中 Tab 自动高亮
├────────────────────────────────────┤
│  ✅ 1 人成功  ❌ 0 人失败  ⏱ 00:09 │  紧凑统计行 (36px)
│  ████████████████████░░░░  100%    │  进度条 (4px高) + 百分比
├────────────────────────────────────┤
│  10:30:01  温江    ✅ 发送成功     │
│  10:30:05  张三    ✅ 发送成功     │  日志列表 (填满剩余空间)
│  10:30:09  李四    ❌ 窗口未找到   │
│                                    │
│                                    │
│                                    │
│  ──────────────────────────────── │
│  已完成  发送 3 人，成功 2 / 失败 1│  完成摘要
│                       [导出日志]   │  导出按钮
└────────────────────────────────────┘
```

**设计要点**：

1. **统计行** (36px高)：
   - 水平排列：`✅ N 人成功` + `❌ N 人失败` + `⏱ MM:SS`
   - 使用小圆点图标 (14px SVG) + 数字 + 文字
   - 字号 `fontSizeSmall` (12px)
   - 左侧对齐，间距 `spLarge` (16px)

2. **进度条** (4px高)：
   - 背景：`clDivider` (#ededed)
   - 填充：`clPrimary` (#07c160)
   - 圆角：2px
   - 右侧显示百分比文字
   - 动画：300ms OutCubic

3. **日志列表**：
   - 占据全部剩余空间
   - 复用现有 `LogItem` 组件
   - 自动滚动到底部
   - 右键复制功能保留

4. **完成摘要**（仅 `done` 阶段）：
   - 底部固定区域，高度 44px
   - 显示完成状态文字 + 「导出日志」按钮
   - 渐入动画 200ms

### 4.7 底部操作栏重设计

将底部操作栏从 InputPanel 内部移出，升级为全窗口宽度的固定底部栏：

```
┌────────────────────────────────────────────────────────────┐
│  ⟳ 合并转发   间隔 [2]~[3] 秒        [开始发送 ▶]         │  40px 高
└────────────────────────────────────────────────────────────┘
```

**设计要点**：

1. **高度**：40px（从分散在底部的多行组件 → 单行紧凑布局）
2. **背景**：`clBgSecondary` (#f7f7f7)，顶部 1px `clDivider`
3. **左侧**：Switch + 标签 + 间隔 SpinBox（使用 WxSpinBox）
4. **右侧**：操作按钮（使用现有 ActionButtons，但按钮样式优化）
5. **发送按钮样式升级**：
   - 内容：`▶ 开始发送`（带 play 图标）
   - 尺寸：`padding: 0 24px`，高度 32px
   - 圆角：16px (胶囊形)
   - 背景：WeChat 渐变绿 `linear-gradient(#07c160, #06ad56)`
   - 悬停：微上移 1px + 加深阴影
6. **状态切换**：
   - idle: `[▶ 开始发送]`
   - running: `[⏸ 暂停] [⏹ 停止]`
   - paused: `[▶ 继续] [⏹ 停止]`
   - done: `[↺ 重新开始]`

### 4.8 WeChatFileCard 优化（预览内嵌版）— `WxChatFileCard.qml`（新建）

```
┌─────────────────────────┐
│  📄  DSE测试用例.docx    │  高度: 44px
│      59.4 KB            │  宽度: ≤ 220px
└─────────────────────────┘
```

**与现有 WeChatFileCard 的区别**：
- 高度 44px（降自 56px）
- 图标 24px（降自 36px）
- **移除右侧 arrow_down 箭头**
- 无阴影效果（对话内嵌场景不需要）
- 最大宽度 220px（适配对话流右对齐）
- 背景色：`#ffffff`，圆角 6px，1px 浅边框
- 仅用于预览面板内部

### 4.9 Tab 栏组件 — `WxTabBar.qml`（新建）

```
┌────────────────────────────────┐
│  [预览]     [发送日志]          │  高度: 36px
│   ════                         │  选中态下划线: 2px WeChat绿色
└────────────────────────────────┘
```

**设计要点**：
- Tab 按钮高度：36px
- 选中标识：底部 2px WeChat 绿色下划线，带 120ms 滑动动画
- 未选中：`clTextSecondary`，选中：`clTextPrimary` + `bold`
- Tab 切换动画：内容区域使用 SwipeView 或 StackLayout + opacity 渐变
- 发送日志 Tab 有可选的通知圆点（新日志到来时闪烁）

### 4.10 StatusBar 优化

将状态栏从顶部移到底部（模拟 VSCode/现代应用的底部状态栏模式）：

```
┌────────────────────────────────────────────────────────────┐
│  支持微信 4.x  │  ⚠ 演示模式  │            v0.2.1        │  24px 高
└────────────────────────────────────────────────────────────┘
```

**设计要点**：
- 高度降至 24px（从 36px）
- 字号 11px
- 移至窗口底部最底层
- 左侧：提示文字
- 右侧：版本号
- 如有演示模式标记，中间显示

---

## 五、主题系统升级 — `WxTheme.qml` 修改

### 5.1 新增主题常量

```qml
// ── 新增颜色 ──
readonly property color clChatBg: "#ebebeb"          // 微信聊天背景色
readonly property color clTabActive: "#07c160"        // Tab 选中下划线
readonly property color clTabInactive: "#999999"      // Tab 未选中文字
readonly property color clProgressTrack: "#e9e9e9"    // 进度条轨道
readonly property color clSwitchTrack: "#dcdfe6"      // Switch 关闭态轨道
readonly property color clSwitchThumb: "#ffffff"      // Switch 滑块

// ── 新增字号 ──
readonly property int fontSizeXSmall: 10              // 超小字（状态栏）
readonly property int fontSizeTitle: 15               // 标题字号

// ── 新增尺寸 ──
readonly property int controlHeight: 28               // 统一控件高度（SpinBox, Button 等）
readonly property int tabHeight: 36                   // Tab 栏高度
readonly property int statusBarHeight: 24             // 状态栏高度
readonly property int actionBarHeight: 40             // 底部操作栏高度
readonly property int chatBubbleMaxWidth: 260         // 气泡最大宽度
readonly property int chatFileCardMaxWidth: 220       // 文件卡片最大宽度
readonly property int chatFileCardHeight: 44          // 文件卡片高度

// ── 新增间距 ──
readonly property int spXLarge: 20                    // 超大间距
```

### 5.2 修正现有使用硬编码值的位置

将 DashboardView 中所有硬编码 `margins: 20`, `spacing: 16`, `iconSize: 28` 等替换为主题常量引用。

---

## 六、交互逻辑重设计

### 6.1 核心交互流程

```
用户启动应用
    ↓
[配置阶段 - idle]
    ├── 左面板: 编辑好友/模板/文件
    ├── 右面板: 「预览」Tab 实时显示效果
    ├── 底部栏: 配置参数 + [开始发送]
    ↓
用户点击 [开始发送]
    ↓
[确认弹窗]
    ├── "即将向 N 位好友发送消息，共 M 个文件。是否继续？"
    ├── [确认发送] / [取消]
    ↓
[发送阶段 - running]
    ├── 左面板: 配置区 **灰化但可见**（inputsEnabled: false）
    ├── 右面板: 自动切换到「发送日志」Tab
    │   ├── 统计行实时更新
    │   ├── 进度条动画前进
    │   └── 日志列表自动滚动
    ├── 底部栏: [暂停] [停止]
    ↓
用户点击 [暂停]
    ↓
[暂停阶段 - paused]
    ├── 进度条停止，统计行显示「已暂停」
    ├── 底部栏: [继续] [停止]
    ↓
发送完成 / 用户停止
    ↓
[完成阶段 - done]
    ├── 左面板: 配置区 **恢复可编辑**
    ├── 右面板: 「发送日志」Tab 显示完成摘要 + 导出按钮
    ├── 底部栏: [重新开始]
    ├── 用户可自由切换回「预览」Tab 查看配置
    ↓
用户点击 [重新开始]
    ↓
[回到 idle]
    ├── 清空日志数据
    ├── 右面板自动切回「预览」Tab
```

### 6.2 Tab 自动切换逻辑

| 触发条件 | Tab 行为 |
|----------|----------|
| idle → running | 自动切换到「发送日志」Tab |
| done → idle (reset) | 自动切回「预览」Tab |
| 用户手动点击 Tab | 任何阶段都可自由切换 |
| running/paused 中点击「预览」| 允许查看预览（日志继续在后台累积）|

### 6.3 配置区灰化（发送中）

发送开始后，左面板所有输入控件设为 `enabled: false`，视觉效果：
- 文本域：背景变浅 `opacity: 0.6`，不可编辑
- 按钮：隐藏「+ 选择文件」等操作按钮
- 文件列表：隐藏删除图标
- 整体叠加一层 0.03 透明度遮罩 indicating read-only

### 6.4 右键菜单增强

所有右键菜单统一增加「全选」操作，确保图标完整一致：

| 菜单项 | 图标 | 快捷键 | 可用条件 |
|--------|------|--------|----------|
| 剪切 | `cut.svg` | Ctrl+X | 有选中文字 |
| 复制 | `copy.svg` | Ctrl+C | 有选中文字 |
| 粘贴 | `paste.svg` | Ctrl+V | 剪贴板有内容 |
| 全选 | `select_all.svg` | Ctrl+A | 文本不为空 |
| ─── | | | |
| 清空名单/模板 | `trash.svg` (红) | — | 文本不为空 |
| 插入 {name} | `text_cursor.svg` | — | 仅模板菜单 |

---

## 七、动画系统优化

### 7.1 移除的动画

| 动画 | 原因 |
|------|------|
| MainLayout 视差滑动 | 取消全屏切换，不再需要 |
| Dashboard 进度环 Canvas | 用线性进度条替代 |
| 启动加载 spinner (800ms) | 过长，缩短至 400ms |

### 7.2 新增/优化的动画

| 动画 | 属性 | 时长 | 缓动 | 触发条件 |
|------|------|------|------|----------|
| Tab 下划线滑动 | x position | 150ms | OutQuad | 切换 Tab |
| Tab 内容切换 | opacity | 120ms | — | 切换 Tab |
| 发送日志 Tab 通知点 | opacity 闪烁 | 500ms | InOutSine | 新日志到来（当用户在预览 Tab 时）|
| Switch 滑块移动 | x position | 120ms | OutQuad | 切换开关 |
| Switch 轨道颜色 | color | 120ms | — | 切换开关 |
| SpinBox 按钮 hover | background color | 80ms | — | 鼠标进入/离开 |
| 进度条增长 | width | 300ms | OutCubic | 进度更新 |
| 底部栏按钮切换 | opacity cross-fade | 150ms | OutQuad | phase 变化 |
| 统计数字跳动 | scale pulse | 200ms | OutBack | 数字变化时 |
| 完成摘要栏 | opacity + slideUp | 200ms | OutCubic | done 阶段出现 |

### 7.3 保留的动画

- TextArea 焦点呼吸光环（1500ms 脉冲）
- 文件项删除收缩（150ms）
- WeChatFileCard hover 提升（120ms）
- WxContextMenu 缩放+淡入（200ms）
- WxContextMenuItem hover 高亮（80ms）
- WxIcon hover 缩放（120ms）
- Toast 淡入淡出（200ms）
- ConfirmDialog 缩放弹出（200ms OutBack）

---

## 八、代码架构优化

### 8.1 文件变更清单

| 操作 | 文件 | 说明 |
|------|------|------|
| **新建** | `qml/components/WxSpinBox.qml` | 自定义 WeChat 主题 SpinBox |
| **新建** | `qml/components/WxSwitch.qml` | 自定义 WeChat 主题 Switch |
| **新建** | `qml/components/WxTabBar.qml` | Tab 栏组件 |
| **新建** | `qml/components/WxChatFileCard.qml` | 预览内嵌用小尺寸文件卡片 |
| **新建** | `qml/components/SendLogPanel.qml` | 发送日志面板（从 DashboardView 拆分）|
| **新建** | `qml/components/RightPanel.qml` | 右侧面板容器（含 Tab 栏 + 预览/日志切换）|
| **新建** | `qml/components/ActionBar.qml` | 全窗口底部操作栏 |
| **新建** | `qml/components/ChatPreview.qml` | 微信对话模拟预览（从 PreviewPanel 重写）|
| **修改** | `qml/components/MainLayout.qml` | 移除视差切换，改为稳定两列布局 + 底部操作栏 |
| **修改** | `qml/components/InputPanel.qml` | 移出底部操作按钮/配置至 ActionBar；修正右键菜单图标 |
| **修改** | `qml/components/WxContextMenuItem.qml` | 固定图标占位对齐 |
| **修改** | `qml/components/WeChatBubble.qml` | 支持右对齐（尾巴在右侧）|
| **修改** | `qml/components/WeChatFileCard.qml` | 移除 arrow_down，可选隐藏阴影 |
| **修改** | `qml/components/EmptyState.qml` | 用 SVG 替代 Emoji |
| **修改** | `qml/components/StatusBar.qml` | 降高到 24px，增加版本号右对齐 |
| **修改** | `qml/components/App.qml` | 调整布局顺序（StatusBar 移到底部）|
| **修改** | `qml/theme/WxTheme.qml` | 新增上述主题常量 |
| **修改** | `app/generate_svgs.py` | 新增 cut/copy/paste/folder_open 等图标 |
| **删除** | `qml/components/DashboardView.qml` | 功能拆分到 SendLogPanel，不再需要 |
| **删除** | `qml/components/ProgressPanel.qml` | 死代码 |
| **删除** | `qml/components/TaskSummaryCard.qml` | 死代码 |
| **删除** | `qml/components/PreviewPanel.qml` | 由 ChatPreview + RightPanel 替代 |

### 8.2 组件依赖关系（新架构）

```
ApplicationWindow (main.qml)
├── App.qml
│   ├── ColumnLayout
│   │   ├── MainLayout (占满剩余空间)
│   │   │   ├── RowLayout
│   │   │   │   ├── InputPanel (55% 宽)
│   │   │   │   │   ├── 好友名单 TextArea + WxContextMenu
│   │   │   │   │   ├── 消息模板 TextArea + TemplateToolbar + WxContextMenu
│   │   │   │   │   └── 文件列表 ListView → FileItem → WxContextMenu
│   │   │   │   ├── 竖分隔线
│   │   │   │   └── RightPanel (45% 宽)
│   │   │   │       ├── WxTabBar [预览 | 发送日志]
│   │   │   │       ├── StackLayout
│   │   │   │       │   ├── ChatPreview (Tab 0)
│   │   │   │       │   │   ├── WeChatBubble (右对齐)
│   │   │   │       │   │   └── WxChatFileCard × N
│   │   │   │       │   └── SendLogPanel (Tab 1)
│   │   │   │       │       ├── 统计行
│   │   │   │       │       ├── 进度条
│   │   │   │       │       ├── ListView → LogItem
│   │   │   │       │       └── 完成摘要 + 导出
│   │   │   │       └── 底部好友信息
│   │   │   └── ActionBar (固定底部)
│   │   │       ├── WxSwitch (合并转发)
│   │   │       ├── WxSpinBox × 2 (间隔)
│   │   │       └── ActionButtons
│   │   └── StatusBar (24px, 最底部)
│   └── ConfirmDialog
├── Toast
└── startupLoader
```

---

## 九、实施计划（分阶段）

### Phase 1：基础组件与图标（预计 1 小时）
1. 新增 SVG 图标（cut, copy, paste, folder_open, text_cursor, clear_all, select_all, user, send, clock）
2. 创建 `WxSpinBox.qml` 自定义主题 SpinBox
3. 创建 `WxSwitch.qml` 自定义主题 Switch
4. 创建 `WxTabBar.qml` Tab 栏组件
5. 更新 `WxTheme.qml` 新增常量
6. 修复 `WxContextMenuItem.qml` 图标对齐占位

### Phase 2：右侧面板重构（预计 1.5 小时）
1. 创建 `ChatPreview.qml`（微信对话模拟预览）
2. 修改 `WeChatBubble.qml` 支持右对齐
3. 创建 `WxChatFileCard.qml`（预览用小尺寸文件卡片）
4. 创建 `SendLogPanel.qml`（从 DashboardView 提取日志/统计/进度逻辑）
5. 创建 `RightPanel.qml`（Tab 容器，组合预览和日志）

### Phase 3：布局重构（预计 1 小时）
1. 创建 `ActionBar.qml`（底部操作栏）
2. 重写 `MainLayout.qml`（移除视差切换，稳定两列 + 底部栏）
3. 重构 `InputPanel.qml`（移出底部控件到 ActionBar）
4. 修改 `App.qml`（StatusBar 移底，集成新 MainLayout）
5. 修改 `StatusBar.qml`（降高，增加版本号）

### Phase 4：右键菜单与交互修正（预计 45 分钟）
1. 修正好友列表右键菜单图标（cut/copy/paste + 全选）
2. 修正模板右键菜单图标（cut/copy/paste + 全选 + 插入姓名）
3. 添加 Tab 自动切换逻辑（idle→running 自动到日志 Tab）
4. 添加配置区灰化逻辑
5. 修改 `EmptyState.qml` 用 SVG 替代 Emoji

### Phase 5：清理与验证（预计 30 分钟）
1. 删除 `DashboardView.qml`、`ProgressPanel.qml`、`TaskSummaryCard.qml`
2. 删除旧 `PreviewPanel.qml`
3. 更新 QML 测试用例
4. 运行完整 pytest 套件确保 86/86 通过
5. 手动验证 800×650 最小分辨率

---

## 十、验证清单

### 自动化验证
- [ ] `pytest` 全部 86 测试通过
- [ ] QML 测试套件（tst_ActionButtons, tst_LayoutValidation, tst_WxTheme, tst_Sanity）全部通过
- [ ] 零控制台警告

### 手动验证矩阵

| 验证项 | 预期结果 |
|--------|----------|
| 800×650 最小窗口 | 所有内容可见，无截断 |
| 960×780 默认窗口 | 布局舒适，比例协调 |
| 1920×1080 大窗口 | 优雅拉伸，不变形 |
| 输入好友名单 | 预览 Tab 实时更新对话模拟 |
| 输入消息模板 | 绿色气泡实时预览 |
| 添加文件 | 文件卡片在对话流中右对齐显示 |
| 右键好友文本域 | 菜单弹出，图标对齐正确，快捷键显示 |
| 右键模板文本域 | 菜单弹出，含「插入 {name}」项 |
| 右键文件列表项 | 菜单弹出，打开文件/文件夹正常工作 |
| 点击「开始发送」 | 弹出确认对话框 |
| 确认发送 | 右侧自动切到「发送日志」Tab，日志实时滚动 |
| 发送中点击「预览」Tab | 可以查看预览，日志继续累积 |
| 发送中点击「暂停」 | 进度暂停，按钮切换为「继续」|
| 发送完成 | 底部栏显示「重新开始」，日志 Tab 显示完成摘要 |
| 点击「重新开始」 | 自动切回「预览」Tab，日志清空 |
| Switch 切换转发模式 | 滑块平滑滑动，颜色渐变 |
| SpinBox 调整间隔 | 外观 WeChat 主题化，交互流畅 |

---

## 附录 A：配色参考

保持现有 WeChat 绿色为主色调，新增以下辅助色：

```
主色系:       #07c160 (WeChat Green)
悬停:         #06ad56
按下:         #059a4c
禁用:         #a0e6b9

背景系:       #ffffff (主背景)
              #f7f7f7 (次要背景/ActionBar)
              #f5f5f5 (输入框/窗体)
              #ebebeb (聊天背景)

文字系:       #191919 (主文字)
              #666666 (次要文字)
              #999999 (提示文字)

边框系:       #e5e5e5 (默认边框)
              #ededed (分隔线)
              #07c160 (焦点边框)

危险系:       #fa5151 (错误/危险)
              #f13e3a (错误悬停)
```

## 附录 B：关键尺寸参考

```
窗口:         960×780 (默认), 800×650 (最小)
面板比例:     左 55% : 右 45%
ActionBar:    40px 高
StatusBar:    24px 高
Tab 栏:       36px 高
控件高度:     28px (SpinBox, 小按钮)
              32px (主操作按钮)
文件项:       32px (配置列表)
              44px (聊天预览卡片)
气泡最大宽:   260px
文件卡片最大宽: 220px
进度条高度:   4px
图标尺寸:     14px (菜单/行内), 20px (列表图标), 24px (文件卡片)
```

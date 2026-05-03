# STATUS — 当前开发状态

> **这份文件回答**："现在停在哪？下一步做什么？什么卡住了？"
>
> **特性**：**瞬时状态**。**硬上限 ~80 行**。可以放心覆写。
> 有价值的内容沉淀到 `MAP.md`（结构变化）或 `DECISIONS.md`（决策原因）**之后**再覆写。
>
> **谁该读**：每次开新会话。

---

## 现在在做什么

🎉 **Phase 1 闭环**（2026-05-03）。VoxAI 第一次成为可启动的 app——所有工程任务完成（1.1 + 1.4-1.7），代码量约 1100 行 Swift，二进制 Release universal 1.1MB。

下一步：Apple Silicon 真机测试——⌘R 在 Xcode 里跑一下，验证"用嘴编程"主流程闭环（启动 → 录音 → 停止 → 自动复制 → 切 Claude → 粘贴）。

## 下一步

1. **Apple Silicon 真机测试** —— Rebecca 用 Xcode 打开项目 ⌘R 跑一次：
   - 第一次启动会弹麦克风 + 语音识别权限弹窗，授予
   - 看到悬浮窗（顶部右侧默认位置，420×420）
   - 点麦克风按钮 → 说几句中文（含技术术语，比如"解释一下这个函数的递归边界"）
   - 看歌词渲染是否流畅
   - 点停止 → 验证标题栏闪 "已复制" + 切 Claude ⌘V 验证内容到了
   - 点 MenuBarExtra 图标看菜单栏
   - 关闭浮窗 → 从 MenuBarExtra "显示浮窗 / Show Dialog" 重开
2. **Phase 2 启动**（待 Apple Silicon 验证通过后）——TTS + MCP server + 完整 Settings
3. **Phase 1 末尾 Intel Mac 实测**（Phase 3.1 集中做）

完整任务表见 `topics/planning/ROADMAP.md`。

## 卡点 / 待确认

- 🟡 等 Rebecca 在 Xcode 里 ⌘R 跑一次验证浮窗 / 录音 / 自动复制
- 🟡 Phase 2.2 SystemTTSEngine 完成后，需要 Rebecca 试听 5-10 段典型 AI 输出（中英混杂、技术术语）判断 v1 中文音质是否"够用"
- 🟡 Phase 1 末尾 Intel Mac 实测——录音 / 续接 / 自动复制功能跨架构验

## 未提交的改动

无。最新 commit 即将是 Phase 1.7。

## 最近一次会话做了什么

2026-05-03 这次会话（**完成 Phase 1 全部工程任务**）：

**Phase 1.1**：Xcode GUI 创建空项目 → Sage 接管所有配置（deployment target 13.0 / Bundle ID 全小写 / DEVELOPMENT_TEAM 切到付费 Team / entitlements / Info.plist 隐私描述 / LSUIElement）；R-006 risk 消解

**事实校正**：通过 keychain 证据链发现 `JK89RW5Q4H` 是美区 Apple ID `g266835@icloud.com` 的 Personal Team（不是付费 Team `YNMBJ5H736` 同账号的 Personal）。L2 + brain/SANDBOX.md 同步更新双账号架构

**Phase 1.4 AppSettings**：220 行 ObservableObject + @Published；9 个 UserDefaults 字段；Cloud API Key Keychain stub；自动复制默认 true（DR-020）；学到 Swift 6 strict mode 需显式 `import Combine`

**Phase 1.5 TranscriptionService**：320 行；从 VoxSage 移植 sessionGeneration 防过期回调；砍掉会议模式整套 + spawn Python；**跨架构 silenceLimit 修正**（VoxSage 写死 43.0 在 48kHz Intel Mac 偏差 ~10%）；@MainActor + audio tap 用 captured locals + Task @MainActor 兼容 Swift 6 concurrency；加 TranscriptionError + lastError + onStopped 钩子

**Phase 1.6 DialogView**：530 行；v1 产品脸面三态 UI（idle 空 / recording-paused / idle 但 transcript 非空）；DR-020 自动复制集成（onAppear 接 ts.onStopped 写 NSPasteboard + 标题栏闪 "已复制" 标签）；砍掉 VoxSage 会议模式整套；权限拒绝弹 alert；`.onChange(of:_:)` 单参兼容 macOS 13

**Phase 1.7 VoxAIApp**：3 Scenes（dialog WindowGroup + Settings 占位 + MenuBarExtra）；MenuBarExtra 状态感知图标 + Show Dialog（⇧⌘D）+ Quit（⌘Q）+ 状态行；删除默认 ContentView.swift；单实例锁延后到 Phase 2.5；Release universal 1.1MB

**累积 Swift 6 工程经验**（commit message 与 STATUS 同步过）：
1. `import SwiftUI` 不再隐式带 Combine
2. @MainActor 静态属性不能做 default argument
3. `.onChange(of:_,_:)` 双参版是 macOS 14+，13.0 用单参
4. Xcode DEVELOPMENT_TEAM 默认跟系统 iCloud 走，每次新 Apple 项目要手动切到付费 Team

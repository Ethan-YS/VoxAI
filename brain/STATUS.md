# STATUS — 当前开发状态

> **这份文件回答**："现在停在哪？下一步做什么？什么卡住了？"
>
> **特性**：**瞬时状态**。**硬上限 ~80 行**。可以放心覆写。
> 有价值的内容沉淀到 `MAP.md`（结构变化）或 `DECISIONS.md`（决策原因）**之后**再覆写。
>
> **谁该读**：每次开新会话。

---

## 现在在做什么

**Phase 1.5 完成**（2026-05-03）。`TranscriptionService` 已从 VoxSage 移植并适配 VoxAI Sandbox + Swift 6 concurrency + 跨架构 sampleRate 修正，Debug + Release universal binary 验证通过。

下一步：Phase 1.6 `DialogView`——v1 产品脸面，悬浮窗 + 歌词渲染 + 录音停止后自动复制剪贴板（DR-020 主推卖点）。

## 下一步

按 ROADMAP Phase 1 余下任务：

1. **Phase 1.6 DialogView**（产品脸面）—— `VoxAI/Views/DialogView.swift`，悬浮窗 + 歌词渲染 + **录音停止后自动复制到剪贴板**（DR-020）+ 录音/暂停/停止/清空控制条 + 手动复制按钮兜底
2. **Phase 1.7 VoxAIApp.swift**（入口）—— 3 Scenes（dialog WindowGroup + settings Window + MenuBarExtra）+ 单实例锁防多开 + 启动时拉起 dialog 浮窗
3. **Phase 1 末尾 Intel Mac 实测**

完整任务表见 `topics/planning/ROADMAP.md`。

## 卡点 / 待确认

- 🟡 Phase 1 末尾 Intel Mac 实测——录音 / 续接 / 自动复制功能跨架构验
- 🟡 Phase 1.5/2.2 SystemTTSEngine 完成后，需要 Rebecca 试听 5-10 段典型 AI 输出（中英混杂、技术术语）判断 v1 中文音质是否"够用"

## 未提交的改动

无。最新 commit 是 Phase 1.5。

## 最近一次会话做了什么

2026-05-03 这次会话：

**Phase 1.4 AppSettings**：
- 创建 `VoxAI/Models/AppSettings.swift`（约 220 行）：`ObservableObject` + `@Published`（macOS 13 不支持 @Observable，DR-005）；9 个 UserDefaults 字段；Cloud API Key Keychain stub；`resetToDefaults()` 方法；所有 key 加 `voxai.` 前缀
- **Swift 6 工程经验 #1**：`import SwiftUI` 不再隐式导入 Combine——用 `ObservableObject` / `@Published` 必须显式 `import Combine`

**Phase 1.5 TranscriptionService**：
- 创建 `VoxAI/Services/TranscriptionService.swift`（约 320 行）：从 VoxSage 移植 `sessionGeneration` 防过期回调机制
- 砍掉：会议模式全套（`isDialogMode` / `meetingAudioFile` / `lastMeetingAudioPath` / `startMeetingListening` / `closeMeetingAudioFile` / `onSegmentCommitted`）/ spawn Python（`startMCPServer` / `findProjectRoot`）/ NSWindow 持有
- **跨架构修正**：`silenceLimit` 从 `inputNode.outputFormat(forBus:0).sampleRate / bufferSize` 实时计算（VoxSage 写死 43.0 在 48kHz Intel Mac 偏差 ~10%）
- 加 `TranscriptionError` enum + `lastError` @Published（不再 try? 静默吞错误）
- 加 `requestPermissions()` 同时请求 Speech + Microphone（macOS 14+ 严格了麦克风权限）
- 加 `onStopped` 钩子供 DialogView 触发自动复制（DR-020）
- **Swift 6 工程经验 #2**：default argument expression（如 `init(settings: AppSettings = .shared)`）在 nonisolated context 求值，引用 `@MainActor` 静态 `.shared` 会触发警告——v1 决定不用默认参数，调用方显式传 `.shared`

会话上半段（Phase 1.1 + 事实校正）：详见 git log（commit f145940 / 7dd290d / a3596ed / f16dbc1）

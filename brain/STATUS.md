# STATUS — 当前开发状态

> **这份文件回答**："现在停在哪？下一步做什么？什么卡住了？"
>
> **特性**：**瞬时状态**。**硬上限 ~80 行**。可以放心覆写。
> 有价值的内容沉淀到 `MAP.md`（结构变化）或 `DECISIONS.md`（决策原因）**之后**再覆写。
>
> **谁该读**：每次开新会话。

---

## 现在在做什么

**Phase 1.4 完成**（2026-05-03）。`AppSettings` 已实现，9 个 UserDefaults 字段就位，Keychain stub 留 Phase 2.4，Debug + Release universal binary 验证通过。

下一步：Phase 1.5 `TranscriptionService`——重头戏，从 VoxSage 移植 ASR + sessionGeneration。

## 下一步

按 ROADMAP Phase 1 余下任务：

1. **Phase 1.5 TranscriptionService**（重头）—— `VoxAI/Services/TranscriptionService.swift`，从 VoxSage 移植 `sessionGeneration` 防过期回调机制。**关键：`silenceLimit` 必须从 `inputNode.outputFormat(forBus: 0).sampleRate` 计算**，不能写死，否则 Intel Mac 跨架构会偏差。砍掉所有会议模式 / `findProjectRoot` / spawn Process 痕迹
2. **Phase 1.6 DialogView**（产品脸面）—— `VoxAI/Views/DialogView.swift`，悬浮窗 + 歌词渲染 + **录音停止后自动复制到剪贴板**（DR-020 主推卖点）+ Settings 给开关
3. **Phase 1.7 VoxAIApp.swift**（入口）—— 3 Scenes（dialog WindowGroup + settings Window + MenuBarExtra）+ 单实例锁防多开
4. **Phase 1 末尾 Intel Mac 实测**

完整任务表见 `topics/planning/ROADMAP.md`。

## 卡点 / 待确认

- 🟡 Phase 1 末尾 Intel Mac 实测——录音 / 续接 / 自动复制功能跨架构验
- 🟡 Phase 1.5/2.2 SystemTTSEngine 完成后，需要 Rebecca 试听 5-10 段典型 AI 输出（中英混杂、技术术语）判断 v1 中文音质是否"够用"

## 未提交的改动

无。最新 commit 是 fact correction（JK89RW5Q4H 归属校正）。

## 最近一次会话做了什么

2026-05-03 这次会话（Phase 1.4 部分）：
- 创建 `VoxAI/Models/AppSettings.swift`（约 220 行）：`ObservableObject` + `@Published` 模式（macOS 13 不支持 @Observable，DR-005）；9 个 UserDefaults 字段；Cloud API Key Keychain stub；`resetToDefaults()` 方法；所有 key 加 `voxai.` 前缀
- **Swift 6 工程经验**：`import SwiftUI` 不再隐式导入 Combine——用 `ObservableObject` / `@Published` 必须显式 `import Combine`，这是 Swift 6 strict concurrency 模式下的变化（之前老代码靠隐式带入）
- Debug build + Release universal binary（arm64+x86_64）双双验证通过

---

会话上半段（Phase 1.1 + 事实校正）：
- Phase 1.1 全程：Xcode 创建空项目（Rebecca）+ Sage 接管所有配置
- 改 project.pbxproj：deployment target 26.4 → 13.0；Bundle ID 大写 → 全小写；`DEVELOPMENT_TEAM` 从美区免费 Personal Team `JK89RW5Q4H` 切到中国付费 Apple Developer Program Team `YNMBJ5H736`；移除 `ENABLE_USER_SELECTED_FILES` / `REGISTER_APP_GROUPS`；加 entitlements 引用 + INFOPLIST_KEY_*
- 创建 `VoxAI/VoxAI.entitlements`：sandbox + audio-input + network.client + network.server
- risk R-006（Xcode universal bug）从 🟡 改 🟢 已消解
- **重大事实校正**：`JK89RW5Q4H` 是美区 Apple ID `g266835@icloud.com` 的 Personal Team，不是 `YNMBJ5H736` 同账号的 Personal Team——L2 个人档案 + brain/SANDBOX.md 同步更新双账号架构

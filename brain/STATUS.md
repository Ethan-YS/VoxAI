# STATUS — 当前开发状态

> **这份文件回答**："现在停在哪？下一步做什么？什么卡住了？"
>
> **特性**：**瞬时状态**。**硬上限 ~80 行**。可以放心覆写。
> 有价值的内容沉淀到 `MAP.md`（结构变化）或 `DECISIONS.md`（决策原因）**之后**再覆写。
>
> **谁该读**：每次开新会话。

---

## 现在在做什么

**Phase 1.1 完成**（2026-05-03）。Xcode 工程骨架已建立，entitlements + Info.plist 配置就位，universal binary 双架构验证通过。risk R-006（Xcode universal bug）已消解。

下一步：进入 Phase 1.4-1.7 写实际代码。

## 下一步

按 ROADMAP Phase 1 余下任务，建议顺序：

1. **Phase 1.4 AppSettings**（轻，先打地基）—— `Models/AppSettings.swift`，`@AppStorage` 包装识别语言 / TTS 引擎 / Cloud 配置 / 语速等；API Key 用 Keychain（Phase 2.4 才用，1.4 先留 stub）
2. **Phase 1.5 TranscriptionService**（重头）—— `Services/TranscriptionService.swift`，从 VoxSage 的 ASR 实现移植 `sessionGeneration` 防过期回调机制。**关键：`silenceLimit` 必须从 `inputNode.outputFormat(forBus: 0).sampleRate` 计算**，不能写死，否则 Intel Mac 跨架构会偏差。砍掉所有会议模式 / `findProjectRoot` / spawn Process 痕迹
3. **Phase 1.6 DialogView**（产品脸面）—— `Views/DialogView.swift`，悬浮窗 + 歌词渲染 + **录音停止后自动复制到剪贴板**（DR-020 主推卖点）+ Settings 给开关
4. **Phase 1.7 VoxAIApp.swift**（入口）—— 3 Scenes（dialog WindowGroup + settings Window + MenuBarExtra）+ 单实例锁防多开

完整 Phase 1 任务表见 `topics/planning/ROADMAP.md`。

## 卡点 / 待确认

- 🟡 Phase 1.5 SystemTTSEngine 完成后，需要 Rebecca 试听 5-10 段典型 AI 输出（中英混杂、技术术语）判断 v1 中文音质是否"够用"——非阻塞但影响 v1 体验
- 🟡 Phase 1 末尾 Intel Mac 实测——`Developer/VoxAI/` 目录里的 archive 跑到 Intel Mac 上验录音 / 续接 / 自动复制功能

## 未提交的改动

无。最新 commit 是 brain/ 状态更新。

## 最近一次会话做了什么

2026-05-03 这次会话：
- Phase 1.1 全程：Xcode 26.4.1 GUI 创建空项目（Rebecca 选保存到桌面避免覆盖现有 brain/）；Sage 用命令行搬到 `Developer/VoxAI/`、清桌面、补 `.gitignore`
- 改 project.pbxproj：deployment target 26.4 → 13.0；Bundle ID 大写 → 全小写对应 Apple Developer Portal 锁定的；DEVELOPMENT_TEAM 从 Personal Team 切到 paid Apple Developer Program Team `YNMBJ5H736`；移除 v1 不需要的 `ENABLE_USER_SELECTED_FILES` / `REGISTER_APP_GROUPS`；加 `CODE_SIGN_ENTITLEMENTS` 引用；加 INFOPLIST_KEY_NSMicrophoneUsageDescription / NSSpeechRecognitionUsageDescription（中文）/ LSUIElement = YES（菜单栏 app 模式，不显示 Dock 图标）
- 创建 `VoxAI/VoxAI.entitlements`：sandbox + audio-input + network.client + network.server
- `xcodebuild Release ARCHS='arm64 x86_64' CODE_SIGNING_ALLOWED=NO` build 通过；`lipo -info` 验证 universal binary 双 slice
- risk R-006（Xcode universal bug）从 🟡 改 🟢 已消解
- ROADMAP Phase 1 进度更新

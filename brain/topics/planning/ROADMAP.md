# ROADMAP — VoxAI 工程节奏

> **这份文件回答**：v1.0 上架要分几个 Phase 跑？每个 Phase 的 DoD 是什么？依赖关系？
>
> **谁该读**：开始一个新 Phase 时；估工期 / 评估卡点时；和 Rebecca 同步进度时。
> **不该读**：找产品规格 → 看 `brain/PROJECT.md` + `topics/systems/`；找具体决策原因 → 看 `brain/DECISIONS.md`。

---

## 总览

**总工期估算**：约 4 周（基于 Cloud TTS 改 OpenAI 兼容协议后的修订）

| Phase | 时长 | 核心目标 | 阻塞下一阶段？ |
|---|---|---|---|
| **0. 技术风险验证** | 1.5 天（实际 ~1 小时） | MCP HTTP server + 双架构跑通 | ✅ |
| **1. Xcode 工程 + ASR 闭环** | 5–7 天 | 浮窗能录音、能歌词式转录 | ✅ |
| **2. TTS + MCP + Settings** | 5–7 天 | Claude Code 能调通 `speak()` | ✅ |
| **3. Intel 兼容 + 完善 + 测试** | 3–5 天 | 双架构都能用，错误反馈成型 | ✅ |
| **4. 上架资产 + 提审** | 3–5 天 | 提交 App Review | — |

---

## Phase 0 — 技术风险验证（已完成 2026-04-29）

> **不进 Xcode 项目**。用 SPM 命令行工具做最小验证，跑通后丢弃。
> 这个 phase 的目的是把不确定性消灭在投入工程之前。

### 任务

| # | 任务 | 状态 |
|---|---|---|
| 0.1 | ~~edge-tts 协议验证~~ | **已砍**（决议改走 OpenAI 兼容协议） |
| 0.2 | Swift MCP SDK 选型 | ✅ 用官方 swift-sdk v0.12.0（DECISIONS TD-001） |
| 0.3 | clone 官方 conformance server 本地跑通 | ✅ HTTP/SSE 全通（DECISIONS TD-005） |
| 0.4 | Universal Binary 验证 | ✅ SPM 路径双架构通（DECISIONS TD-006） |

### Phase 0 复盘

从计划的 1.5 天压到约 1 小时实操。最大收获是**事实校准**——验证了 swift-sdk 的 SSE 流、session 管理、跨架构编译都真的工作；实测 release binary 单架构约 12MB（之前文档里"SwiftNIO ~10MB"的猜测和实际接近，但是巧合不是认知）。Xcode 26.x SPM 路径上没复现 16.x 的 universal bug——**Phase 1 Xcode project 路径再验一次**。

---

## Phase 1 — Xcode 工程 + ASR 闭环（5–7 天，待开始）

**目标**：app 能开、能录音、浮窗显示歌词式转录。**不接 MCP，不接 TTS**。

### 任务

| # | 任务 |
|---|---|
| 1.1 | 创建 Xcode 项目（macOS 13+ deployment target、`ARCHS = $(ARCHS_STANDARD)`、Sandbox 开启）。**工程创建后立即 archive 一次验证双架构产物**（防 Xcode 16.x universal bug） |
| 1.2 | Bundle ID `com.ethanys.voxai`、entitlements: `app-sandbox` + `device.audio-input` + `network.client` + `network.server` |
| 1.3 | Info.plist：`NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription`（中英两版） |
| 1.4 | `AppSettings`（UserDefaults `@AppStorage` 包装） |
| 1.5 | `TranscriptionService`——**重写**（参考旧版 `sessionGeneration` / 60s 续接的设计，但去掉所有会议模式痕迹、`findProjectRoot`、spawn Process） |
| 1.6 | `DialogView`——**重写**（参考旧版歌词渲染 + 控制条 + 浮窗设置，去掉 `isDialogMode` 双路、`MeetingModeContent`、`openWindow("meeting")`）。**v1 必含**：录音停止后自动复制到剪贴板（DR-020），Settings 给关闭开关；保留手动复制按钮作 fallback |
| 1.7 | `VoxAIApp.swift`：3 Scenes（`dialog` WindowGroup / `settings` Window / `MenuBarExtra`），启动自动 open dialog |

### DoD

- ✅ Apple Silicon Mac 上 build & run 通过
- ✅ Intel Mac 上 build & run 通过（**Phase 1 末尾就要测一次**，不要拖到 Phase 3）
- ✅ 浮窗常驻置顶、能拖动、能关闭
- ✅ 录音 → 实时歌词 → 60s 后无缝续接 → 复制全文

### 跨架构要点

- AVAudioEngine 在 Intel 上 input format 默认 sampleRate 可能与 Apple Silicon 不同（48kHz vs 44.1kHz）。**`silenceLimit` 必须从实际 `inputNode.outputFormat(forBus: 0).sampleRate` 计算**——VoxSage 写死 `× 43.0` 跨架构会偏差
- 权限授予回调时序在 Intel 上较慢——`requestPermissions()` 后要 await，不能假设立即返回

### 验收：Intel Mac 实测脚本

1. 拿到 Rebecca 提供的 Intel Mac
2. Build & run（archive 一份 universal binary）
3. 第一次启动 → 麦克风权限 → SF Speech 权限 → 录音
4. 录音超过 60s（验证续接）
5. 复制 → 粘贴到文本编辑器看完整性

---

## Phase 2 — Settings UI + 错误反馈 + 双语（~2 天，待开始）

> **2026-05-04 切片更新**：原 Phase 2（TTS + MCP + Cloud + Keychain，5-7 天）整体砍掉。详见 DR-021 / DR-022。Phase 2 缩到 MVP 必需的 5 件事。

**目标**：v1.0 必备的 UI / UX 完善——让用户能看到错误、能改设置、UI 中英双语。

### 任务

| # | 任务 |
|---|---|
| 2.1 | ✅ `VoxAI/Views/SettingsView.swift`——v1.0 极简版（autoCopy toggle + 关于：版本号 + 隐私政策链接 + GitHub 链接 + v1.x 占位提示）|
| 2.2 | ✅ VoxAIApp.swift `SettingsPlaceholderView` → 真 `SettingsView`；MenuBarExtra 加 `SettingsLink`（macOS 14+）/ `showSettingsWindow:` selector fallback（macOS 13）|
| 2.3 | ✅ 错误反馈统一路径：`TranscriptionService.requestPermissions` 失败时 set `lastError`；DialogView 用 `errorBinding` 弹 alert（覆盖 4 种 TranscriptionError case）；DialogTitleBar + MenuBarExtra label + MenuBarContent 状态行都根据 `lastError != nil` 显示 warning |
| 2.4 | ✅ Localizable.xcstrings + InfoPlist.xcstrings 中英双语：developmentRegion 改 zh-Hans；39 条 UI 字符串提供 en + zh-Hans 翻译；隐私描述从 `INFOPLIST_KEY_*` 移到 `InfoPlist.xcstrings`；TranscriptionError 用 `NSLocalizedString`；中英混排菜单标签按 locale 拆分（"显示浮窗 / Show Dialog" 在英文系统显示 "Show Dialog"）|
| 2.5 | ✅ `VoxAI/VoxAI.entitlements` 已移除 `network.client` + `network.server`（pivot commit 里完成）|

### DoD

- ✅ Settings 能开关"自动复制到剪贴板"，立即生效
- ✅ 拒麦克风 / 拒语音识别 / SFSpeechRecognizer 不可用 → 菜单栏图标变 warning + 浮窗弹错误提示
- ✅ 切英文系统语言，UI 显示英文（DialogView 提示语 + Settings 标签 + 菜单栏 + 权限弹窗）
- ✅ entitlements 减到 `[app-sandbox, audio-input]` 两条
- ✅ Debug + Release universal binary 通过

---

## Phase 3 — 合规 + Intel 实测（~2 天，待开始）

**目标**：上架前所有合规检查就位，跨架构验证完成。

### 任务

| # | 任务 |
|---|---|
| 3.1 | ✅ `PrivacyInfo.xcprivacy` 已建——`NSPrivacyAccessedAPICategoryUserDefaults` reason `CA92.1`；`NSPrivacyTracking=false`；`NSPrivacyCollectedDataTypes=[]` |
| 3.2 | ✅ Apple Silicon 完整用户旅程通过（2026-05-05，8 项 checklist 全 pass）|
| 3.3 | ✅ **Intel Mac 实测通过**（2026-05-05，朋友"弘"在 Intel Mac 验证）—— Notarize 后的 .app 双击启动 OK；中文识别准确含标点；DR-020 自动复制 → 粘贴到微信主流程跑通；无崩溃。**Phase 1.5 跨架构 sampleRate 修正在 Intel 真机生效**——担心的 48kHz 偏差未暴露 |
| 3.4 | ✅ 无 Intel 问题需要修（Phase 3.3 即一次过）|
| 3.5 | ✅ `README.md` 中英双语用户文档已写 |

### DoD

- ✅ PrivacyInfo.xcprivacy 完整 + 通过 `xcrun privacy-info validate` 检查
- ✅ Apple Silicon 主流程零 bug 跑通
- ✅ Intel Mac 主流程跑通（朋友确认）
- ✅ README.md 给用户一页文档（用嘴编程定位 / 安装方式 / 第一次使用步骤 / 常见问题）

---

## Phase 4 — 上架资产 + 提审（~2-3 天，待开始）

| # | 任务 | 备注 |
|---|---|---|
| 4.1 | ✅ App Icon 已集成（Codex 生成，全套 16-1024 + 1024 单独 source，commit ff0b55a）|  |
| 4.2 | ✅ App Store 截图 3 张已就绪（3024×1964，commit ba764b7）—— `docs/screenshots/asc-{1-floating,2-recording,3-finished}.png`，3 张连成"桌面悬浮 → 用嘴对 Claude 说话 → 自动复制完成"故事 | |
| 4.3 | ✅ 应用描述 + 关键词 + 类别——草稿在 `topics/operations/ASC_SUBMISSION_DRAFTS.md` §1-§7 | |
| 4.4 | ✅ 隐私政策网页——`docs/privacy.html` 中英双语 + dark mode；GitHub Pages LIVE 在 `https://ethan-ys.github.io/VoxAI/privacy.html`（HTTP 200 验证通过）| |
| 4.5 | ⏳ **进行中**：等 Rebecca 在 ASC 创建 app record（中国账号 `hrebeccaqy@icloud.com` 无痕窗口）→ Sage 跑 archive (`method=app-store`) + upload → 填字段（草稿全在 ASC_SUBMISSION_DRAFTS.md）→ Submit | Notarize toolchain 已经在 Phase 3 朋友测试时端到端预演过，换 method 即可 |
| 4.6 | ✅ App Review Notes 极简版——在 `ASC_SUBMISSION_DRAFTS.md` §8 | DR-022 砍 MCP 后审核风险大幅降低 |

### DoD

- ✅ 提交 App Review，等结果
- ✅ 同步在 VoxSage README 加一段「商店版 VoxAI 已上架」

---

## 总工期重估（2026-05-04 切片后）

| Phase | 原估 | 切片后 | 实际 | 变化原因 |
|---|---|---|---|---|
| Phase 1 | 5-7 天 | — | **1 天**（2026-05-03） | Sage 接管所有 Xcode 配置 + Rebecca 仅做 GUI 创建 |
| Phase 2 | 5-7 天 | ~2 天 | **2 天**（2026-05-03 ~ 05-05） | 切片砍 TTS / MCP / Cloud / Keychain；末段 NSPanel 大重构（DR-025）拖了 0.5 天但解决了根因 |
| Phase 3 | 3-5 天 | ~2 天 | **0.5 天**（2026-05-05） | Notarize toolchain 顺手在朋友测试时跑通；Intel Mac 一次过 |
| Phase 4 | 3-5 天 | ~2-3 天 | 进行中 ~1 天（剩 ASC submission） | 大部分 Phase 4 任务和 Phase 3 / GitHub 重组并行做了 |
| **总计** | **~4 周** | **~6-7 天** | **~3.5 天到 RC** | 切片到 MVP + 工作流并行 |

---

## v1.x / v2 路线图

### v1.1 — ~~会议模式~~ → 移交 VoxSage（2026-06-25，DR-028）

> **这条线不在 VoxAI 做了。** 2026-06-25 Rebecca 提出"和别人谈事时 AI 实时旁听 + 多人 diarization + 判断靠不靠谱"场景，决定移交 VoxSage 旧仓——VoxSage 已有 whisperx+pyannote diarization 栈（`src/stt/diarize.py`）、无 App Sandbox 限制、本地分离隐私干净。详见 DECISIONS **DR-028**。
> VoxAI 的 v1.x 候选回到轻量项：语言切换 UI（DR-023）/ TTS（DR-021）/ 自动 paste（DR-024），等真实用户反馈再启动。

**原会议模式设计**（移交 VoxSage 时可参考）：
- WhisperKit 集成（Intel/Apple Silicon 双适配，模型分级）
- 会议管理 UI（沿用 VoxSage 的 ContentView 设计）
- 离线 ASR + 简单的说话人区分
- `list_meetings` / `get_meeting` MCP 工具回归

### v2.0 — TBD

- 真正的声纹分离（评估纯 Swift 方案）
- iCloud 同步会议数据
- 自定义热词 / 行业术语
- Apple Intelligence 集成（如果苹果开放 API）

---

## 外部依赖

| 项 | 状态 | 何时需要 |
|---|---|---|
| Apple Developer Program 账号 | ✅ Rebecca 已确认 | Phase 4 上架时 |
| Intel Mac 测试机 | ✅ Rebecca 提供 | Phase 1 末尾首次测试 / Phase 3 主战场 |
| App Icon 视觉素材 | ✅ 沿用 VoxSage 现有 | Phase 4.1 |

---

## 进度跟踪

> 每完成一个任务勾掉，每个 Phase 末尾写一段简短复盘。

### Phase 0 进度
- [x] 0.2 Swift MCP SDK 选型（2026-04-29，详见 DECISIONS TD-001/TD-002）
- [x] 0.3 clone 官方 conformance server 本地跑通（2026-04-29，详见 DECISIONS TD-005）
- [x] 0.4 Universal Binary 验证（2026-04-29，详见 DECISIONS TD-006）

### Phase 1 进度
- [x] **1.1 创建 Xcode 工程**（2026-05-03 完成）
  - Xcode 26.4.1 GUI 创建空 macOS App 项目（Rebecca 操作）
  - 移到 `Developer/VoxAI/`，搬入 git 仓库
  - 修正 build settings：deployment target 13.0、Bundle ID 全小写 `com.ethanys.voxai`、DEVELOPMENT_TEAM 切换到 paid Team `YNMBJ5H736`、加 entitlements 引用、加隐私描述、加 LSUIElement
  - 创建 `VoxAI/VoxAI.entitlements`：sandbox + audio-input + network.client + network.server
  - **Release universal binary 验证通过**：`x86_64 + arm64` 双 slice，risk R-006 消解
- [ ] 1.2 entitlements + Info.plist 隐私描述（已并入 1.1 完成）
- [ ] 1.3 ~~Info.plist 隐私描述~~（同上，已合入 1.1）
- [x] **1.4 `AppSettings`**（2026-05-03 完成）
  - `VoxAI/Models/AppSettings.swift` — `ObservableObject` + `@Published`（macOS 13 不支持 @Observable）
  - 9 个 UserDefaults 字段：识别语言 / TTS 引擎 / System 中英语音 / Cloud Base URL / Cloud Model / Cloud Voice / 语速 / 自动复制剪贴板（DR-020 默认 true）
  - Cloud API Key 走 Keychain（DR-009），Phase 1.4 留 stub，Phase 2.4 接入 KeychainHelper
  - `resetToDefaults()` 方法支持"恢复出厂设置"
  - 所有 key 加 `voxai.` 前缀防冲突
  - Debug + Release universal binary 验证通过
- [x] **1.5 `TranscriptionService`**（2026-05-03 完成）
  - `VoxAI/Services/TranscriptionService.swift`（约 320 行）—— 从 VoxSage 移植 `sessionGeneration` 防过期回调机制
  - 砍掉：`isDialogMode` 双路 / 所有会议模式代码 / `meetingAudioFile` / `lastMeetingAudioPath` / spawn Python `startMCPServer` / `findProjectRoot` / NSWindow 持有
  - **跨架构修正**：`silenceLimit` 从 `inputNode.outputFormat(forBus:0).sampleRate / bufferSize` 实时计算（VoxSage 写死 43.0 在 48kHz Intel Mac 会偏差 ~10%）
  - Swift 6 strict concurrency 兼容：`@MainActor` 隔离 + audio tap closure 用 captured locals + `Task @MainActor` 切回主线程更新 `@Published`
  - 加 `TranscriptionError` enum + `lastError` @Published（不再 try? 静默吞错误）
  - 加 `requestPermissions()` 同时请求 Speech + Microphone（macOS 14+ 严格了麦克风权限）
  - 加 `onStopped` 钩子供 DialogView 触发自动复制（DR-020）
  - Debug + Release universal binary（arm64+x86_64）双双验证通过
- [x] **1.6 `DialogView`**（2026-05-03 完成）
  - `VoxAI/Views/DialogView.swift`（约 530 行）—— v1 产品脸面
  - 三态 UI：idle 空（mic 按钮）/ recording-paused（歌词 + 控制条）/ idle 但有 transcript（完成态：复制 + 清空 + 重录）
  - **DR-020 自动复制集成**：在 `onAppear` 接 `ts.onStopped`，依据 `AppSettings.autoCopyToClipboard` 决定是否在 stop 瞬间写 NSPasteboard + 标题栏闪 "已复制" 标签
  - 砍掉 VoxSage 的：MeetingModeContent / "Switch to Dialog Mode" / `ts.dialogWindow` / `ts.meetingWindow` / `openWindow("meeting")` / `ts.openSettingsOnShow` / `ts.isDialogMode`（v1 永远是 dialog 模式）
  - 关闭按钮：hide window + stop mic（避免麦克风后台静默运行）
  - 麦克风权限拒绝时弹 alert 引导用户去系统设置
  - macOS 13.0 兼容：用单参 `.onChange(of:_:)` 而不是 macOS 14+ 的双参版
  - Debug + Release universal binary（arm64+x86_64）双双验证通过；二进制 252K
- [x] **1.7 `VoxAIApp.swift`**（2026-05-03 完成）
  - 改写 `VoxAI/VoxAIApp.swift`：3 Scenes（dialog WindowGroup + Settings 占位 + MenuBarExtra）
  - 注入 `AppSettings.shared` + `TranscriptionService(settings:.shared)` 通过 `@StateObject` + `.environmentObject(...)`
  - MenuBarExtra：状态感知图标（idle/recording/paused 三态颜色）+ "显示浮窗 / Show Dialog"（⇧⌘D）+ "退出 / Quit"（⌘Q）+ 状态行（非交互的 status row）
  - Settings Scene 留 `SettingsPlaceholderView` —— Phase 2.7 替换为完整 SettingsView
  - 删除默认 `VoxAI/ContentView.swift`（不再被引用）
  - **单实例锁未加**（v1.7 决定）：macOS Launch Services 已防 `open` 双开，留 Phase 2.5 MCPServer 端口绑定时再评估
  - Debug + Release universal binary（arm64+x86_64）双双通过；二进制 1.1M
- [ ] **Phase 1 末尾 Apple Silicon 上 ⌘R 真机测试**——录音 / 续接 / 自动复制走一遍
- [ ] **Phase 1 末尾 Intel Mac 实测**

---

### 🎉 Phase 1 闭环（2026-05-03）

Phase 1 所有工程任务完成，**VoxAI 第一次成为可启动的 app**。下一步是真机测试——在 Apple Silicon 上 ⌘R 跑一下用嘴编程的核心流（录音 → 自动复制 → 切 Claude → 粘贴）。Intel Mac 实测留到 Phase 3.1。

Phase 1 累积工程经验（写到 STATUS 已发现 commit message 同步过）：
- Swift 6 strict concurrency 不再隐式导入 Combine（需要 `import Combine` 显式声明 ObservableObject/@Published/Timer.publish）
- @MainActor 静态属性（如 `AppSettings.shared`）不能作为 default argument expression（nonisolated context）
- `.onChange(of:_,_:)` 双参版是 macOS 14+，13.0 必须用单参版
- Xcode 默认 DEVELOPMENT_TEAM 跟系统 iCloud 走（美区免费 Team `JK89RW5Q4H`），新建 Apple 项目要手动切到付费 Team `YNMBJ5H736`

### Phase 2 进度
（待开始）

### Phase 3 进度
（待开始）

### Phase 4 进度
（待开始）

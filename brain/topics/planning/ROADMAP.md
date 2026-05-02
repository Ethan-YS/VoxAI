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
| 1.6 | `DialogView`——**重写**（参考旧版歌词渲染 + 控制条 + 浮窗设置，去掉 `isDialogMode` 双路、`MeetingModeContent`、`openWindow("meeting")`） |
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

## Phase 2 — TTS + MCP + Settings（5–7 天，待开始）

**目标**：Claude Code 能通过 HTTP MCP 调 `speak()`、`stop_speaking()`、`list_voices()`、`update_voice_config()`。

### 任务

| # | 任务 |
|---|---|
| 2.1 | `TTSEngine` 协议（`speak / stop / listVoices`），day-1 抽象成可热插拔 |
| 2.2 | `SystemTTSEngine`（AVSpeechSynthesizer 包装；中英语音都列出来；按 `recognitionLanguage` 自动选默认） |
| 2.3 | `OpenAITTSClient`（HTTP POST `{baseURL}/audio/speech` → 音频流 → `AVAudioPlayer` 播放） |
| 2.4 | API Key 用 Keychain 存储（不落 UserDefaults） |
| 2.5 | `MCPServer`（HTTP/SSE，绑 `127.0.0.1:0`，4 个 tool） |
| 2.6 | mcp-config.json 持久化到 `Application Support/VoxAI/`，文件权限 600 |
| 2.7 | `SettingsView`——**全新设计**：识别语言 / TTS 引擎 / System 中英语音 / Cloud 配置（base URL/key/voice/model/test） / 语速 / MCP 配置展示（一键复制 Claude Code JSON） |
| 2.8 | 错误反馈：菜单栏图标状态机（正常 / 警告 badge），点击展开错误描述 |

### DoD

- ✅ Claude Code 添加 mcp-config 后，`speak("hello")` 能听到声音（System 模式默认）
- ✅ Settings 配置 OpenAI key + voice 后，Cloud 模式能调通；Test Connection 按钮工作
- ✅ Settings 切引擎/语音/语速立即生效，无需重启
- ✅ Apple Silicon + Intel 都能 `speak()` 中英文
- ✅ MCP server 启动后能在 Sandbox 内绑定端口、写 mcp-config

### 跨架构要点

- AVSpeechSynthesizer 跨架构无差异 ✓
- OpenAITTSClient 是纯网络，无差异 ✓
- SwiftNIO 双架构必测：archive 出 universal binary，在 Intel Mac 上跑 MCP server 一次完整 speak 调用

---

## Phase 3 — Intel 兼容 + 完善 + 测试（3–5 天，待开始）

**目标**：双架构都打磨好，错误反馈端到端成型。

### 任务

| # | 任务 |
|---|---|
| 3.1 | 在 Intel Mac 上跑完整用户旅程（开 app → 授权 → 录音 → Claude Code 连 MCP → speak），记录所有发现的问题 |
| 3.2 | 错误反馈完善：麦克风拒绝 / 网络挂 / 端口占用 / SFSpeechRecognizer 不可用 / API Key 错 / Cloud TTS 服务挂 → 全部走「图标 badge + 浮窗角标」模式 |
| 3.3 | 中英双语 UI 完成（`Localizable.xcstrings`） |
| 3.4 | 单元测试：TTSEngine 路由 / OpenAITTSClient HTTP 协议 / MCP JSON-RPC 消息解析 |
| 3.5 | `PrivacyInfo.xcprivacy` 完整声明（要列：麦克风、Speech Recognition、Network、Keychain） |

### DoD

- ✅ 不再有 `try?` 静默失败
- ✅ 拔网线 / 拒麦克风 / 故意填错 API Key → 用户都能看懂发生了什么
- ✅ 中英 UI 完整、无穿帮
- ✅ 单元测试通过率 100%

---

## Phase 4 — 上架资产 + 提审（3–5 天，待开始）

| # | 任务 | 备注 |
|---|---|---|
| 4.1 | App Icon（1024×1024 + 各 size） | 沿用 VoxSage 的 sparkles + 蓝紫渐变 |
| 4.2 | App Store 截图（13" + 16" 各一组，至少 3 张：Dialog 待机 / 录音中 / Settings） | 在 Apple Silicon 拍 |
| 4.3 | 应用描述（中英）、关键词、类别（Developer Tools 主 / Productivity 副） | |
| 4.4 | 隐私政策网页（GitHub Pages，仓库下 `docs/privacy.html`） | 必写：麦克风用途、ASR 不上传、用户配的 Cloud TTS 由用户自负责 |
| 4.5 | App Store Connect 创建 record，archive → upload → 提审 | |
| 4.6 | README.md 用户文档 | 替换 Phase 0 时存在的临时占位 |
| 4.7 | App Review Notes：解释 MCP HTTP server 用途（开发工具行业惯例） | 防止以 Guideline 2.5.x 拒 |

### DoD

- ✅ 提交 App Review，等结果
- ✅ 同步在 VoxSage README 加一段「商店版 VoxAI 已上架」

---

## v1.x / v2 路线图

### v1.1 — 会议模式（v1.0 上架后启动，~2 周）

- WhisperKit 集成（Intel/Apple Silicon 双适配，模型分级）
- 会议管理 UI（沿用 VoxSage 的 ContentView 设计）
- 离线 ASR + 简单的说话人区分（v1.1 不做声纹分离，只做"说话人 1/2"基于停顿启发）
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
（待开始 — 待 Rebecca 拍板"GitHub 公开 vs 闭源"和"v1 付费 vs 免费"两个产品决策后启动）

### Phase 2 进度
（待开始）

### Phase 3 进度
（待开始）

### Phase 4 进度
（待开始）

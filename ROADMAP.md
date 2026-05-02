# VoxAI 开发路线图

> 配套 [PLAN.md](./PLAN.md) 使用。
> **PLAN** 是产品规格（功能、架构、决策记录）。
> **ROADMAP** 是工程节奏（Phase 拆分、DoD、依赖、风险）。

**总工期估算**：约 4 周（基于 Cloud TTS 改 OpenAI 兼容协议后的修订）

---

## 概览

| Phase | 时长 | 核心目标 | 阻塞下一阶段？ |
|---|---|---|---|
| **0. 技术风险验证** | 1.5 天 | MCP HTTP server + 双架构跑通 | ✅ |
| **1. Xcode 工程 + ASR 闭环** | 5–7 天 | 浮窗能录音、能歌词式转录 | ✅ |
| **2. TTS + MCP + Settings** | 5–7 天 | Claude Code 能调通 `speak()` | ✅ |
| **3. Intel 兼容 + 完善 + 测试** | 3–5 天 | 双架构都能用，错误反馈成型 | ✅ |
| **4. 上架资产 + 提审** | 3–5 天 | 提交 App Review | — |

---

## Phase 0 — 技术风险验证（1.5 天）

> **不进 Xcode 项目**。用 SPM 命令行工具做最小验证，跑通后丢弃。
> 这个 phase 的目的是把不确定性消灭在投入工程之前。

### 任务

| # | 任务 | 产出 |
|---|---|---|
| 0.1 | ~~edge-tts 协议验证~~ | **已砍**（决议改走 OpenAI 兼容协议，无需验证） |
| 0.2 | ✅ Swift MCP SDK 选型 | 已决：用官方 `modelcontextprotocol/swift-sdk` v0.12.0（详见 TD-001/TD-002） |
| 0.3 | clone 官方 conformance server 本地跑通 | 验证 SwiftNIO + swift-sdk 在本机能起 HTTP MCP server，curl 访问通 |
| 0.4 | Universal Binary 验证 ⚠️ | 在 SPM 工程加 swift-sdk + NIO 依赖，`swift build -c release --arch arm64 --arch x86_64`，`lipo -info` 看到双 slice。**已知风险**：Xcode 16.1 / 16.2 有 universal binary bug（编译只产 arm64，Apple FB17019201 已记录），实操遇到的话切到 archive build 路径或评估 Xcode 版本选型 |

### DoD

- ✅ MCP SDK 选型决定，写到 ROADMAP 末尾「技术决策日志」
- ✅ SwiftNIO HTTP server 在 Sandbox 模拟环境跑通（注：SPM 工具默认无 sandbox，但能验证 API 用法；真 sandbox 验证留到 Phase 2）
- ✅ Universal binary 双架构产物都能跑

### 跨架构要点

- SwiftNIO 5.x 官方支持 arm64 + x86_64，但要在 Phase 1 装 Xcode 后再次确认 `Package.resolved` 没有锁到单架构

### 风险与应对

- **SwiftNIO 在 Sandbox 下绑 localhost 端口失败** → Phase 0.3 POC 不保证能 100% 模拟，留到 Phase 2 接 Xcode 后才能彻底验。如有问题 fallback 到 `Network.framework` 的 `NWListener`
- **Xcode 16.1 / 16.2 universal binary bug** → 实操时如果 `lipo -info` 只看到单 slice，先尝试 archive build 路径；若仍不行考虑 Xcode 版本（升级到更新版本或降到 15.x）

---

## Phase 1 — Xcode 工程 + ASR 闭环（5–7 天）

**目标**：app 能开、能录音、浮窗显示歌词式转录。**不接 MCP，不接 TTS**。

### 任务

| # | 任务 |
|---|---|
| 1.1 | 创建 Xcode 项目（macOS 13+ deployment target、`ARCHS = $(ARCHS_STANDARD)`、Sandbox 开启）。注：Xcode 16.x universal binary bug 在 Phase 0.4 已识别，工程创建后立即 archive 一次验证双架构产物 |
| 1.2 | Bundle ID `com.ethanys.voxai`、entitlements: `app-sandbox` + `device.audio-input` + `network.client` + `network.server` |
| 1.3 | Info.plist：`NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription`（中英两版） |
| 1.4 | `AppSettings`（UserDefaults `@AppStorage` 包装） |
| 1.5 | `TranscriptionService`——**重写**（参考旧版 sessionGeneration / 60s 续接的设计，但去掉所有会议模式痕迹、`findProjectRoot`、spawn Process） |
| 1.6 | `DialogView`——**重写**（参考旧版歌词渲染 + 控制条 + 浮窗设置，去掉 `isDialogMode` 双路、`MeetingModeContent`、`openWindow("meeting")`） |
| 1.7 | `VoxAIApp.swift`：3 Scenes（`dialog` WindowGroup / `settings` Window / `MenuBarExtra`），启动自动 open dialog |

### DoD

- ✅ Apple Silicon Mac 上 build & run 通过
- ✅ Intel Mac 上 build & run 通过（**Phase 1 末尾就要测一次**，不要拖到 Phase 3）
- ✅ 浮窗常驻置顶、能拖动、能关闭
- ✅ 录音 → 实时歌词 → 60s 后无缝续接 → 复制全文

### 跨架构要点

- AVAudioEngine 在 Intel 上 input format 默认 sampleRate 可能与 Apple Silicon 不同（48kHz vs 44.1kHz）。**`silenceLimit` 必须从实际 `inputNode.outputFormat(forBus: 0).sampleRate` 计算**，旧版写死的 `× 43.0` 在跨架构会偏差
- 权限授予回调时序在 Intel 上较慢——`requestPermissions()` 后要 await，不能假设立即返回

### 验收：Intel Mac 实测脚本

1. 拿到 Rebecca 提供的 Intel Mac
2. Build & run（archive 一份 universal binary）
3. 第一次启动 → 麦克风权限 → SF Speech 权限 → 录音
4. 录音超过 60s（验证续接）
5. 复制 → 粘贴到文本编辑器看完整性

---

## Phase 2 — TTS + MCP + Settings（5–7 天）

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

## Phase 3 — Intel 兼容 + 完善 + 测试（3–5 天）

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

## Phase 4 — 上架资产 + 提审（3–5 天）

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

## 外部依赖

| 项 | 状态 | 何时需要 |
|---|---|---|
| Apple Developer Program 账号 | ✅ Rebecca 已确认 | Phase 4 上架时 |
| Intel Mac 测试机 | ✅ Rebecca 提供 | Phase 1 末尾首次测试 / Phase 3 主战场 |
| App Icon 视觉素材 | ✅ 沿用 VoxSage 现有 | Phase 4.1 |

---

## 技术决策日志

> 此处记录 Phase 0 调研后做的具体技术选型，避免后续遗忘。

### TD-001：Swift MCP SDK = 官方 `modelcontextprotocol/swift-sdk` v0.12.0

**调研日期**：2026-04-29（Phase 0.2）

**关键事实**：
- 官方 SDK 已发布到 0.12.0（2026-03-24 release，活跃维护，107+ commits）
- 最低 macOS 13.0，与 VoxAI 部署目标完全匹配
- 内置 `StatefulHTTPServerTransport`：自带 session 管理、SSE streaming、event store（resumability with Last-Event-ID）、HTTP request validation pipeline
- MCP library target 本身**不依赖 SwiftNIO**——只依赖 swift-system / swift-log / mattt/eventsource
- 官方 conformance server 示例用 SwiftNIO 套 HTTP listener，可直接参考

**为什么不自写 JSON-RPC**：JSON-RPC + SSE + 协议版本协商 + session 管理 + event store resumability，自写至少 2000 行 + 大量边界 case。官方 SDK 全包了，且持续跟进 spec 演进。

### TD-002：HTTP listener 方案 = SwiftNIO（接 swift-sdk）

**为什么不用 Network.framework `NWListener`**：
- 优点：Apple 原生、零依赖、Sandbox 兼容性最佳
- 缺点：要自己写 HTTP/1.1 协议解析、SSE 帧编码——重复造轮子

**为什么用 SwiftNIO**：
- 官方 conformance server 现成代码可参考，**`MCPConformance/Server/` 直接迁移**
- `NIOHTTP1` 处理协议解析，省事
- `NIOCore/NIOPosix/NIOHTTP1` Apple 官方维护
- Sandbox 下绑 localhost 端口 + 已声明 `network.server` entitlement → 经查证 Apple 文档，端口 > 1024 时允许（我们用 `:0` OS 自动分配，正好规避 well-known port 限制）

**未验证项**：SwiftNIO 真实体积代价（之前文档曾写"~10MB"是估测，已删除）；跨架构稳定性需要 Phase 0.4 实操验证。

### TD-003：MCP token 存储

mcp-config.json 写 Sandbox `Application Support/VoxAI/`，文件权限 600。

### TD-004：API Key 存储

macOS Keychain（DR-009）。

### TD-005：Phase 0.3 conformance server 实测结果

**实测日期**：2026-04-29
**环境**：macOS 26.4 / Xcode 26.4.1 / Swift 6.3.1 / Apple Silicon arm64

**操作**：
1. `git clone --depth=1 https://github.com/modelcontextprotocol/swift-sdk.git`
2. `swift build --product mcp-everything-server`（27.76s）
3. `mcp-everything-server --port 18080`，绑定 `127.0.0.1:18080`
4. `curl -X POST http://127.0.0.1:18080/mcp` + MCP `initialize` 请求

**实测结果**：
- ✅ HTTP 200 + Content-Type: text/event-stream（SSE 正确）
- ✅ Session ID 自动分配（`MCP-Session-Id: E419E138-...`）
- ✅ SSE 帧格式正确（`id: 1_1` / `event: message` / `data: {...}`）
- ✅ MCP `initialize` 握手返回完整 server capabilities

**结论**：SwiftNIO + swift-sdk 路径完全可用，Phase 2 直接迁移 `MCPConformance/Server/HTTPApp.swift` 模式即可。

### TD-006：Phase 0.4 Universal Binary 实测结果

**实测命令**：
```bash
swift build -c release --triple arm64-apple-macosx13.0 --product mcp-everything-server
swift build -c release --triple x86_64-apple-macosx13.0 --product mcp-everything-server
lipo -create <arm64-slice> <x86_64-slice> -output universal
```

**实测产物**：
- arm64 release binary: **11.78 MB**
- x86_64 release binary: **12.03 MB**
- Universal binary: 23.82 MB（含 swift-sdk + SwiftNIO 完整栈 + conformance 业务代码）
- `lipo -info`: `Architectures in the fat file: x86_64 arm64`
- `file`: `Mach-O universal binary with 2 architectures`

**结论**：
- Xcode 26.x 上 SwiftPM 路径的 cross-compile 正常工作，**之前担心的 16.1/16.2 universal bug 在 SPM 路径未复现**
- 实际 binary 体积约 12MB（包含完整 SwiftNIO + MCP SDK），对 App Store 上架场景完全可接受
- VoxAI 用 Xcode project 而非 SPM，**Phase 1.1 创建 Xcode 工程后需要再次验证一次 archive 路径**——SPM 通了不等于 Xcode 项目通

---

## 进度跟踪

> 每完成一个任务勾掉，每个 Phase 末尾写一段简短复盘。

### Phase 0 进度
- [x] 0.2 Swift MCP SDK 选型（2026-04-29，详见 TD-001/TD-002）
- [x] 0.3 clone 官方 conformance server 本地跑通（2026-04-29，详见 TD-005）
- [x] 0.4 Universal Binary 验证（2026-04-29，详见 TD-006）

**Phase 0 复盘**：从计划的 1.5 天压到 ~1 小时实操。最大收获是**事实校准**——验证了 swift-sdk 的 SSE 流、session 管理、跨架构编译都真的工作；实测 release binary 单架构约 12MB（之前文档里"SwiftNIO ~10MB"的猜测和实际接近，但是巧合不是认知）。Xcode 26.x SPM 路径上没复现 16.x 的 universal bug（Phase 1 Xcode project 路径再验一次）。

### Phase 1 进度
（待开始）

### Phase 2 进度
（待开始）

### Phase 3 进度
（待开始）

### Phase 4 进度
（待开始）

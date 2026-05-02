# ARCHITECTURE — VoxAI 整体架构

> **这份文件回答**：VoxAI 内部各模块如何组织，数据怎么流，外部接口长什么样。
>
> **谁该读**：要动 MCP server / TTS / ASR / Settings 任何模块前。
> **不该读**：找具体决策原因 → 看 `DECISIONS.md`；找 Sandbox entitlement 配置 → 看 `SANDBOX.md`。

---

## 一、整体架构图

```
┌─────────────────────────────────────────────────┐
│                Claude Code                       │
│           (or other MCP client)                  │
└──────────────────────┬──────────────────────────┘
                       │ HTTP + SSE
                       │ Bearer Token
                       ▼
┌─────────────────────────────────────────────────┐
│          VoxAI.app (sandboxed)                   │
│ ┌─────────────────────────────────────────────┐ │
│ │  MCPServer (Swift, swift-nio)               │ │
│ │  127.0.0.1:RANDOMPORT                       │ │
│ └──────────┬──────────────────────────────────┘ │
│            │                                     │
│            ▼                                     │
│ ┌──────────────────────┐  ┌────────────────────┐│
│ │  TTSEngine           │  │ TranscriptionSvc   ││
│ │  ├ SystemTTS         │  │ SFSpeechRecognizer ││
│ │  └ OpenAITTSClient   │  │ AVAudioEngine      ││
│ └──────────────────────┘  └────────────────────┘│
│            │                                     │
│            ▼                                     │
│ ┌──────────────────────┐                        │
│ │  AppSettings         │ (UserDefaults + Keychain)
│ └──────────────────────┘                        │
└─────────────────────────────────────────────────┘
                       ▲
                       │
                  ┌────┴─────┐
                  │ DialogView│ ← 用户语音输入
                  └──────────┘
```

## 二、模块职责

### MCPServer
- **绑定**：`127.0.0.1:0`（随机端口），启动时把端口 + token 写入 `~/Library/Containers/com.ethanys.voxai/Data/Library/Application Support/VoxAI/mcp-config.json`
- **协议**：HTTP/SSE（Streamable HTTP transport），不是 stdio
- **认证**：每次启动随机生成 Bearer Token，要求所有请求带 `Authorization: Bearer XXX`
- **工具清单（v1.0）**：
  - `speak(text, voice?, speed?)` — 朗读文字，可临时覆盖语音/语速
  - `stop_speaking()` — 立即打断
  - `list_voices()` — 列出当前引擎可用语音
  - `update_voice_config(...)` — 运行时改引擎/语音/语速/语言
- **依赖**：官方 `modelcontextprotocol/swift-sdk` v0.12.0 + SwiftNIO（详见 DECISIONS TD-001/TD-002）

### TTSEngine（抽象层 + 双引擎路由）
- **协议**：`speak(text) / stop() / listVoices()`，day-1 抽象成可热插拔
- **System 引擎（默认）**：`AVSpeechSynthesizer` 包装。Apple 自带、零依赖、离线、跨架构。中英语音都列出来，按 `recognitionLanguage` 自动选默认
- **Cloud 引擎**：`OpenAITTSClient`，HTTP POST `{baseURL}/audio/speech` → 音频流 → `AVAudioPlayer` 播放
  - v1 主打 OpenAI 自家 API（`https://api.openai.com/v1`）
  - Base URL 字段保留可改（用户可接 OpenAI 兼容代理服务），但**这是高级用法，不是 v1 卖点**
  - 主流 TTS（ElevenLabs / Cartesia / Deepgram / Google Cloud）有各自的 API，**v1 不直接适配**

### TranscriptionService（ASR）
- **核心**：`SFSpeechRecognizer` + `AVAudioEngine`
- **关键设计**：从 VoxSage 移植 `sessionGeneration` 防过期回调机制
  - 60s 超时自动续接
  - `clearTranscript()` 时递增代数让旧回调失效
  - 静音阈值检测自动分段（Dialog 模式可关）
- **跨架构注意**：AVAudioEngine 在 Intel 上 input format 默认 sampleRate 可能与 Apple Silicon 不同（48kHz vs 44.1kHz）。**`silenceLimit` 必须从实际 `inputNode.outputFormat(forBus: 0).sampleRate` 计算**——VoxSage 写死 `× 43.0` 跨架构会偏差
- **移植时砍掉**：`findProjectRoot()`（不再需要 Python 后端）+ 所有会议模式代码（`startMeetingListening`、`meetingAudioFile` 等）

### AppSettings
- **存储分工**：
  - **UserDefaults**（`@AppStorage`）：识别语言、TTS 引擎选择、语音 ID、语速、Cloud Base URL、Cloud Model
  - **Keychain**：Cloud TTS API Key（绝对不落 UserDefaults）
  - **`Application Support/VoxAI/mcp-config.json`**：MCP 端口 + token，文件权限 600

### DialogView（用户语音输入面板）
- 悬浮窗，常驻置顶，能在任何 app 上面工作
- 歌词式渲染：已完成段落淡出、活跃段落高亮
- 自动标点（macOS 13+ 原生 `addsPunctuation`）
- 复制到剪贴板按钮

### MenuBarView / SettingsView
- **菜单栏**：常驻 SF Symbol 图标，状态机（正常 / 警告 badge）
- **Settings**：独立窗口，⌘, 快捷键，4 段：识别语言 / TTS 引擎 / Cloud 配置 / MCP 信息展示

## 三、数据流

### 用户说话 → AI 收到文字
```
用户口头 → AVAudioEngine (硬件)
       → SFSpeechRecognizer (系统 ASR)
       → TranscriptionService (sessionGeneration 控制)
       → DialogView (歌词渲染 + 复制按钮)
       → 用户手动复制 → 粘贴到 Claude Code
```

注：v1 不把 ASR 结果**主动**推到 MCP server——用户手动复制粘贴，因为：
- MCP server 是 Claude Code 主动调用，不是 VoxAI 主动 push
- 自动 push 需要新 MCP 工具 `get_pending_transcript()` 或类似设计，v1 暂不做

### AI 输出 → 用户听到
```
Claude Code → HTTP POST /mcp { tools/call: speak }
           → MCPServer (验 token, 解析参数)
           → TTSEngine.speak(text)
           → System 路径：AVSpeechSynthesizer
           → Cloud 路径：OpenAITTSClient HTTP → 音频流 → AVAudioPlayer
           → 用户听到声音
```

## 四、关键技术决策摘要

完整决策见 `brain/DECISIONS.md`。摘要列表：

| 决策 | 选择 | 主要理由 |
|---|---|---|
| MCP transport | HTTP/SSE | stdio 在 Sandbox 里无法被外部 Claude Code 调用 |
| 后端语言 | 纯 Swift | Sandbox 禁止 spawn Python，打包 Python 进 bundle 复杂度极高 |
| MCP SDK | 官方 swift-sdk v0.12.0 | 内置 SSE / session / event store，自写 ≥ 2000 行 |
| HTTP listener | SwiftNIO | 接 swift-sdk，官方 conformance server 可参考 |
| Cloud TTS | 用户自带 OpenAI key | edge-tts 踩 App Store Guideline 2.5.1 + 5.2.2 |
| ASR | SFSpeechRecognizer | 系统原生，跨架构稳定，自动标点 |
| 最低系统 | macOS 13.0 (Ventura) | 覆盖 Intel + Apple Silicon，支持 ASR 自动标点 |
| 架构 | Universal Binary | App Store 要求 + 双架构用户基数 |

## 五、模块依赖关系

```
DialogView ──→ TranscriptionService ──→ AppSettings
                                       └─→ Keychain (无)

SettingsView ──→ AppSettings
            └─→ TTSEngine.testConnection (Cloud)

MCPServer ──→ TTSEngine ──→ SystemTTSEngine
          │                └─→ OpenAITTSClient ──→ AppSettings (Cloud config)
          └─→ AppSettings (运行时配置变更)

VoxAIApp ──→ 启动时初始化 MCPServer + AppSettings
         └─→ 3 个 Scene：dialog / settings / menubar
```

无循环依赖。MCPServer 不依赖 DialogView（v1 ASR 走手动复制）。

## 六、跨架构兼容（Universal Binary）

| 模块 | Intel 行为 | 备注 |
|---|---|---|
| AVAudioEngine | 不同 sampleRate（默认） | **必须从 inputNode 实际值计算 silenceLimit** |
| SFSpeechRecognizer | 无 Neural Engine 加速，稍慢 | v1 不引入 NN 推理，无性能悬崖 |
| AVSpeechSynthesizer | 跨架构无差异 | ✅ |
| OpenAITTSClient | 纯网络调用 | ✅ |
| SwiftNIO | 双架构支持（5.x） | Phase 0.4 已用 SPM 验证 12MB / arch |
| swift-sdk | macOS 13+ 双架构 | Phase 0.3 已验 SSE 流通 |

**Xcode universal binary 已知风险**：Xcode 16.1/16.2 有编译只产 arm64 的 bug（Apple FB17019201）。Phase 0.4 用 SPM 路径未复现，但 **Phase 1.1 创建 Xcode 项目后必须再次 archive 验证**。

## 七、目录结构（提议，Phase 1 创建 Xcode 工程时落地）

```
VoxAI/                          # repo root
├── CLAUDE.md                   # 项目入口（已建，引导新会话读 brain/）
├── PLAN.md / ROADMAP.md        # 短索引指向 brain/（已迁移）
├── brain/                      # 项目脑（本目录）
├── .references/                # 调研用代码（不进 build）
│   └── swift-sdk/              # 官方 MCP SDK 验证用 clone
│
├── VoxAI.xcodeproj/            # Xcode 工程（Phase 1.1 创建）
│
├── VoxAI/                      # App 源码
│   ├── VoxAIApp.swift          # 入口（3 scenes：dialog / menubar / settings）
│   ├── Info.plist
│   ├── VoxAI.entitlements
│   ├── Views/
│   │   ├── DialogView.swift
│   │   ├── MenuBarView.swift
│   │   └── SettingsView.swift
│   ├── Services/
│   │   ├── TranscriptionService.swift
│   │   ├── TTSEngine.swift
│   │   ├── SystemTTSEngine.swift
│   │   ├── OpenAITTSClient.swift
│   │   └── MCPServer.swift
│   ├── Models/
│   │   └── AppSettings.swift
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   └── PrivacyInfo.xcprivacy
│   └── Localizable.xcstrings
│
├── VoxAITests/                 # 单元测试
└── docs/
    ├── screenshots/            # App Store 截图素材
    ├── PRIVACY.md              # 隐私政策（要托管成网页）
    └── DEPLOYMENT.md           # 上架手册（v1 发版时写）
```

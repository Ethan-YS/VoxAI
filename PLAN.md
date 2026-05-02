# VoxAI v1.0 — App Store 上架方案

**版本**：v1.0 设计稿
**日期**：2026-04-29
**作者**：Sage × Rebecca

---

## 一、背景与定位

### 为什么开新仓

旧仓库 [VoxSage](../VoxSage/)（GitHub: `Ethan-YS/VoxAI`，已发布 v0.5.0）走的是 **Notarized DMG** 路线，依赖一套完整的 Python 后端（whisperx + mlx-audio + edge-tts + chatterbox），通过 spawn `venv/bin/python3.13` 子进程跑 MCP server。

这套架构和 **Mac App Store Sandbox** 有结构性冲突：
- Sandbox 不允许 spawn 用户路径下的 Python 进程
- whisperx / pyannote 模型从 HuggingFace 下载（需要 token）也是问题
- MCP server 通过 stdio 给 Claude Code 调用，本质是"外部工具调本地脚本"——这种模式 App Store 应用做不到

所以我们走 **双轨发布** 策略：

| 仓库 | 渠道 | 用户群 | 功能 |
|---|---|---|---|
| **VoxSage**（旧） | GitHub Releases / Notarized DMG | 开发者 | 全功能（含会议、声纹分离、本地 TTS） |
| **VoxAI**（新，本仓库） | Mac App Store | 普通用户 | 核心语音 I/O |

### 产品定位

**给 AI 加一层语音 I/O，主战场 Claude Code，外延到所有 MCP 兼容工具。**

- 不是录音 app
- 不是会议笔记 app（v1 至少不是）
- 是 **「让 AI 听得见、说得出」的桥梁**

---

## 二、v1.0 功能范围

### ✅ 包含（必做）

#### 实时语音输入（Dialog 模式）
- 悬浮窗，常驻置顶，能在任何 app 上面工作
- `SFSpeechRecognizer` + `AVAudioEngine`，60s 超时自动续接
- 歌词式渲染：已完成段落淡出、活跃段落高亮
- 自动标点（macOS 13+ 原生）
- 复制到剪贴板按钮

#### MCP HTTP Server（核心卖点）
应用内置 HTTP/SSE MCP server，绑定 `localhost:PORT`。Claude Code 通过 HTTP transport 连接。

工具清单（v1.0）：
| Tool | 说明 |
|---|---|
| `speak(text, voice?, speed?)` | 朗读文字，可临时覆盖语音/语速 |
| `stop_speaking()` | 立即打断 |
| `list_voices()` | 列出当前引擎可用语音 |
| `update_voice_config(...)` | 运行时改引擎/语音/语速/语言 |

#### TTS 引擎（双引擎，运行时切换）
- **System TTS**：`AVSpeechSynthesizer`（Apple 自带，零依赖、离线、跨架构，默认）
- **Cloud TTS**：用户自带 API key + **OpenAI 兼容协议**。VoxAI 不绑定任何服务方，只做 HTTP client；用户填什么 endpoint 就调什么（OpenAI / ElevenLabs / Groq / 自建均可）

#### 设置面板
- 识别语言（自动 / 中文 / 英文）
- TTS 引擎切换（System / Cloud）
- System 模式：中英文分别选语音
- Cloud 模式：Base URL / API Key / Voice ID / Model / Test Connection
- 语速 0.5 ~ 2.0
- 显示 MCP 连接信息（端口、token、Claude Code 配置示例）

#### 系统集成
- 菜单栏常驻图标
- 启动时自动唤起 Dialog 窗口
- 支持中英双语 UI（跟随系统）

### ❌ 不包含（v1 明确砍掉）

| 功能 | 砍掉理由 |
|---|---|
| **会议模式** | 依赖 whisperx 离线转录 + pyannote 声纹分离，迁移到 WhisperKit 工作量大（≥2 周），先 v1.0 上架，v1.1 再补 |
| **声纹分离** | 同上 |
| **Qwen3-TTS（中文本地）** | mlx-audio 无 Swift 包装，且 Apple 系统中文音质够用 |
| **Chatterbox（英文本地）** | 同理，AVSpeechSynthesizer 已能覆盖 |
| **MCP 工具 `list_meetings` / `get_meeting`** | 依赖会议模式 |

---

## 三、技术架构

### 整体架构图

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
│ │  └ EdgeTTSClient     │  │ AVAudioEngine      ││
│ └──────────────────────┘  └────────────────────┘│
│            │                                     │
│            ▼                                     │
│ ┌──────────────────────┐                        │
│ │  AppSettings         │ (UserDefaults)         │
│ └──────────────────────┘                        │
└─────────────────────────────────────────────────┘
                       ▲
                       │
                  ┌────┴────┐
                  │ DialogView│ ← 用户语音输入
                  └─────────┘
```

### 关键技术决策

#### 1. MCP Transport：HTTP/SSE（不是 stdio）

**Why**：App Sandbox 不允许 Claude Code 直接 spawn 沙盒应用内的可执行文件，stdio 路死。HTTP localhost + 一次性 token 是最干净的方案。

**实现**：
- 启动时绑定 `127.0.0.1:0`（随机端口），把端口号 + token 写入 `~/Library/Containers/{bundle-id}/Data/Library/Application Support/VoxAI/mcp-config.json`
- 设置面板里显示一段可复制的 Claude Code 配置：
  ```json
  {
    "mcpServers": {
      "voxai": {
        "type": "http",
        "url": "http://127.0.0.1:PORT/mcp",
        "headers": { "Authorization": "Bearer TOKEN" }
      }
    }
  }
  ```
- Token 是启动时随机生成（每次启动可能变化 / 可选持久化），防止其他进程乱调

**评估的 Swift MCP SDK**（待新窗口确认最新生态）：
- `loopwork/swift-mcp-sdk`
- 自写最小实现（MCP 协议 JSON-RPC + SSE 不复杂，几百行）

#### 2. Cloud TTS：OpenAI API（用户自带 OpenAI key）

**Why**：edge-tts 逆向 Microsoft 未公开的 Edge Read-Aloud API，会同时踩 App Store 两条硬条款：
- **Guideline 2.5.1**：「Apps may only use **public APIs**」—— edge-tts 调的不是 public API
- **Guideline 5.2.2 Third-Party Sites/Services**：「ensure that you are specifically permitted to do so under the service's terms of use. Authorization must be provided upon request」—— 我们拿不出 Microsoft 的授权

改走「用户自带 OpenAI API key」：用户的 key、用户接受 OpenAI 的服务条款，VoxAI 只是 HTTP client，零法务风险。

**协议**：OpenAI TTS API（`POST {base_url}/audio/speech`）。

**实现范围（v1）**：
- v1 主打 **OpenAI 自家 API**（`https://api.openai.com/v1`）
- Base URL 字段保留可改——用户想接 OpenAI 兼容的代理服务（如 openai-edge-tts 自建、TokenMix 等）也能用，但**这是高级用法，不是 v1 卖点**
- 主流 TTS（ElevenLabs / Cartesia / Deepgram / Google Cloud）有各自的 API，**v1 不直接适配**，留到 v1.x 按用户反馈再加

**Settings 配置项**：
- Base URL（默认 `https://api.openai.com/v1`）
- API Key（SecureField，存 Keychain）
- Voice（下拉 + 文本框；预填 OpenAI 6 个标准 voice：`alloy / echo / fable / onyx / nova / shimmer`，文本框允许覆盖）
- Model（默认 `tts-1`，可选 `tts-1-hd` / `gpt-4o-mini-tts`）
- Test Connection 按钮

**好处**：
- 法务零风险（VoxAI 不绑定任何第三方服务方）
- 协议简单（HTTP POST + 音频流），实现快
- 比 edge-tts 的 WebSocket 方案省 3-4 天开发

#### 3. ASR：沿用 SFSpeechRecognizer

VoxSage 那套设计很扎实，**整套 `sessionGeneration` 防过期回调的逻辑直接搬过来**，包括：
- 60s 超时自动续接
- `clearTranscript()` 时递增代数让旧回调失效
- 静音阈值检测自动分段（Dialog 模式可关）

**唯一改动**：移除 `findProjectRoot()` 那段（因为不需要 Python 后端）和会议相关代码（`startMeetingListening`, `meetingAudioFile` 等）。

#### 4. 架构兼容：Universal Binary

Xcode build setting：`ARCHS = $(ARCHS_STANDARD)`（自动包含 arm64 + x86_64）。

**Intel Mac 上的性能注意点**：
- AVSpeechSynthesizer：原生支持，性能 OK
- edge-tts：纯网络调用，性能 OK
- SFSpeechRecognizer：Apple Silicon 上有 Neural Engine 加速，Intel 上稍慢但可用
- v1.0 没有 NN 模型推理，跨架构没有性能悬崖

> v1.1 加会议模式时如果引入 WhisperKit，要专门评估 Intel Mac 性能（tiny/base 模型可用，large 不建议）。

#### 5. 应用最低系统：macOS 13.0（Ventura）

**Why**：
- macOS 13+ 原生支持 ASR 自动标点（`addsPunctuation`）
- macOS 13+ 同时支持 Intel 和 Apple Silicon
- macOS 13+ 已经覆盖大部分 Mac 装机量
- 旧 VoxSage 是 14+，新 VoxAI 放宽到 13+ 增加用户基数

---

## 四、项目结构（提议）

```
VoxAI/
├── CLAUDE.md                       # 项目级入口（已建）
├── PLAN.md                         # 本文档
├── README.md                       # 用户文档（v1 上架前写）
├── .gitignore
│
├── VoxAI.xcodeproj/                # Xcode 项目
│
├── VoxAI/                          # App 源码
│   ├── VoxAIApp.swift              # 入口（3 scenes：dialog / menubar / settings）
│   ├── Info.plist
│   ├── VoxAI.entitlements
│   │
│   ├── Views/
│   │   ├── DialogView.swift        # 悬浮窗 + 歌词渲染
│   │   ├── MenuBarView.swift       # 菜单栏下拉
│   │   └── SettingsView.swift      # 设置面板
│   │
│   ├── Services/
│   │   ├── TranscriptionService.swift   # ASR（从 VoxSage 精简移植）
│   │   ├── TTSEngine.swift              # TTS 抽象 + 路由
│   │   ├── SystemTTSEngine.swift        # AVSpeechSynthesizer 包装
│   │   ├── EdgeTTSClient.swift          # 自写 WebSocket 客户端
│   │   └── MCPServer.swift              # HTTP/SSE MCP server
│   │
│   ├── Models/
│   │   └── AppSettings.swift            # UserDefaults 包装
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   └── PrivacyInfo.xcprivacy
│   │
│   └── Localizable.xcstrings
│
├── VoxAITests/                     # 单元测试
│
└── docs/
    ├── screenshots/                # App Store 截图素材
    ├── PRIVACY.md                  # 隐私政策（要托管成网页）
    └── DEPLOYMENT.md               # 上架手册（v1 发版时写）
```

---

## 五、沙盒 Entitlements

`VoxAI.entitlements`：

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.device.audio-input</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.network.server</key>
<true/>
```

**说明**：
- `audio-input`：麦克风（ASR 必需）
- `network.client`：调 edge-tts WebSocket
- `network.server`：监听 localhost MCP HTTP 端口
- **不需要** `files.user-selected.read-write`（v1 不读写用户文件）
- **不需要** `temporary-exception` 系列（避免审核额外问题）

`Info.plist` 隐私描述：
```xml
<key>NSMicrophoneUsageDescription</key>
<string>VoxAI 需要麦克风权限以进行实时语音转文字。</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>VoxAI 需要语音识别权限将你的语音转为文字。</string>
```

---

## 六、开发路线图

### v1.0 — 首次上架（目标 ~3 周）

**Week 1：骨架 + ASR**
- [ ] 创建 Xcode 项目（universal、macOS 13+、sandbox 开启）
- [ ] 移植 `TranscriptionService`（精简版）
- [ ] 实现 DialogView（悬浮窗 + 歌词渲染）
- [ ] AppSettings 模型 + SettingsView 骨架

**Week 2：TTS + MCP Server**
- [ ] SystemTTSEngine（AVSpeechSynthesizer，中英语音都列）
- [ ] OpenAITTSClient（HTTP POST `/audio/speech`，音频流播放）
- [ ] TTSEngine 抽象层（System / Cloud 运行时切换）
- [ ] MCPServer（HTTP/SSE，4 个 tool）
- [ ] mcp-config.json 写入 + Settings 面板显示
- [ ] Cloud TTS 配置项（Base URL / API Key / Voice / Model / Test Connection），API Key 存 Keychain

**Week 3：打磨 + 上架准备**
- [ ] 中英双语 UI 完成
- [ ] 错误反馈（不再 try? 静默失败）
- [ ] 单元测试（TTSEngine 路由、edge-tts 协议、MCP 协议）
- [ ] App Store 截图、描述、隐私政策网页
- [ ] 提交审核

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

## 七、上架清单

### 账号 / 法务
- [x] Apple Developer Program 账号（Rebecca 已确认有）
- [ ] App Store Connect 创建 app record
- [ ] Bundle ID: `com.{?}.voxai` —— 待 Rebecca 决定团队名 / 公司名
- [ ] 隐私政策网页（建议托管在 GitHub Pages 或个人站）
- [ ] 软件许可协议（可选，用 Apple 默认 EULA 也行）

### 技术
- [ ] Universal Binary 验证（在 Intel Mac 实测）
- [ ] Sandbox 实测（运行时无任何 entitlement 缺失）
- [ ] 公证流程跑通（archive → upload → distribution）
- [ ] PrivacyInfo.xcprivacy 完整声明

### 资产
- [ ] App icon（1024×1024 + 各种 size）
- [ ] App Store 截图（13" 和 16" 各一组，至少 3 张）
- [ ] 应用描述（中英双语）
- [ ] 关键词
- [ ] 类别：Developer Tools（主）/ Productivity（副）

### 营销
- [ ] 着陆页（可选）
- [ ] 演示视频 / GIF
- [ ] 旧 VoxSage 的 README 加一段"商店版 VoxAI 已上架"

---

## 八、决议事项（2026-04-29 与 Rebecca 确认）

| # | 决议 |
|---|---|
| 1 | **Bundle ID** = `com.ethanys.voxai` |
| 2 | **隐私政策托管** = GitHub Pages，仓库 `docs/privacy.html` |
| 3 | **定价模式** = 免费（v1 最大化用户基数，未来再考虑 Freemium） |
| 4 | **Cloud TTS** = **不用 edge-tts**（踩 Guideline 2.5.1 + 5.2.2），v1 改走"用户自带 OpenAI API key"。Base URL 字段可改保留代理用法弹性，但 v1 主打 OpenAI 自家。详见 §3.2 |
| 5 | **GitHub 仓库** = 开源（继承 VoxSage MIT） |
| 6 | **App Store Connect 主语言** = 英文为主，中文 Localized |
| 7 | **设置面板入口** = 独立 Settings Window，菜单栏图标里的 "Settings…" 菜单项 + ⌘, 快捷键 |
| 8 | **MCP token / 端口策略** = 端口启动时随机绑定，token 持久化到 Sandbox `Application Support/VoxAI/mcp-config.json`，文件权限 600 |
| 9 | **错误反馈方式** = 菜单栏图标 SF Symbol 状态变化（`waveform.circle.fill` → `waveform.circle.badge.exclamationmark`）+ 浮窗角落红点。不弹对话框打断流程 |
| 10 | **启动行为** = 沿用旧版，启动时自动开 Dialog 浮窗 |
| 11 | **App Icon** = 沿用 VoxSage 的 sparkles + 蓝紫渐变视觉 |
| 12 | **Intel Mac 测试机** = 由 Rebecca 提供 |

---

## 九、决策记录（DR）

| # | 决策 | 选择 | 理由 |
|---|---|---|---|
| DR-001 | 双轨发布还是合并 | 双轨 | App Store 沙盒和当前架构有结构性冲突 |
| DR-002 | MCP transport | HTTP/SSE | stdio 在沙盒里无法被外部 Claude Code 调用 |
| DR-003 | 后端语言 | 纯 Swift | 沙盒禁止 spawn Python，且打包 Python 进 bundle 复杂度极高 |
| DR-004 | v1 是否含会议模式 | 不含 | 优先把核心 MCP 语音 I/O 做扎实上线，会议模式 v1.1 补 |
| DR-005 | 最低系统 | macOS 13.0 | 覆盖 Intel + Apple Silicon，且支持 ASR 自动标点 |
| DR-006 | 中文本地 TTS | 砍 | mlx-audio 无 Swift 包装，AVSpeechSynthesizer 中文够用 |
| DR-007 | 名字 | VoxAI（不带后缀） | 跟产品名一致，区分旧 VoxSage |
| DR-008 | Cloud TTS 实现路径 | 用户自带 OpenAI API key（v1 主打 OpenAI 自家；Base URL 可改保留代理弹性） | edge-tts 同时踩 App Store Guideline 2.5.1（public APIs only）+ 5.2.2（third-party 授权要求）；改走「用户的 key、用户接受 OpenAI 服务条款」可零法务风险。注：之前文档曾错误描述"OpenAI 兼容协议是事实标准"——实际主流 TTS（ElevenLabs / Cartesia / Deepgram / Google Cloud）都有自家协议非 OpenAI 兼容，v1 直接 cover 的就是 OpenAI 一家 |
| DR-009 | API Key 存储位置 | macOS Keychain | Sandbox 内 Application Support 仅存 mcp-config（端口/token），用户的第三方 API Key 必须 Keychain |

---

## 十、风险登记

| 风险 | 影响 | 缓解 |
|---|---|---|
| 用户填的第三方 TTS API 服务挂掉 / 改协议 | Cloud TTS 失败 | OpenAITTSClient 给清晰错误提示；System TTS 始终可用作 fallback |
| 苹果审核拒绝 MCP HTTP server | 上架失败 | 苹果不禁止 localhost server（开发工具普遍如此），但要在 App Review Notes 解释清楚用途 |
| Intel Mac 用户体验差 | 差评 | v1 没有重型 NN 推理，风险低；v1.1 引入 WhisperKit 时分级处理 |
| MCP 协议演进，Claude Code 改接口 | 工具失效 | 关注 modelcontextprotocol.io 更新，做好版本协商 |
| Sandbox 下 SwiftNIO 绑定 localhost 端口失败 | MCP server 起不来 | Phase 0.3 POC 先验证；如有问题考虑 `Network.framework` 替代方案 |

---

**End of v1.0 Plan**

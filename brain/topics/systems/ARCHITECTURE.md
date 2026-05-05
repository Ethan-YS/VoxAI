# ARCHITECTURE — VoxAI 整体架构

> **这份文件回答**：VoxAI 内部各模块如何组织，数据怎么流，外部接口长什么样。
>
> **谁该读**：要动 ASR / DialogView / Settings 任何模块前。
> **不该读**：找具体决策原因 → 看 `DECISIONS.md`；找 Sandbox entitlement 配置 → 看 `SANDBOX.md`。
>
> **v1.0 范围说明**：
> - 2026-05-04 切片（DR-021 / DR-022）：MCP server / TTS / Cloud 整套已砍
> - 2026-05-05 大改（DR-025）：浮窗从 SwiftUI `Window` scene 迁移到 NSPanel + AppDelegate（解决 macOS 26 + LSUIElement 下 `.floating` 不可靠）
> - v1.1+ 重启 SwiftUI Window scene 路径或重启 MCP / TTS 时，参考第八节"v1.1+ 预留设计"

---

## 一、整体架构图（v1.0，DR-025 NSPanel 路径）

```
┌──────────────────────────────────────────────────────┐
│            VoxAI.app (sandboxed)                      │
│                                                       │
│  VoxAIApp (@main)                                     │
│   ├─ @NSApplicationDelegateAdaptor → AppDelegate     │
│   │                                    │              │
│   │                                    ▼              │
│   │                          ┌──────────────────┐    │
│   │                          │ VoxAIPanel       │    │
│   │                          │ (NSPanel)        │    │
│   │                          │  isFloatingPanel │    │
│   │                          │     = true       │    │
│   │                          │  hasShadow=true  │    │
│   │                          └────────┬─────────┘    │
│   │                                   │ NSHostingView│
│   │                                   ▼              │
│   │                          ┌──────────────────┐    │
│   │                          │ DialogView       │    │
│   │                          │ (SwiftUI)        │    │
│   │                          │ 歌词 + 三态 UI   │    │
│   │                          └─┬─────┬─────┬────┘    │
│   │                            │     │     │          │
│   │              ┌─────────────┘     │     └────┐    │
│   │              ▼                   ▼          ▼    │
│   │      TranscriptionService   AppSettings  NSPaste-│
│   │      (.shared)              (.shared)    board   │
│   │       │ SFSpeechRecognizer                       │
│   │       │ AVAudioEngine                            │
│   │       │ sessionGeneration                        │
│   │                                                   │
│   ├─ Settings scene                                   │
│   │    └─ SettingsView                                │
│   │         └─ AppSettings.shared                     │
│   │                                                   │
│   └─ MenuBarExtra scene                               │
│        └─ MenuBarContent                              │
│             ├─→ AppDelegate.showDialog()              │
│             └─→ TranscriptionService.shared (state)   │
│                                                       │
└───────────────────────────────────────────────────────┘
                  │
                  │ 用户停止录音 → 自动写剪贴板 → 切到 Claude → ⌘V
                  ▼
            外部 AI 工具的输入框
```

**为什么不再是 SwiftUI Window scene 持有浮窗**：见 DECISIONS DR-025。一句话：SwiftUI 的 `Window` scene 在 macOS 26 + LSUIElement = YES 下，`.floating` window level 会被 SwiftUI 内部窗口管理在某些 state transitions 时重置回 `.normal`。NSPanel 的 `isFloatingPanel = true` 是 OS 级承诺，没有这个 race。

**关键**：v1.0 **没有外部 IPC**——所有数据流都在 VoxAI.app 内部 + 通过 macOS 系统剪贴板传给其他 app。这是审核最简单的形态。

## 二、模块职责（v1.0）

### AppDelegate（v1.0 的浮窗主管）— 2026-05-05 DR-025 引入

`VoxAI/AppDelegate.swift`，~130 行。三个 type：

- **`AppDelegate: NSApplicationDelegate`**：在 `applicationDidFinishLaunching` 时构建 NSPanel + show 出来；监听 `applicationShouldHandleReopen` 让用户从菜单栏 / Dock 重启 app 时自动 show 浮窗。同时**sweep 启动时被 SwiftUI 误开的 Settings 窗口**（LSUIElement = YES + 没有主 Window scene 时 SwiftUI 启发式行为）
- **`VoxAIPanel: NSPanel`**：自定义子类，重写 `canBecomeKey = true` 让 borderless panel 接受键盘输入，`canBecomeMain = false` 让标准菜单仍指 NSApp 而非这个浮窗
- **`DialogPanelController: ObservableObject`**：作为 EnvironmentObject 注入 DialogView，DialogView 关闭按钮调 `.close()` 而不是直接持有 NSWindow

NSPanel 关键配置：
```swift
panel.isFloatingPanel = true          // OS 级 floating 承诺
panel.becomesKeyOnlyIfNeeded = true   // 点浮窗不抢焦点
panel.hidesOnDeactivate = false        // 切其他 app 不隐藏
panel.level = .floating
panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
panel.styleMask = [.borderless, .fullSizeContentView, .nonactivatingPanel]
panel.isOpaque = false; panel.backgroundColor = .clear
panel.hasShadow = true   // 让 macOS 跟随 SwiftUI RoundedRectangle alpha 画圆角阴影
panel.isMovableByWindowBackground = true  // 拖动 by background
```

DialogView 通过 `NSHostingView`（不是 NSHostingController！）嵌入 panel.contentView，加 `.width / .height` autoresizing 让 SwiftUI 内容充满整个 panel。

### TranscriptionService（核心 ASR 引擎）
- **核心**：`SFSpeechRecognizer` + `AVAudioEngine`
- **关键设计**：从 VoxSage 移植 `sessionGeneration` 防过期回调机制
  - 60s 超时自动续接
  - `clearTranscript()` 时递增代数让旧回调失效
  - 静音阈值检测自动分段
- **跨架构修正**：`silenceLimit` 必须从 `inputNode.outputFormat(forBus:0).sampleRate / bufferSize` 计算（VoxSage 写死 43.0 在 48kHz Intel Mac 偏差 ~10%）
- **依赖输入**：`AppSettings.recognitionLanguage`（v1.0 默认 zh-CN，无 UI 切换，DR-023）
- **暴露**：`@Published state / completedSegments / activeSegment / lastError` + `onStopped` 钩子（DialogView 用来触发自动复制 DR-020）
- **Swift 6 concurrency**：`@MainActor` 隔离；audio tap closure 用 captured locals + `Task @MainActor` 切回主线程更新 `@Published`

### DialogView（v1 产品脸面）
- 悬浮窗，常驻置顶（`.floating` level + `.canJoinAllSpaces` + `.stationary` + `.fullScreenAuxiliary`），跨 app + 全屏可见
- 歌词式渲染：已完成段落渐淡（0.4-0.75，单段特例 0.75）、活跃段落高亮
- 自动标点（macOS 13+ 原生 `addsPunctuation`）
- **录音停止后自动复制到剪贴板**（DR-020 主推卖点）—— "用嘴编程"流畅性的核心实现
- 三态 UI：idle 空（mic 按钮）/ recording-paused（歌词 + 控制条）/ idle 但 transcript 非空（完成态：复制 + 清空 + 重录）
- 关闭按钮 = hide window + stop mic（避免麦克风后台静默运行）
- 手动复制按钮（保留作 fallback）
- 麦克风权限拒绝时弹 alert 引导用户去系统设置

### AppSettings（v1.0 极简版）
- **存储分工**：
  - **UserDefaults**（`@Published`）：v1.0 用户实际能改的只有 `autoCopyToClipboard`（其余字段保留但 SettingsView 不暴露——为 v1.1 留底）
  - **Keychain**：v1.0 不用（DR-021 砍 Cloud TTS 后 API Key 字段无意义）
  - ~~mcp-config.json~~：v1.0 不用（DR-022 砍 MCP server）
- **保留但 v1.0 不暴露的字段**（避免 v1.1 加 TTS/MCP 时重新引入字段）：
  - `recognitionLanguage`（DR-023 默认 zh-CN）
  - `ttsEngine` / `systemVoiceChinese` / `systemVoiceEnglish` / `cloudBaseURL` / `cloudModel` / `cloudVoice` / `speechRate`

### SettingsView（v1.0 极简版）
- 只暴露：**自动复制到剪贴板** toggle（默认 ON，DR-020）
- 关于信息：版本号 + 隐私政策网页链接 + GitHub 链接
- 不含：语言切换 / TTS 配置 / Cloud 配置 / MCP 配置（已砍）

### MenuBarExtra（菜单栏图标）
- **状态感知图标**：idle（waveform.circle 灰色）/ recording（waveform.circle.fill 红色）/ paused（waveform.circle.fill 橙色）/ error（warning badge，Phase 2 加）
- 菜单内容：状态行 + "显示浮窗 / Show Dialog"（⇧⌘D）+ Settings（Phase 2 接通）+ "退出 / Quit"（⌘Q）

## 三、数据流（v1.0 唯一路径）

### 用户说话 → AI 收到文字
```
用户口头 → AVAudioEngine (硬件)
       → SFSpeechRecognizer (系统 ASR，可能经 Apple 服务器，DR-018)
       → TranscriptionService (sessionGeneration 控制)
       → DialogView (歌词渲染)
       → 录音停止 → NSPasteboard.general (自动复制，DR-020)
       → 用户切到 Claude → ⌘V → 粘贴
```

**为什么自动复制是 v1 主路径**：少一次"点复制"鼠标动作，从 4 步压到 3 步——这是"用嘴编程"流畅性的核心兑现。

**为什么不直接 paste**：v1 不做"自动 ⌘V paste"（CGEvent 模拟键盘）—— 需要 Accessibility 权限，授权摩擦大 + Sandbox 受限 + App Store 审核风险。v1.x 看用户反馈再考虑（DR-024）。

**MCP 路径已砍**（DR-022）：v1.0 不暴露任何 HTTP/SSE 接口给 Claude Code。Claude Code 拿到用户语音输入靠剪贴板——这是 macOS 工具间最通用的 IPC，不需要任何 server。

## 四、关键技术决策摘要（v1.0 适用）

完整决策见 `brain/DECISIONS.md`。摘要：

| 决策 | 选择 | 主要理由 |
|---|---|---|
| 后端语言 | 纯 Swift | Sandbox 禁止 spawn Python；纯 Swift 是 App Store 路线的硬约束（DR-003） |
| ASR | SFSpeechRecognizer | 系统原生，跨架构稳定，自动标点（DR-018 默认服务器模式）|
| 最低系统 | macOS 13.0 (Ventura) | 覆盖 Intel + Apple Silicon，支持 ASR 自动标点（DR-005） |
| 架构 | Universal Binary | App Store 要求 + 双架构用户基数 |
| 自动复制剪贴板 | 默认开 | "用嘴编程"主推卖点（DR-020） |
| TTS | **v1.0 不做** | 主推 ASR 输入侧，TTS 留 v1.1（DR-021） |
| MCP server | **v1.0 不做** | TTS 砍了 MCP 没意义（DR-022） |
| 语言切换 UI | **v1.0 不暴露** | 主市场中文，默认 zh-CN（DR-023） |
| 自动 paste | **v1.0 不做** | Accessibility 权限摩擦 + 审核风险，留 v1.x（DR-024） |

## 五、模块依赖关系（v1.0）

```
DialogView ──→ TranscriptionService ──→ AppSettings
          └─→ NSPasteboard.general (录音停止时自动写入，DR-020)

SettingsView ──→ AppSettings

VoxAIApp ──→ 启动时初始化 AppSettings + TranscriptionService(settings:)
         └─→ 3 个 Scene：dialog / Settings / MenuBarExtra
```

**简化的连锁好处**（v1.0 切片相比 v1.x 设计）：
- 无循环依赖
- 无 TTS / MCP / Cloud / Keychain 模块——审核 entitlements 极简
- 无外部网络监听——`network.client` + `network.server` 都不需要

## 六、跨架构兼容（Universal Binary）

| 模块 | Intel 行为 | 备注 |
|---|---|---|
| AVAudioEngine | 不同 sampleRate（默认 48kHz） | **必须从 inputNode 实际值计算 silenceLimit** |
| SFSpeechRecognizer | 无 Neural Engine 加速，稍慢 | v1 不引入 NN 推理，无性能悬崖 |
| AppSettings (UserDefaults) | 跨架构无差异 | ✅ |
| DialogView (SwiftUI) | 跨架构无差异 | ✅ |

**Xcode universal binary 风险消解**：原 R-006（Xcode 16.x bug）已在 Phase 1.1 实测验证未复现，🟢 已消解。Phase 0.4 SPM 路径 + Phase 1.1 Xcode project 路径都通过 `lipo -info` 验证 [arm64 + x86_64] 双 slice。

## 七、目录结构（v1.0 落地）

```
VoxAI/                          # repo root
├── CLAUDE.md                   # 项目入口
├── PLAN.md / ROADMAP.md        # 短索引指向 brain/
├── LICENSE                     # MIT (DR-013/DR-017)
├── brain/                      # 项目脑
├── .references/                # Phase 0 调研用 swift-sdk clone（v1.0 实际不引入）
│
├── VoxAI.xcodeproj/            # Xcode 工程
│
├── VoxAI/                      # App 源码（fileSystemSynchronizedGroups 自动发现）
│   ├── VoxAIApp.swift          # 入口（3 Scenes：dialog / Settings / MenuBarExtra）
│   ├── VoxAI.entitlements      # v1.0 极简：[app-sandbox, audio-input]
│   ├── Assets.xcassets/        # 应用图标 + 强调色
│   │
│   ├── Models/
│   │   └── AppSettings.swift          # 配置 + Keychain stub
│   │
│   ├── Services/
│   │   └── TranscriptionService.swift # ASR 核心
│   │
│   └── Views/
│       ├── DialogView.swift           # 浮窗（v1 产品脸面）
│       └── SettingsView.swift         # 设置面板（Phase 2 实现）
│
└── docs/
    ├── privacy.html            # 隐私政策（Phase 4 创建，托管 GitHub Pages）
    └── PRIVACY.md              # 隐私政策源文档（可选）
```

**v1.0 没有的源文件**（DR-021 / DR-022 砍掉）：
- ~~`Services/TTSEngine.swift`~~
- ~~`Services/SystemTTSEngine.swift`~~
- ~~`Services/OpenAITTSClient.swift`~~
- ~~`Services/MCPServer.swift`~~
- ~~`Models/KeychainHelper.swift`~~

## 八、v1.1+ 预留设计（已砍但保留参考）

> 以下设计在 v1.0 切片时被砍，但保留架构参考——v1.1 视用户反馈决定是否重新引入。详见 DR-021 / DR-022。

### 砍掉的 MCP server 设计（v1.1+ 重启时参考）
- 绑定 `127.0.0.1:0`（随机端口）+ Bearer Token 认证
- HTTP/SSE transport（不是 stdio——Sandbox 不允许 spawn）
- 用官方 `modelcontextprotocol/swift-sdk` v0.12.0 + SwiftNIO
- 工具：`speak / stop_speaking / list_voices / update_voice_config`
- mcp-config.json 持久化到 `Application Support/VoxAI/`
- entitlements 需要回 `network.server`

### 砍掉的 TTS 设计（v1.1+ 重启时参考）
- TTSEngine 协议（`speak / stop / listVoices`）+ 双引擎运行时切换
- SystemTTSEngine：AVSpeechSynthesizer 包装
- OpenAITTSClient：HTTP POST `{baseURL}/audio/speech` → AVAudioPlayer
- API Key 走 macOS Keychain（DR-009）
- entitlements 需要回 `network.client`

### Phase 0 调研的实测产物（已完成不需要重做）
- `.references/swift-sdk/` clone 已验证 SwiftNIO + swift-sdk 跑得通（TD-005）
- universal binary 双架构通过（TD-006）
- 这些资产 v1.1 重启时直接复用，不需要重新调研

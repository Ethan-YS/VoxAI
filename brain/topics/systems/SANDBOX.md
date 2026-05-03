# SANDBOX — App Sandbox 配置与红线

> **这份文件回答**：VoxAI 在 macOS App Sandbox 下要开哪些 entitlement、配什么隐私描述、踩过什么坑。
>
> **谁该读**：动 entitlements / Info.plist / PrivacyInfo.xcprivacy 之前。改 MCP server 网络绑定方案之前。
> **不该读**：找上架审核流程 → 看 `operations/APP_STORE_CHECKLIST.md`；找架构层数据流 → 看 `ARCHITECTURE.md`。

---

## 一、Entitlements 清单（VoxAI.entitlements）

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

| Entitlement | 用途 | 必需性 |
|---|---|---|
| `app-sandbox` | App Store 强制 | 必需 |
| `device.audio-input` | 麦克风访问（ASR） | 必需 |
| `network.client` | Cloud TTS HTTP 调用 OpenAI API | 必需 |
| `network.server` | MCP server 监听 localhost | 必需 |

### 故意不要的 entitlement

| Entitlement | 为什么不要 |
|---|---|
| `files.user-selected.read-write` | v1 不读写用户文件 |
| `files.downloads.read-write` | v1 没下载行为 |
| `temporary-exception.*` 系列 | 任何 temporary-exception 都会触发审核额外问题，能不用就不用 |
| `network.client.location` | 不需要定位 |
| `automation.apple-events` | 不脚本化其他 app |

**纪律**：每加一条 entitlement 都要在 DECISIONS 里记一条，写明"为什么这个功能必须加这条"——审核时被问能直接报答案。

## 二、Info.plist 隐私描述

```xml
<key>NSMicrophoneUsageDescription</key>
<string>VoxAI 需要麦克风权限以进行实时语音转文字。</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>VoxAI 需要语音识别权限将你的语音转为文字。</string>
```

**双语**：通过 `Localizable.xcstrings` 提供英文版（Phase 3.3 完成）：
- "VoxAI needs microphone access for real-time speech-to-text."
- "VoxAI needs speech recognition to convert your voice to text."

**审核惯例**：使用描述要"具体到用途"，写"为了功能正常"会被拒。上面措辞已经是审核友好版本。

## 三、PrivacyInfo.xcprivacy（Phase 3.5 完成）

要声明的数据类型：
- **麦克风** → 捕获音频用于 ASR；VoxAI 本身不存储、不上传
- **Speech Recognition** → 通过 Apple `SFSpeechRecognizer` 处理。**v1 默认服务器模式（DR-018）**——根据 Apple 隐私策略，音频可能由 Apple 服务器处理。这是 Apple 平台标准行为，VoxAI 必须诚实声明
- **剪贴板（Clipboard）** → 录音停止后自动写入转录文字（DR-020），用户可在 Settings 关闭
- **Network**（Cloud TTS） → 用户自己配的 endpoint，发什么由用户决定
- **Keychain** → 存 Cloud TTS API Key

要声明的 API 用途（Required Reason API）：
- `UserDefaults`：用户偏好存储（reason `CA92.1`）
- `FileTimestamp`（如果用到）：文件管理（reason `C617.1`）

**纪律**：苹果 2024 起强制要求 `PrivacyInfo.xcprivacy`，缺失会导致上架被拒。Phase 3.5 单独跑一遍。

## 四、Sandbox 下的关键技术约束

### 4.1 不能 spawn 用户路径下的进程
**这是 VoxSage → VoxAI 重构的核心动因**。Sandbox 禁止：
- `Process` / `posix_spawn` 调用 `~/anaconda3/bin/python`、`venv/bin/python` 等
- 即使打包到 `.app/Contents/Resources/` 内的 binary，也要走 `XPC` 或 helper tool 路径，不能简单 spawn

**对 VoxAI 的影响**：所有功能必须**纯 Swift 实现**，不依赖任何外部脚本。

### 4.2 网络绑定
**问题**：Sandbox 应用监听网络端口需要 `network.server` entitlement，但有两个隐含限制：
- 端口 ≤ 1024 是 well-known port，需要 root，Sandbox 应用拿不到
- localhost 监听允许，外网监听需要更明确的用户授意

**VoxAI 的解决方案**：
- 绑 `127.0.0.1:0` → OS 自动分配端口（一定 > 1024）
- 端口和 token 写到 `Application Support/VoxAI/mcp-config.json`，用户自己复制配置到 Claude Code

### 4.3 文件系统隔离
Sandbox 应用的文件 I/O 默认只能在：
- `~/Library/Containers/com.ethanys.voxai/Data/` 下（应用专属容器）
- 用户通过 `NSOpenPanel` 显式授权的路径

**对 VoxAI 的影响**：
- mcp-config.json 写 Container 内 `Application Support/VoxAI/`（默认就在容器内）
- v1 不需要读写用户文件，`files.user-selected` 都不开

### 4.4 子进程模型
即使要做 helper（v2+ 可能要 WhisperKit），也只能：
- 打包到 `.app/Contents/MacOS/` 或 `.app/Contents/XPCServices/`
- 通过 `NSXPCConnection` 通信
- 不能调任何用户路径下的 binary

## 五、Sandbox 调试与验证

### Phase 1 早期验证清单

每次 build 后，运行一次：
```bash
codesign -d --entitlements - VoxAI.app
```

确认 entitlements 都进了签名（如果只在源码 entitlements 文件里有但没签进 app，runtime 等于没开）。

### Phase 2.5 网络绑定验证

```bash
# 在 sandboxed app 里跑 MCP server 后
lsof -i -P | grep VoxAI
# 应该看到 127.0.0.1:RANDOMPORT (LISTEN)
```

### 常见踩坑

| 症状 | 真因 |
|---|---|
| `bind() failed: Operation not permitted` | 没开 `network.server` |
| Cloud TTS 网络调用失败 | 没开 `network.client` |
| 麦克风权限弹窗只出现一次然后再也不出 | 用户拒了；要在 Settings 里给清晰指引去系统隐私设置开 |
| build 通过但启动 crash | Info.plist 缺 `NSMicrophoneUsageDescription`（macOS 14+ 强制）|

## 六、审核 Notes（Phase 4 提交时填）

App Review 提审时在 "Notes" 字段说明：

> VoxAI is a macOS speech I/O bridge for AI tools (Claude Code etc.). It runs a local HTTP/SSE MCP server bound to 127.0.0.1 random port. This is a developer-tool industry convention (similar to Claude Desktop, Cursor, Zed extensions, etc.) — the server only accepts localhost connections and uses Bearer token authentication. No network listener on external interfaces.

**为什么要写**：MCP HTTP server 是新模式，审核员可能不熟悉。提前解释避免被以 Guideline 2.5.x 拒。

## 七、签名 Team（每次新 Apple 项目都要警觉）

**Rebecca 有两个 Apple ID，签名 Team 跟着分裂**：

| Apple ID | Team ID | 角色 | 用在哪 |
|---|---|---|---|
| `g266835@icloud.com`（美区，系统 iCloud 登录） | `JK89RW5Q4H` | 免费 Personal Team | 仅本机调试 |
| `hrebeccaqy@icloud.com`（中国，付费 Apple Developer Program） | `YNMBJ5H736` | 付费 Team | **VoxAI 上架必须用这个** |

**Xcode 默认行为**：新建 Apple 项目时 Xcode 跟系统 iCloud 登录走，自动把 `DEVELOPMENT_TEAM` 填成美区免费 Team `JK89RW5Q4H`。**如果不手动改，archive 出来的产物没法上架**——付费证书在另一个账号下。

**VoxAI 当前配置**（Phase 1.1 已纠正，project.pbxproj 第 163/227 等行）：
```
DEVELOPMENT_TEAM = YNMBJ5H736;          // 中国付费账号
PRODUCT_BUNDLE_IDENTIFIER = com.ethanys.voxai;  // 在 YNMBJ5H736 下注册
```

**全局规则**（跨所有 Apple 项目通用）：详见 `L2-个人档案/账号密码记录.md` 的"Apple ID 双账号架构"章节。

**钥匙串验证命令**（怀疑签名错乱时跑一下）：
```bash
security find-identity -v -p codesigning
# 应能看到：
#   Apple Development: g266835@icloud.com (...)  ← 美区 Personal
#   Developer ID Application: SANG YI (YNMBJ5H736)  ← 中国付费，VoxAI 用这个
```

## 八、关联

- **Entitlements 决策原因** → `brain/DECISIONS.md` DR-002 / TD-002
- **Cloud TTS 用 OpenAI 协议而非 edge-tts 的法务原因** → `brain/DECISIONS.md` DR-008
- **完整上架清单** → `brain/topics/operations/APP_STORE_CHECKLIST.md`
- **Sandbox 风险登记** → `brain/topics/operations/RISKS.md`
- **Apple ID 双账号全局架构** → `L2-个人档案/账号密码记录.md`

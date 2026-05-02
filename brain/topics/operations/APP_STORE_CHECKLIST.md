# APP_STORE_CHECKLIST — Mac App Store 上架清单

> **这份文件回答**：上架要准备什么资产、走哪些流程、容易踩的审核坑。
>
> **谁该读**：Phase 4 提审前；任何时候想确认"上架还差什么"。
> **不该读**：找架构 → `systems/`；找路线图 → `planning/ROADMAP.md`；找版权审计 → `LICENSE_AUDIT.md`。

---

## 一、账号 / 法务

- [x] Apple Developer Program 账号（Rebecca 已确认有）
- [ ] App Store Connect 创建 app record
- [x] Bundle ID = `com.ethanys.voxai`（DECISIONS DR-010）
- [ ] 隐私政策网页（GitHub Pages 仓库下 `docs/privacy.html`）
- [ ] 软件许可协议（用 Apple 默认 EULA）
- [ ] 第三方依赖许可证审计 → 详见 `LICENSE_AUDIT.md`

## 二、技术验收

- [ ] Universal Binary 验证（在 Intel Mac 实测）
- [ ] Sandbox 实测（运行时无任何 entitlement 缺失，详见 `systems/SANDBOX.md`）
- [ ] 公证流程跑通（archive → upload → distribution）
- [ ] PrivacyInfo.xcprivacy 完整声明（Phase 3.5）
- [ ] App Sandbox 启用且签名正确（`codesign -d --entitlements - VoxAI.app` 验证）
- [ ] MCP server 在 Sandbox 下能绑定 `127.0.0.1:0` 端口

## 三、资产清单

### 视觉资产
- [ ] App Icon 1024×1024（沿用 VoxSage sparkles + 蓝紫渐变）
- [ ] App Icon 各 size（macOS 自动从 1024 生成，但 Asset Catalog 要全填）
- [ ] App Store 截图 13" × 至少 3 张：Dialog 待机 / 录音中 / Settings
- [ ] App Store 截图 16" × 至少 3 张：同上
- [ ] (可选) 演示视频 / GIF

### 文案资产
- [ ] 应用描述（英文，主语言）—— **主轴：用嘴编程 / Voice input for AI coding**
- [ ] 应用描述（中文，Localized）—— **主轴：用嘴编程**
- [ ] 关键词（英文 + 中文）—— **主关键词建议**：
  - 英：`speech to text`, `voice input`, `dictation`, `voice for AI`, `talk to Claude`, `voice coding`, `hands-free coding`
  - 中：`语音转文字`, `语音输入`, `语音编程`, `用嘴编程`, `AI 助手`, `Claude Code`
- [ ] 类别：**Productivity（主）/ Developer Tools（副）**——v1 定位"用嘴编程"，Productivity 是更大的池子；Developer Tools 作副承接技术受众（DR-015）
- [ ] What's New（更新说明）
- [ ] App Review Notes（解释 MCP HTTP server 用途，详见下面"四、审核 Notes"）

## 四、App Review Notes（提审时填）

> VoxAI is a macOS voice input tool for AI coding workflows. The primary use case is speech-to-text dictation: developers speak prompts, the transcribed text is automatically copied to the clipboard, and the user pastes into Claude Code or other AI tools.
>
> A secondary feature: VoxAI runs a local HTTP/SSE MCP server bound to 127.0.0.1 on a random port. This optional capability allows AI tools to ask VoxAI to read text aloud (text-to-speech). This is a developer-tool industry convention (similar to Claude Desktop, language servers, code formatters) — the server only accepts localhost connections and uses Bearer token authentication. No network listener on external interfaces.
>
> The MCP (Model Context Protocol) is an open standard maintained by Anthropic at modelcontextprotocol.io. VoxAI exposes 4 TTS tools: speak / stop_speaking / list_voices / update_voice_config.
>
> Speech recognition uses Apple's SFSpeechRecognizer (system framework), which may process audio on Apple servers per Apple's privacy policy. VoxAI itself does not collect or upload any audio or text.
>
> Cloud TTS (optional, off by default) uses user-supplied OpenAI API keys (stored in Keychain). VoxAI does not bundle any TTS service or rely on undocumented APIs. All network calls are to user-configured endpoints.

**为什么要写**：MCP HTTP server 是新模式，审核员可能不熟悉；且 v1 主推 voice input，要让审核员一眼看清核心用例不是 server。提前解释避免被以 Guideline 2.5.x 拒。

## 五、隐私政策必写项

托管位置：GitHub Pages，仓库 `docs/privacy.html`

**核心准确表述**（之前的"不上传任何音频"是错误的，DR-018 拍板修正）：
- **VoxAI 本身**不收集、不存储、不上传任何用户的音频或文字
- **语音识别**由 Apple 系统级 `SFSpeechRecognizer` 处理。**根据 Apple 的隐私策略，这可能涉及将音频发送到 Apple 服务器进行处理**——这是 Apple 平台的标准行为，VoxAI 选择默认服务器模式以提供最佳识别质量
- **剪贴板**：录音停止后，VoxAI 会把转录文字写入系统剪贴板（默认行为，用户可在 Settings 关闭）。剪贴板内容由用户控制
- **Cloud TTS（可选，默认关闭）**：用户自配的第三方 endpoint。VoxAI 仅作 HTTP client，**用户的文字内容会发到用户配置的 endpoint**——这一条要明确警告
- **API Key 存储**：macOS Keychain，不上传任何服务器
- **MCP Server**：localhost 监听，不接受外网连接，Bearer Token 认证
- **不收集**：VoxAI 不收集用户身份、不收集使用统计、无 telemetry、不连任何 voxai.com 类似域名

## 六、营销（可选）

- [ ] 着陆页（可选）
- [ ] 演示视频 / GIF
- [ ] 旧 VoxSage 的 README 加一段"商店版 VoxAI 已上架"

## 七、提审前最终走查

> **强制走查清单**——提审前一天逐条对一遍，避免低级错误：

- [ ] App Sandbox 开启（`com.apple.security.app-sandbox = true`）
- [ ] 所有用到的隐私 API 都有 `NS*UsageDescription`
- [ ] PrivacyInfo.xcprivacy 完整且正确
- [ ] 没有任何 `temporary-exception` entitlement
- [ ] 没有 NSLog / print 输出敏感信息（API Key、Token）
- [ ] 应用图标在所有 size 都正常显示
- [ ] 中英 UI 完整无穿帮（字符串截断、布局错乱）
- [ ] 第一次启动流程顺：权限弹窗 → 授权后正常使用
- [ ] 无网络环境下 System TTS + ASR 都能工作
- [ ] 提交版本号 / build 号比上次提交的高
- [ ] 隐私政策网页已上线且 URL 正确
- [ ] App Review Notes 填了 MCP 解释
- [ ] License audit 完成（详见 `LICENSE_AUDIT.md`）

## 八、被拒了怎么办（参考流程）

最常见的拒理由及应对：

| 拒理由 | 真因 | 应对 |
|---|---|---|
| Guideline 2.5.1（public APIs） | edge-tts 类似的逆向 API | v1 已避开 ✅ |
| Guideline 5.1.1（隐私描述不清楚） | NSXxxUsageDescription 太模糊 | 改具体到用途 |
| Guideline 2.1（崩溃 / 不能用） | Sandbox 缺 entitlement | 看 console.app 找 sandbox violation |
| Guideline 4.0（设计） | UI 有明显问题 | 截图重拍 |
| Guideline 5.2.2（third-party 服务） | 用了 Microsoft / 别家未授权 API | v1 已避开（用户自带 OpenAI key）✅ |

**纪律**：被拒不要慌，App Review 不是终审——可以 Reply 解释或在 Resolution Center 答辩，大部分拒理由是审核员不理解，解释清楚就放行。

## 九、上架后

- [ ] 跟踪首批用户反馈（用 `topics/feedback/` 整理）
- [ ] 监控 Crash logs（Xcode Organizer）
- [ ] App Store Connect 关键指标：下载数、留存、评分
- [ ] 旧 VoxSage README 同步更新（指向商店版）

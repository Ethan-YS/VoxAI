# APP_STORE_CHECKLIST — Mac App Store 上架清单

> **这份文件回答**：上架要准备什么资产、走哪些流程、容易踩的审核坑。
>
> **谁该读**：Phase 4 提审前；任何时候想确认"上架还差什么"。
> **不该读**：找架构 → `systems/`；找路线图 → `planning/ROADMAP.md`；找版权审计 → `LICENSE_AUDIT.md`。

---

## 一、账号 / 法务

- [x] Apple Developer Program 账号（Rebecca 已确认有，Team ID `YNMBJ5H736`）
- [ ] App Store Connect 创建 app record（Phase 4 提审前）
- [x] Bundle ID = `com.ethanys.voxai`（DECISIONS DR-010）—— 2026-05-02 已在 Apple Developer Portal Identifiers 注册锁定
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
- [ ] **应用描述（中文，主语言 — 2026-05-04 调整）**—— v1.0 主推中文市场（DR-023）。主轴："用嘴编程——给 Claude Code / Cursor 等 AI 工具加一层中文语音输入"
- [ ] 应用描述（英文，Localized）—— 简短版本：A Chinese voice input tool for AI coding assistants
- [ ] 关键词 —— **聚焦中文市场**：
  - 中：`语音转文字`, `语音输入`, `语音编程`, `用嘴编程`, `AI 助手`, `Claude Code`, `Cursor`, `中文语音`
  - 英（次要）：`speech to text`, `Chinese voice input`, `dictation for AI`, `voice for Claude Code`
- [ ] 类别：**Productivity（主）/ Developer Tools（副）**——v1 定位"用嘴编程"，Productivity 是更大的池子；Developer Tools 作副承接技术受众
- [ ] What's New（更新说明）
- [ ] App Review Notes（**v1.0 极简版**——MCP 砍了不用解释 server，详见下面"四、审核 Notes"）

## 四、App Review Notes（提审时填，v1.0 极简版）

> **2026-05-04 更新**：v1.0 砍 MCP server / TTS（DR-021 / DR-022）后，Notes 极简到只解释麦克风。

```
VoxAI is a Chinese-language voice input tool for AI coding assistants
(Claude Code, Cursor, etc.). The user speaks, VoxAI transcribes via
Apple's SFSpeechRecognizer, and the result auto-copies to the system
clipboard. The user then pastes into the AI tool. That is the entire
feature scope of v1.0.

Microphone access is required for speech-to-text. Audio is processed
by Apple's system framework (SFSpeechRecognizer), which may transmit
to Apple servers per Apple's privacy policy. VoxAI itself does not
store, upload, or transmit any audio or text outside the system
clipboard.

No network listening, no third-party server connections, no telemetry.
Entitlements are limited to `app-sandbox` and `device.audio-input`.
```

**为什么这套 Notes 简单**：v1.0 的功能极聚焦——只有"录音 + 系统识别 + 写剪贴板"。审核员一眼看清楚，过审风险降到最低。这是切片到 ASR-only MVP 的副产品收益（DR-022 砍 MCP server 让 Notes 不再需要解释 HTTP/SSE 行业惯例）。

## 五、隐私政策必写项

托管位置：GitHub Pages，仓库 `docs/privacy.html`

**核心准确表述（v1.0 极简版，2026-05-04 更新）**：
- **VoxAI 本身**不收集、不存储、不上传任何用户的音频或文字
- **语音识别**由 Apple 系统级 `SFSpeechRecognizer` 处理。**根据 Apple 的隐私策略，这可能涉及将音频发送到 Apple 服务器进行处理**——这是 Apple 平台的标准行为，VoxAI 选择默认服务器模式以提供最佳识别质量
- **剪贴板**：录音停止后，VoxAI 会把转录文字写入系统剪贴板（默认行为，用户可在 Settings 关闭）。剪贴板内容由用户控制
- **不收集**：VoxAI 不收集用户身份、不收集使用统计、无 telemetry、不连任何 voxai.com 类似域名
- **不联网**：v1.0 不发起任何 HTTP / WebSocket / 其他网络请求；不监听任何端口

**v1.0 砍掉的（v1.1 重新引入时补回）**：
- ~~Cloud TTS：用户自配的第三方 endpoint~~（DR-021 砍 TTS）
- ~~API Key 存储 macOS Keychain~~（无 Cloud TTS 后无意义）
- ~~MCP Server localhost 监听~~（DR-022 砍 MCP）

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

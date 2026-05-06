# ASC_SUBMISSION_DRAFTS — App Store Connect 提交文案草稿

> **这份文件回答**：v1.0 提审到 App Store Connect 时，所有需要复制粘贴到 ASC 表单里的文案，都在这里。
>
> **谁该读**：Phase 4.5 真正提审时；任何时候要修改 App Store 描述时。
> **维护纪律**：这是 v1.0 草稿。每次 ASC 改了什么 → 同步回这里，让 git 是单一来源。
>
> 草稿日期：2026-05-05 · 起草人：Sage · 待 Rebecca 审定

---

## 0. 元信息

| 项 | 值 |
|---|---|
| Bundle ID | `com.ethanys.voxai` |
| Team ID | `YNMBJ5H736`（中国付费 Apple Developer Program）|
| 主语言 | **简体中文（中国大陆）** —— 主市场（DR-023）|
| 本地化语言 | English（次要）|
| 类别（主） | **Productivity** |
| 类别（副） | **Developer Tools** |
| 价格 | 免费（DR-016）|
| 适用地区 | 全球（中文市场为主，但不限制其他地区下载）|

---

## 1. App 名称 / 副标题（中文）

> **2026-05-05 更新**：原计划名称 `VoxAI`（5 字符）在 ASC 创建时被拒——"VoxAI" 已被 Beijing InOrange Technology 占用（iOS App ID `6448861780`，2023-06-27 之后未更新）。改用 `VoxAI - 用嘴编程`（18 字符）一次过 ASC 名称校验。详见 DR-027。

### App 名称（ASC create-app 弹窗已用此值）
```
VoxAI - 用嘴编程
```
（30 字符限制 · 实际 18 字符）

### 副标题（Subtitle，App Information 页面填）

```
给 Claude Code / Cursor 用的语音输入
```
（30 字符限制 · 实际 28 字符）

> 2026-05-05 Rebecca 拍板。理由：和 App 名 "用嘴编程" 信息无重叠，副标题锁定目标用户（Claude Code / Cursor 使用者），SEO 命中精准。

### 推广文本（Promotional Text，中文 · 170 字符限制）

> Promotional Text 在 ASC 版本页填，**可以随时改而不需要新版本提审**——适合放当前阶段最想用户看到的话（首发宣传 / 限时活动 / 用户反馈热点等）。

**v1.0 首发版本**：
```
VoxAI 1.0 首发——给 Claude Code / Cursor 加一层中文语音输入。说一句话，停下后自动复制到剪贴板，⌘V 粘贴。无账号，无追踪，完全离线。
```
（约 81 字符，在 170 限制内）

**备选**（更短）：
- `给 AI 编程加一层中文语音输入。打开浮窗说话，停下后自动复制剪贴板，⌘V 粘贴到 Claude Code / Cursor。无账号、无追踪、完全离线。`（约 65 字符）

---

## 2. App 名称 / 副标题（英文 Localized）

### App Name
```
VoxAI
```

### Subtitle
```
Chinese voice input for AI coding
```
（30 字符限制 · 实际 32 字符——略超，需要缩到 30 内）

> 30 字符内的备选：
> - `Chinese dictation for AI` (24)
> - `Voice input for AI coding` (25)
> - `Chinese voice → AI prompts` (26)

**推荐**：`Voice input for AI coding`（25 chars，留 buffer）

---

## 3. 应用描述（中文 · 主语言）

> **字符限制**：4000 字符。注意前 5 行非常关键——App Store 搜索结果摘要只展示这部分。

```
用嘴编程——给 Claude Code、Cursor 等 AI 编程助手加一层中文语音输入。

VoxAI 是一款 macOS 上的语音输入工具，专为使用 AI 编程助手的中文开发者设计。
打开浮窗，点麦克风按钮说一句话，文字实时显示在歌词式界面上，停下后自动复制到剪贴板。
切换到 AI 工具按 ⌘V，文字立刻粘贴进去。整个"想到 → 说出 → 出现在 AI 输入框"的流程，
你的手不用离开键盘旁。

【为什么需要 VoxAI】
Claude Code 和 Cursor 这类 AI 编程助手原生不支持中文语音输入——它们只接受键盘文字或英文语音。
打长 prompt 慢、解释复杂代码意图费劲、连续多轮迭代时尤其痛。
VoxAI 用 macOS 系统级中文语音识别（含自动标点）+ 自动剪贴板，把这条路径做到极致顺滑。

【核心功能】
• 实时中文语音识别（基于 Apple 系统级语音识别框架，自动标点）
• 录音停止后自动复制转录文字到剪贴板（核心体验，可在设置里关闭）
• 悬浮窗常驻屏幕最上层，跨 App、跨 Space、全屏可见
• 录音中歌词式渲染，已完成段落渐淡，活跃段落高亮
• 暂停 / 继续 / 清空 / 重新录音
• 60 秒自动续接，无缝长录音
• 菜单栏图标显示当前状态（待机 / 录音中 / 暂停 / 错误）
• ⇧⌘D 重新打开浮窗，⌘, 打开设置

【隐私优先】
• VoxAI 本身不收集、不存储、不上传任何数据
• 不需要注册，没有用户账号系统
• 不联网——entitlements 极简到只有麦克风权限和 App Sandbox
• 语音识别由 Apple 系统级框架处理，按 Apple 隐私政策可能涉及 Apple 服务器（macOS 平台标准行为）
• 完整隐私政策见应用内 Settings 链接

【系统要求】
• macOS 13.0 (Ventura) 或更新版本
• 同时支持 Apple Silicon 和 Intel Mac
• 中文语音识别需要系统已下载对应语言识别包（首次启动时系统自动处理）

【v1.0 不包含的功能】
v1.0 聚焦"用嘴编程"主流程，以下功能留给后续版本视用户反馈再做：
• AI 朗读回复（TTS）
• MCP HTTP 服务器
• 多语言切换 UI
• 自动粘贴到下一层应用

【联系作者】
如有问题或建议，请到 GitHub 提 Issue：github.com/Ethan-YS/VoxAI

VoxAI 由 Ethan 制作，MIT 协议开源。
```

---

## 4. App Description (English · Localized)

```
Voice input for AI coding — built for Chinese developers using Claude Code, Cursor, and similar AI assistants.

VoxAI is a macOS dictation tool designed around one specific gap: AI coding assistants don't natively accept Chinese voice input. VoxAI fills that gap. Open the floating panel, tap the mic, speak in Chinese; the transcript flows live, lyric-style. When you stop, it lands automatically on your clipboard — switch to your AI tool, ⌘V, done. From "thought" to "in the AI's input box," your hand never leaves the keyboard area.

Why you need VoxAI

Claude Code and Cursor accept keyboard text or English voice — not Chinese voice. Typing long prompts is slow, explaining complex code intent in writing is laborious, and back-and-forth iteration is especially painful. VoxAI uses Apple's system-level Chinese speech recognition (with automatic punctuation) plus automatic clipboard handoff to make this path as fluid as possible.

Core features

• Real-time Chinese speech-to-text via Apple's SFSpeechRecognizer (with automatic punctuation)
• Auto-copy transcript to clipboard on stop (the core experience — toggleable in Settings)
• Floating panel stays on top across apps, Spaces, and full-screen sessions
• Lyric-style rendering: completed segments fade, active segment highlighted
• Pause / Resume / Clear / Re-record controls
• 60-second auto-continuation for seamless long dictation
• Menu-bar icon reflects status (idle / recording / paused / error)
• ⇧⌘D re-opens the dialog; ⌘, opens Settings

Privacy first

• VoxAI itself collects, stores, and uploads NOTHING
• No accounts, no registration
• Offline by design — entitlements are limited to microphone and App Sandbox; there is literally no network code in v1.0
• Speech recognition is handled by Apple's system framework. Per Apple's privacy policy, this may involve Apple's servers (the standard behavior on macOS)
• Full privacy policy linked from in-app Settings

Requirements

• macOS 13.0 (Ventura) or later
• Apple Silicon and Intel Mac both supported
• Chinese voice recognition requires the corresponding language pack to be downloaded by the system (handled automatically by macOS on first use)

What v1.0 deliberately does NOT include

v1.0 focuses on the "用嘴编程" (voice-to-AI dictation) main flow. These will be evaluated for later versions based on user feedback:
• AI text-to-speech (read-aloud)
• MCP HTTP server integration
• Language switcher UI
• Auto-paste to underlying app

Contact

For issues or suggestions, file a GitHub Issue: github.com/Ethan-YS/VoxAI

VoxAI is built by Ethan and is MIT-licensed open source.
```

---

## 5. 关键词（中文，100 字符限制）

```
用嘴编程,语音输入,语音转文字,AI助手,Claude Code,Cursor,中文语音,听写,语音编程,实时转录
```
（约 76 字符 · 留 buffer 给 ASC 自动 normalize）

> 不要重复 App 名（"VoxAI"）和描述里的核心词——ASC 会自动 index 那些。
> 关键词应该是用户**实际搜索时会输入但描述里可能没出现**的词。

## 6. Keywords (English, 100 字符限制)

```
voice input,dictation,Chinese,AI coding,Claude,Cursor,speech to text,transcribe,voice typing
```
（约 96 字符）

---

## 7. URL 字段

| 字段 | 值 |
|---|---|
| **Privacy Policy URL** | `https://ethan-ys.github.io/VoxAI/privacy.html` |
| **Marketing URL**（可选） | `https://github.com/Ethan-YS/VoxAI`（暂用 GitHub README，未来可换 landing page）|
| **Support URL** | `https://github.com/Ethan-YS/VoxAI/issues` |

> 隐私政策 URL 必须在提审前**真实可访问**。
> docs/privacy.html 已写好，需要 Rebecca 启用 GitHub Pages（仓库 Settings → Pages → Source: main, /docs）。

---

## 8. App Review Notes（极简版，提审时填）

```
VoxAI is a Chinese-language voice input tool for AI coding assistants
(Claude Code, Cursor, etc.). The user speaks Chinese, VoxAI transcribes
via Apple's SFSpeechRecognizer, and the transcript is auto-copied to
the system clipboard so the user can paste it into the AI tool.
That is the entire feature scope of v1.0.

Microphone access is required for speech-to-text. Audio is processed
by Apple's system framework (SFSpeechRecognizer), which may transmit
to Apple servers per Apple's privacy policy. VoxAI itself does not
store, upload, or transmit any audio or text outside the system
clipboard.

Network access: entitlements do NOT include com.apple.security.network.client
or com.apple.security.network.server. VoxAI v1.0 is technically incapable
of making outbound network connections. No telemetry, no analytics,
no third-party SDKs.

Required Reason API: UserDefaults (CA92.1 — only this app's container).
Declared in PrivacyInfo.xcprivacy.

Test instructions for App Reviewer:
1. Launch VoxAI. A floating panel appears top-right of the screen.
2. Click the microphone button. Grant Microphone + Speech Recognition
   permissions when prompted (both required).
3. Speak any Chinese sentence (or English — Apple's recognizer handles
   both, though VoxAI is marketed for Chinese).
4. Click the blue stop button. The title bar will briefly flash a
   "Copied" tag, indicating the transcript is on the system clipboard.
5. Switch to any text field (e.g. TextEdit) and ⌘V. The transcript
   pastes in.

That's the full user journey. There is no account, no login, no
in-app purchase, no subscription, no external service to test.

Source code (MIT-licensed): https://github.com/Ethan-YS/VoxAI
Privacy policy: https://ethan-ys.github.io/VoxAI/privacy.html
```

---

## 9. 截图清单（Phase 4.2）

ASC macOS app 接受的尺寸（必须是其中之一）：
- 1280×800
- 1440×900
- **2560×1600**（现代 13" MBP Retina）
- **2880×1800**（现代 14"/16" MBP Retina）
- 3024×1964

每种尺寸至少 1 张，最多 10 张。建议提交 ≥3 张。

**v1.0 推荐 3 张内容**：
1. **浮窗待机叠桌面**：VoxAI 浮窗 idle 状态 + 麦克风按钮，背景是开发者会用的桌面（IDE 或一些代码窗口）
2. **录音中歌词**：浮窗显示几句正在识别的中文（含技术术语，比如"解释一下 useEffect 的依赖数组"），波形动画进行中
3. **完成态 + 粘贴效果**：浮窗显示已停止录音的 transcript + 一旁打开的 Claude Code（或 Cursor）窗口里能看到刚刚粘贴进去的同一段文字

**截图技巧**：
- 用 `⌘⇧4` + 空格选屏幕区域，或 `⌘⇧3` 全屏
- 截后用 macOS 自带 Preview 裁剪到目标尺寸
- 不要在截图里露出私人信息（聊天窗口 / 邮箱 / 文档名）

**当前状态（2026-05-05 截图就绪）**：

ASC 用全屏截图（3024×1964，符合 ASC "13"/16" Retina" 尺寸标准）：
| 文件 | 内容 | 尺寸 |
|---|---|---|
| `docs/screenshots/asc-1-floating.png` | 浮窗悬浮在桌面壁纸（湖景）—— 展示常驻特性 | 3024×1964 (5.9MB) |
| `docs/screenshots/asc-2-recording.png` | 浮窗录音中歌词 + 旁边 Claude Code 窗口 —— 展示用嘴编程主场景 | 3024×1964 (752KB) |
| `docs/screenshots/asc-3-finished.png` | 浮窗完成态（绿色 ✓ "已复制" + 重录按钮）+ 旁边 Claude Code —— 展示 DR-020 自动复制结果 | 3024×1964 (692KB) |

3 张连成一个故事：**桌面悬浮 → 录音中 → 自动复制完成准备粘贴**。
asc-1 偏大（5.9MB）是因为桌面壁纸细节多，ASC 上限 8MB 安全。

README / 项目文档用的浮窗局部素材（840×840）保留在 `docs/screenshots/ui-{idle,recording,finished}.png`。

---

## 10. App 隐私（Privacy Details）填写指引

> ASC 位置：信任和安全性 → **App 隐私**。这是 App Store "营养标签"（隐私详情卡片）的来源——上架后用户在 App Store 商品页能看到。

### 关键概念

ASC 问的是 **"你的 App 自己收集了什么数据"**，而不是 "你用的系统框架处理了什么"。
- VoxAI 不存储 / 不上传 / 不传输任何数据 → 答 **"No data collected"**
- 麦克风音频喂给 Apple 系统级 SFSpeechRecognizer 框架处理后立即丢弃；识别结果显示在浮窗 + 写入系统 Pasteboard。这都是 macOS 系统行为，**不是 VoxAI 自己收集**

### 表单选择

| 问题 | 选 | 理由 |
|---|---|---|
| 你的 App 是否从这个 App 收集任何数据？ | **No** | VoxAI 没有自己的服务器、没有分析 SDK、没有 telemetry、没有任何数据持久化（除 UserDefaults 仅存本机配置）|
| 是否使用任何 SDK 跨 App 或网站追踪用户？ | **No** | v1.0 砍掉所有第三方 SPM 依赖（DR-022），没有 SDK |

选 No 之后 ASC 跳过详细类别问卷（联系方式 / 健康 / 金融 / 位置等）。

### 营养标签预览结果

应该显示 **"Data Not Collected"**（数据未收集）—— App Store 上是干净的"无追踪"标签。

---

## 11. 出口合规（Encryption / Export Compliance）

> ASC 位置：1.0 版本页底部 **App 加密** 区域（首次提审时跳出 modal 询问）。

### 关键事实

- VoxAI v1.0 entitlements 没有 `network.client` / `network.server`（DR-022 切了之后）
- 没有任何自己的加密代码 / HTTPS / TLS / 自定义加密算法
- 完全依赖 macOS 系统框架（SFSpeechRecognizer、AVAudioEngine、Pasteboard）

### 表单选择

| 问题 | 选 | 理由 |
|---|---|---|
| 你的 App 是否使用加密？ | **No** | VoxAI 不直接调用任何加密 API（即使 macOS 系统框架内部用了，也不归我们声明）|

选 "No" 后 ASC 跳过 ECCN / BIS 申报问卷。

### Info.plist 标记（可选优化）

可以在项目里加 `ITSAppUsesNonExemptEncryption = NO` 让 ASC 永久跳过这个问题（每次新版本不再问）。

```diff
# project.pbxproj 的两个 buildSettings (Debug + Release):
+ INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO;
```

v1.0 没加（手动每次答 No 也行）。v1.x 时 Sage 顺手补上。

---

## 12. 提审前最后核对

- [ ] 隐私政策 URL 真实可访问（GitHub Pages 启用）
- [ ] 截图 3 张已上传 ASC，符合标准尺寸
- [ ] 应用描述中英文都已填
- [ ] 关键词中英文都已填
- [ ] App Review Notes 已填（第 8 节）
- [ ] 类别正确（Productivity 主 / Developer Tools 副）
- [ ] 价格 = 免费
- [ ] 版本号 = 1.0，build 号 = 1（首次提审）
- [ ] What's New = "首发" / "Initial release"
- [ ] 内容分级（Age Rating）= 4+（无敏感内容）
- [ ] App 隐私 = Data Not Collected（§10）
- [ ] 出口合规 = Not using encryption（§11）

提审包：`build/Export-AppStore/VoxAI.pkg`（已 Apple Distribution 签名 + Universal Binary）。上传方式见 §13。

---

## 13. Build 上传到 ASC

> Sage 已 archive + export 完成，产物 `build/Export-AppStore/VoxAI.pkg`（3.6 MB，Apple Distribution 签名，TeamIdentifier `YNMBJ5H736`）。

### 上传方式（推荐顺序）

**A. Transporter（macOS App Store 免费 App，最简单）** ★ 推荐
1. 安装 Transporter（Mac App Store 搜 "Transporter" by Apple，免费）
2. 启动后用 ASC 中国账号 `hrebeccaqy@icloud.com` 登录
3. 拖 `build/Export-AppStore/VoxAI.pkg` 进 Transporter 窗口
4. Transporter 自动 verify + 提示上传 → 点 "Deliver"
5. 等 5-15 分钟，上传 + ASC 服务端处理

**B. xcrun altool（命令行）**
- 需要 ASC API Key（在 ASC → 用户和访问 → 集成 → App Store Connect API 创建一个）
- 命令：`xcrun altool --upload-app -f build/Export-AppStore/VoxAI.pkg -t macos --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>`
- v1.0 首次上传不必走这条；Transporter 更直观

**C. xcodebuild -exportArchive --upload**
- Xcode 16+ 的新选项，但需要 ASC API Key
- 同 B，v1.0 不必走

### 上传后

1. ASC 服务端处理 5-30 分钟（构建版本扫描 + 加密合规 + 内部 validation）
2. 处理完成后在 ASC → App → 1.0 版本页面 → "构建版本" 区会出现可选 build
3. 选择 build → 填出口合规答案（如果 Info.plist 没标）→ 保存
4. 完成所有 §10/§11/§12 字段 → 点右上角 "**添加以供审核**" → 提交

### 上传遇到的常见错误

| 错误 | 原因 | 解决 |
|---|---|---|
| "ITMS-90238: Invalid Signature" | 签名不是 Apple Distribution | 重 archive，verify `codesign -dvvv` 显示 Apple Distribution |
| "ITMS-90713: Missing Info.plist value LSApplicationCategoryType" | 缺类别 | 已在 v1.0 修（commit `<this commit>`）|
| "ITMS-90683: Missing Purpose String" | NSMicrophoneUsageDescription 等缺 | check INFOPLIST_KEY_NS*UsageDescription |
| "Bundle is invalid" / "Asset Catalog Compiler" | AppIcon 配置 | actool 警告 "unassigned child"——v1.0 这个不是 blocking，但反复出现可考虑补 light/dark/tinted variants |

---

## 14. 提审通过后的 GitHub 收尾

> 记录于 2026-05-05，等 Apple 审核通过后做。Topics 已在 release-ready 阶段加完（macos / swift / swiftui / voice-input / dictation / speech-to-text / chinese / claude-code / cursor / accessibility-app / app-store / app-sandbox），此节只列**上架后**的事项。

### 14.1 建 GitHub Release（推荐）

`v1.0-rc.1` tag 已存在但**没有对应 Release**。上架通过后建一个正式 `v1.0`：

- **不上传 binary**——VoxAI 的分发渠道是 Mac App Store，不是 GitHub Releases（DR-026 切的就是这条线）
- Release 类型：source-only（GitHub 自动 attach 源码 zip / tar.gz 即可）
- Tag：新建 `v1.0`（不复用 rc.1，正式版本号干净）
- Release notes 模板：
  ```markdown
  VoxAI 1.0 is now on the Mac App Store 🎉

  Download: https://apps.apple.com/.../id...

  ## What's in 1.0
  - 中文系统级语音识别（Apple SFSpeechRecognizer）
  - 录音停止后自动复制到剪贴板
  - 浮窗常驻最上层，跨 App / 跨 Space / 全屏可见
  - macOS 13.0+, Apple Silicon + Intel Universal

  ## Source code
  Full Swift source in this repo. MIT licensed.

  ## v1.x roadmap
  See [brain/topics/planning/ROADMAP.md](...) — TTS / MCP / 自动 paste 等可能加回。
  ```
- 命令：
  ```bash
  gh release create v1.0 --repo Ethan-YS/VoxAI \
    --title "VoxAI 1.0 — Now on the Mac App Store" \
    --notes-file <release-notes.md>
  ```

### 14.2 改 Homepage URL 指向 ASC（推荐）

当前 `homepageUrl` = `https://ethan-ys.github.io/VoxAI/privacy.html`（隐私政策）。上架后换成 ASC 产品页：

```bash
gh repo edit Ethan-YS/VoxAI --homepage 'https://apps.apple.com/<region>/app/voxai/id<APPID>'
```

ASC URL 在 ASC record 创建时拿到。

### 14.3 Social preview image（推荐，可选）

仓库分享到 Twitter / Slack / Discord 时显示的卡片图。当前是 GitHub 默认（自动生成的纯文字图）。

- 素材：`docs/screenshots/ui-recording.png`（840×840）或 `usage-1.png` 可直接用，或单独做 1280×640
- **只能 web 上传**：仓库 Settings → General → Social preview → Upload an image
- gh CLI 不支持

### 14.4 GitHub Discussions（看意愿，不推荐 v1.0）

当前 `hasDiscussionsEnabled = false`。开了之后：
- ✅ 用户反馈 / 问题不混在 issues 里
- ❌ 维护成本 +1，社区没起来时会显得空旷

建议：v1.0 阶段保持关闭。等真有用户提 issue 提到吃力时再开。

### 14.5 README badges（可选小事）

[`README.md`](../../../README.md) 头部目前没 badges。可选加：

```markdown
![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.10+-orange)
![License](https://img.shields.io/badge/License-MIT-green)
[![Mac App Store](https://img.shields.io/badge/Mac%20App%20Store-Download-black?logo=apple)](https://apps.apple.com/.../id...)
```

最后一个 badge 等上架后才能加（需要 ASC URL）。


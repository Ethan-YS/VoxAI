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

### App 名称
```
VoxAI
```
（30 字符限制 · 实际 5 字符）

### 副标题（Subtitle）
```
用嘴编程：中文语音转 AI 输入
```
（30 字符限制 · 实际约 22 字符）

> 备选：
> - 用嘴编程·让 AI 听见你的中文（约 18）
> - 中文语音转文字 → AI 编程助手（约 24）

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

## 10. 提审前最后核对

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
- [ ] 出口合规（Export Compliance）：使用标准加密 → 通常勾"使用 Apple 提供的标准 HTTPS / TLS"，但 v1.0 没用网络，可以勾"Not designed to use cryptography"

提审包：用 `method=app-store` 重跑 archive → upload via Transporter 或 Xcode Organizer。

---

## 11. 提审通过后的 GitHub 收尾

> 记录于 2026-05-05，等 Apple 审核通过后做。Topics 已在 release-ready 阶段加完（macos / swift / swiftui / voice-input / dictation / speech-to-text / chinese / claude-code / cursor / accessibility-app / app-store / app-sandbox），此节只列**上架后**的事项。

### 11.1 建 GitHub Release（推荐）

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

### 11.2 改 Homepage URL 指向 ASC（推荐）

当前 `homepageUrl` = `https://ethan-ys.github.io/VoxAI/privacy.html`（隐私政策）。上架后换成 ASC 产品页：

```bash
gh repo edit Ethan-YS/VoxAI --homepage 'https://apps.apple.com/<region>/app/voxai/id<APPID>'
```

ASC URL 在 ASC record 创建时拿到。

### 11.3 Social preview image（推荐，可选）

仓库分享到 Twitter / Slack / Discord 时显示的卡片图。当前是 GitHub 默认（自动生成的纯文字图）。

- 素材：`docs/screenshots/ui-recording.png`（840×840）或 `usage-1.png` 可直接用，或单独做 1280×640
- **只能 web 上传**：仓库 Settings → General → Social preview → Upload an image
- gh CLI 不支持

### 11.4 GitHub Discussions（看意愿，不推荐 v1.0）

当前 `hasDiscussionsEnabled = false`。开了之后：
- ✅ 用户反馈 / 问题不混在 issues 里
- ❌ 维护成本 +1，社区没起来时会显得空旷

建议：v1.0 阶段保持关闭。等真有用户提 issue 提到吃力时再开。

### 11.5 README badges（可选小事）

[`README.md`](../../../README.md) 头部目前没 badges。可选加：

```markdown
![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.10+-orange)
![License](https://img.shields.io/badge/License-MIT-green)
[![Mac App Store](https://img.shields.io/badge/Mac%20App%20Store-Download-black?logo=apple)](https://apps.apple.com/.../id...)
```

最后一个 badge 等上架后才能加（需要 ASC URL）。


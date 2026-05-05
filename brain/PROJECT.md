# PROJECT — VoxAI

> **这份文件回答**："这个项目是什么？解决什么问题？**不做什么**？"
>
> **特性**：内容几乎不变。如果开始频繁变动，说明项目定位在漂移——
> 这件事本身应该被 `DECISIONS.md` 记录，而不是在这份文件里反复改写。
>
> **谁该读**：首次接触项目的人（包括未来的我）；不确定项目边界时。

---

## 一句话定义

**用嘴编程。**

VoxAI 是 macOS 上的语音输入工具——用户对着麦克风说话，文字流畅出现并自动进入剪贴板，无缝粘到 Claude Code（或其他 AI 编程工具）里。

## 解决什么问题

AI 编程助手（Claude Code 等）的主流交互是键盘文字——但**写 prompt 慢**是开发者长期的真实痛点：
- 长指令、复杂上下文、多轮迭代用打字效率低
- 解释代码意图时口头表达比文字更顺
- 写完一段代码再想问点东西，手离开键盘说一句比切回去打字快

VoxAI 把"开发者用嘴说话 → 转成文字 → 进入 AI 输入框"这条路径做到极致顺滑：
1. 悬浮窗常驻，按钮一点开始录音
2. 系统级语音识别（自动标点、60s 续接）
3. 录音停止后**自动复制到剪贴板**（默认开）
4. 用户切到 Claude 直接 ⌘V

**MCP server / TTS 朗读**作为次要功能存在（让 AI 能朗读回复给用户听），但**不是主推卖点**——v1 的核心战场是"用户 → AI"的输入侧。

**为什么是新仓**：旧版 [VoxSage](../VoxSage/) 走 GitHub DMG 路线，依赖 Python 后端（whisperx + mlx-audio + edge-tts + chatterbox）通过 spawn 子进程跑 MCP server。这套架构和 **Mac App Store Sandbox** 有结构性冲突：

- Sandbox 不允许 spawn 用户路径下的 Python 进程
- HuggingFace 模型下载需要 token，Sandbox 内难以处理
- stdio MCP 模式（外部工具调本地脚本）App Store 应用做不到

所以走**双轨发布**：旧 VoxSage 留在 GitHub Releases 给开发者全功能版；新 VoxAI 走 Mac App Store 给普通用户 ASR 输入聚焦版。两个仓库**不共享二进制**，VoxAI 是纯 Swift 重写。

## 刻意不做什么（非目标）

> **2026-05-04 切片更新**：v1.0 范围从原计划（含 TTS + MCP server）切片到 **ASR-only MVP**——只做"用嘴编程"主流程。TTS / MCP / Cloud 配置全部留 v1.1+。详见 DR-021 / DR-022。

每一条都源自明确决策，不是遗漏：

### v1.0 砍掉的（v1.1+ 视用户反馈再决定）

- **不做 AI 朗读 TTS（v1.0）**——`TTSEngine` / `SystemTTSEngine` / `OpenAITTSClient` 整套不写。先发 MVP 验证主流程是否被需要，再决定 v1.1 加不加。详见 DR-021
- **不做 MCP HTTP server（v1.0）**——TTS 砍了 MCP 没意义，整个 MCPServer.swift / mcp-config.json / SwiftNIO / swift-sdk 不引入。意外好处：entitlements 简到极致（只剩 sandbox + audio-input），审核风险大幅降低。详见 DR-022
- **不暴露语言切换 UI（v1.0）**——目标市场是中文，默认 zh-CN。Settings UI 不放语言选项。详见 DR-023
- **不做"自动 paste 到下层 App"（v1.0）**——CGEvent 模拟键盘需要 Accessibility 权限，授权摩擦大 + Sandbox 受限 + 审核风险。v1.x 看用户反馈。详见 DR-024

### v1.x 也不做的（永久边界）

- **不做会议模式（v1）**——依赖 whisperx 离线转录 + pyannote 声纹分离，迁移到 WhisperKit 工作量 ≥ 2 周。v1.1 评估。详见 DR-004
- **不做声纹分离（v1）**——同上依赖链
- **不打包 edge-tts**——逆向 Microsoft 未公开 API，同时踩 App Store Guideline 2.5.1（public APIs only）+ 5.2.2（third-party authorization）+ GPL-3.0 许可证三道雷。详见 DR-008 / LICENSE_AUDIT
- **不打包 Python 后端**——Sandbox 禁止 spawn 用户路径下的 Python；纯 Swift 实现是 App Store 路线的硬约束。详见 DR-003
- **不做本地中文 TTS（Qwen3-TTS / mlx-audio）**——无 Swift 包装
- **不做本地英文 TTS（Chatterbox）**——无 Swift 包装
- **不做 SFSpeechRecognizer on-device 开关（v1）**——v1 主打体验/识别准确率，默认走 Apple 服务器。隐私政策诚实告知。详见 DR-018
- **不替代 VoxSage**——双轨发布，旧仓继续维护，新仓只做 ASR 聚焦的子集
- **不做录音 app / 笔记 app**——定位是"开发者的语音输入工具"
- **不做 SaaS / 订阅模式（v1）**——v1 免费，最大化用户基数。详见 DR-016

## 目标用户 / 使用者

**主要用户**：
- **使用 Claude Code / Cursor / 其他 AI 编程工具的中文开发者**——希望用中文语音写 prompt，取代部分键盘输入。Claude Code 本身不支持中文语音输入，VoxAI 填这个差异化空白
- **次要英文用户**：英文 SFSpeechRecognizer 也能用，但 Claude Code 自带键盘对英文已够用，VoxAI 对英文用户吸引力较弱

**不是给谁用**：
- 不会用 Claude Code 等 AI 工具的普通用户——VoxAI 没有独立价值
- 需要会议转录 / 字幕的用户——v1 没有这个功能，引导他们去 VoxSage（旧版有）
- 想要离线 / 本地隐私的用户——v1 用 Apple 服务器识别（详见 DR-018），隐私敏感用户应等 v1.x 评估 on-device 选项
- 想要 AI 朗读功能的用户——v1.0 不含 TTS，留 v1.1 评估（详见 DR-021）

**用户故事**（v1.0）：
> 我在 Claude Code 里写代码，想让它解释这段函数。我点 VoxAI 浮窗的录音按钮，对着麦克风说"解释一下这个文件第 42 行那个递归，特别是 base case 那部分逻辑"。点停止——文字已经在剪贴板里。切到 Claude，⌘V，回车。整个过程我的手没离开过键盘旁边。

**v1.0 不包含 AI 朗读功能**——朗读 AI 回复的需求留 v1.1 视用户反馈再决定。

## 项目起源与核心信念

VoxAI 是 [VoxSage](../VoxSage/) 的"上架兄弟"——同一愿景的两个分发渠道，但 **VoxAI 在 ASR 输入侧聚焦**。

**核心信念**：
- **用嘴说比用手打更高带宽**——开发者长期被键盘瓶颈低估
- **流畅是体验的核心**——少一步手部动作，差别巨大（自动复制到剪贴板就是这个信念的体现）
- **用户的隐私和钱由用户控制**——VoxAI 不绑定任何 TTS 服务方；ASR 用 Apple 系统级，诚实告知数据流向
- **App Store 渠道值得做**——即使要砍掉一半功能换上架，触达普通开发者用户的价值也值得这次重构
- **法务洁癖**——任何会让 App Store 审核为难、或让用户协议踩雷的依赖都不要（edge-tts 是典型例子）

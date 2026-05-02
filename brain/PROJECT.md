# PROJECT — VoxAI

> **这份文件回答**："这个项目是什么？解决什么问题？**不做什么**？"
>
> **特性**：内容几乎不变。如果开始频繁变动，说明项目定位在漂移——
> 这件事本身应该被 `DECISIONS.md` 记录，而不是在这份文件里反复改写。
>
> **谁该读**：首次接触项目的人（包括未来的我）；不确定项目边界时。

---

## 一句话定义

**给 AI 加一层语音 I/O 的 macOS 应用——主战场 Claude Code，外延到所有 MCP 兼容工具。**

## 解决什么问题

AI 编程助手（Claude Code 等）只能通过键盘文字交互，存在两个具体痛点：

1. **写 prompt 慢**——长指令、复杂上下文用打字效率低，开发者经常想"说出来"而不是"敲出来"
2. **AI 输出只能看不能听**——长回复要逐行读，多轮对话期间无法腾出眼睛做别的事

VoxAI 通过 MCP 协议把"语音输入 → 文字"和"文字 → 语音输出"做成 Claude Code 等工具可以直接调用的能力，让 AI 真正"听得见、说得出"。

**为什么是新仓**：旧版 [VoxSage](../VoxSage/) 走 GitHub DMG 路线，依赖 Python 后端（whisperx + mlx-audio + edge-tts + chatterbox）通过 spawn 子进程跑 MCP server。这套架构和 **Mac App Store Sandbox** 有结构性冲突：

- Sandbox 不允许 spawn 用户路径下的 Python 进程
- HuggingFace 模型下载需要 token，Sandbox 内难以处理
- stdio MCP 模式（外部工具调本地脚本）App Store 应用做不到

所以走**双轨发布**：旧 VoxSage 留在 GitHub Releases 给开发者全功能版；新 VoxAI 走 Mac App Store 给普通用户核心能力。两个仓库**不共享二进制**，VoxAI 是纯 Swift 重写。

## 刻意不做什么（非目标）

每一条都源自明确决策，不是遗漏：

- **不做会议模式（v1）**——依赖 whisperx 离线转录 + pyannote 声纹分离，迁移到 WhisperKit 工作量 ≥ 2 周。优先把核心 MCP 语音 I/O 做扎实上线，会议模式留给 v1.1。详见 DECISIONS DR-004。
- **不做声纹分离（v1）**——同上依赖链，且即使有也是 v1.1 才考虑。
- **不绑定特定 TTS 服务方**——Cloud TTS 走"用户自带 OpenAI API key + OpenAI 兼容协议"。**不打包 edge-tts**，因为它逆向 Microsoft 未公开 API，会同时踩 App Store Guideline 2.5.1（public APIs only）+ 5.2.2（third-party authorization）两条硬条款。详见 DECISIONS DR-008。
- **不打包 Python 后端**——Sandbox 禁止 spawn 用户路径下的 Python；打包 Python 进 bundle 复杂度极高。纯 Swift 实现是 App Store 路线的硬约束。详见 DECISIONS DR-003。
- **不做本地中文 TTS（Qwen3-TTS / mlx-audio）**——无 Swift 包装，且 Apple 系统中文音质够用。
- **不做本地英文 TTS（Chatterbox）**——同理，AVSpeechSynthesizer 已能覆盖。
- **不替代 VoxSage**——双轨发布，旧仓继续维护，新仓只做能上架的子集。
- **不做录音 app / 笔记 app**——定位是"AI 的语音桥梁"，不是独立的语音工具。
- **不做 SaaS / 订阅模式（v1）**——v1 免费，最大化用户基数；商业化模型留给后续版本。

## 目标用户 / 使用者

**主要用户**：
- **使用 Claude Code 等 MCP 兼容 AI 工具的开发者**——希望用语音和 AI 交互（输入 prompt、听 AI 朗读回复）
- **有付费 OpenAI API key 的用户**——想用更高音质的 Cloud TTS（System TTS 始终可用，不强制）

**不是给谁用**：
- 不会用 Claude Code 或 MCP 工具的普通用户——VoxAI 没有独立价值
- 需要会议转录 / 字幕的用户——v1 没有这个功能，引导他们去 VoxSage（旧版有）
- 想要离线英文高音质 TTS 的用户——v1 没有，只能用 System TTS 或 Cloud

**用户故事**：
> 我在 Claude Code 里写代码，想让它解释这段函数。我直接对着麦克风说"解释一下这个文件第 42 行那个递归"，VoxAI 把语音转文字推给 Claude；Claude 给出长解释，我点"speak"让 VoxAI 朗读出来，我边听边继续写下一段代码。

## 项目起源与核心信念

VoxAI 是 [VoxSage](../VoxSage/) 的"上架兄弟"——同一愿景的两个分发渠道。

**核心信念**：
- **AI 协作应该跨越键盘的瓶颈**——语音是开发者长期被忽视的高带宽接口
- **用户的隐私和钱由用户控制**——VoxAI 不绑定任何 TTS 服务方，用户自带 key、自负责数据流向
- **App Store 渠道值得做**——即使要砍掉一半功能换上架，触达普通用户的价值也值得这次重构
- **法务洁癖**——任何会让 App Store 审核为难、或让用户协议踩雷的依赖都不要（edge-tts 是典型例子）

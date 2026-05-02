# LICENSE_AUDIT — 第三方依赖与开源许可证审计

> **这份文件回答**：VoxAI 用了哪些第三方技术？各自什么许可证？有没有冲突或法务风险？
>
> **谁该读**：引入新依赖前；Phase 4 提审前；任何时候 Rebecca 担心法务问题时。
> **维护纪律**：每加一条依赖立即追加条目；标 ✅ 已审 / ⏳ 待审 / ⚠️ 有问题。
>
> **免责声明**：本文件由 Sage 整理常识级许可证情况，**不是法律意见**。重大商业用途前请咨询律师。

---

## 一、VoxAI 自身许可证

**选择**：MIT（继承 VoxSage 决策，DECISIONS DR-014）

**理由**：
- 旧 VoxSage 已是 MIT，保持一致性
- MIT 是宽松许可证，最大化用户和潜在贡献者的自由
- 与 VoxAI 引入的所有依赖兼容（无 copyleft 冲突）

## 二、VoxAI 引入的依赖

### 2.1 已确认要用

| 依赖 | 版本 | 许可证 | 兼容性 | 状态 |
|---|---|---|---|---|
| `modelcontextprotocol/swift-sdk` | v0.12.0 | MIT | ✅ MIT 兼容 MIT | ✅ 已审 |
| `swift-nio` | 5.x | Apache 2.0 | ✅ Apache 2.0 兼容 MIT（需保留 NOTICE 文件） | ✅ 已审 |
| `swift-system` | 1.x | Apache 2.0 | ✅ 同上（swift-sdk 间接依赖） | ✅ 已审 |
| `swift-log` | 1.x | Apache 2.0 | ✅ 同上（swift-sdk 间接依赖） | ✅ 已审 |
| `mattt/eventsource` | latest | MIT | ✅ MIT 兼容 MIT（swift-sdk 间接依赖） | ✅ 已审 |

### 2.2 Apple 系统框架（不算第三方依赖）

| 框架 | 许可证 | 备注 |
|---|---|---|
| `SFSpeechRecognizer` (Speech.framework) | Apple SDK License | App Store 应用使用无限制 |
| `AVSpeechSynthesizer` (AVFoundation) | Apple SDK License | 同上 |
| `AVAudioEngine` (AVFoundation) | Apple SDK License | 同上 |
| `Foundation` / `SwiftUI` / `AppKit` | Apple SDK License | 同上 |
| `Network.framework`（如果 fallback） | Apple SDK License | 同上 |

Apple SDK 的限制：必须为 Apple 平台开发应用。VoxAI 是 macOS app，符合。

### 2.3 待审（Phase 1+ 引入时单独审）

| 依赖 | 何时审 | 备注 |
|---|---|---|
| 任何 SPM package（icon 库、log 库等） | 引入时 | 必须是 MIT / Apache 2.0 / BSD-2/3 之一才接受 |
| WhisperKit（v1.1） | v1.1 启动时 | 需查确认（应该是 MIT，但要核实） |

## 三、明确**不**用的依赖（法务原因）

### 3.1 edge-tts — 砍

**问题**：
- 许可证：GPL-3.0（强 copyleft）
- 实现方式：逆向工程 Microsoft Edge "Read Aloud" 未公开 API

**双重法务风险**：
1. **GPL-3.0 污染**：如果 VoxAI 直接打包 / 链接 edge-tts，整个 VoxAI 必须开源 GPL-3.0，与 MIT 选择冲突
2. **App Store Guideline 2.5.1**：`Apps may only use public APIs` —— Microsoft Edge Read Aloud 不是公开 API
3. **App Store Guideline 5.2.2**：`Third-Party Sites/Services ... ensure that you are specifically permitted to do so under the service's terms of use. Authorization must be provided upon request.` —— 我们拿不出 Microsoft 授权

**说明 VoxSage 的情况**：旧 VoxSage 通过 spawn Python subprocess 调用 edge-tts CLI——这是**独立进程通信**，一般共识下不构成 derivative work，所以 VoxSage 维持 MIT 是合理的。但**任何 GPL 依赖在 App Store 渠道都额外踩 2.5.1 / 5.2.2，不能用**。

**VoxAI 应对**：完全不依赖 edge-tts。Cloud TTS 改"用户自带 OpenAI API key + OpenAI 兼容协议"——用户的 key、用户接受 OpenAI ToS，VoxAI 仅作 HTTP client，零法务风险。详见 DECISIONS DR-008。

### 3.2 whisperx — 砍

**问题**：
- 依赖 `pyannote.audio` 用于 VAD / 声纹分离
- 模型 weights 从 Hugging Face 下载需要 token
- Sandbox 内无法可靠 spawn Python 进程

**许可证情况**（仅供参考，**Phase 1 引入 WhisperKit 时也要审**）：
- whisperx 本身：BSD-4-Clause（待最终核实）
- pyannote.audio：MIT
- pyannote 模型 weights：**有专门 license**——商业用途要 Hugging Face 上单独同意

**VoxAI 应对**：v1 完全不做会议模式。v1.1 改用 **WhisperKit**（Apple 生态原生，应是 MIT/Apache 2.0，引入时单独审）。

### 3.3 mlx-audio — 砍

**问题**：
- 无 Swift 包装，要走 Python
- Sandbox 不允许 spawn Python

**许可证情况**：mlx-audio 项目本身一般是 MIT/Apache 2.0（Apple 系，待引入时核实），但**实现路径在 Sandbox 下走不通**——许可证不是主要问题，技术兼容才是。

**VoxAI 应对**：v1 用 AVSpeechSynthesizer 系统中文，够用。

### 3.4 chatterbox — 砍

**问题**：同 mlx-audio——无 Swift 路径，Sandbox 不兼容。

**许可证情况**：未审计（不打算用，无审必要）。

**VoxAI 应对**：v1 用 AVSpeechSynthesizer 系统英文。

## 四、VoxSage（旧仓）继承的代码

VoxAI 从 VoxSage **参考** / **重写**了以下设计：
- `TranscriptionService` 的 `sessionGeneration` 防过期回调机制 → 重写到 VoxAI（PLAN/ROADMAP Phase 1.5）
- `DialogView` 的歌词式渲染 → 重写到 VoxAI（Phase 1.6）
- App Icon（sparkles + 蓝紫渐变）→ 沿用

**许可证安全性**：VoxSage 是 MIT，VoxAI 是 MIT，跨仓代码复用无问题。**只要 VoxSage 那段代码本身不来自 GPL 上游**就行——已确认这些都是原创实现，没有从 edge-tts / whisperx 等抄代码。

## 五、用户行为相关的法务边界

### 5.1 用户配的 Cloud TTS endpoint

VoxAI 是 HTTP client，把用户输入的文字 POST 到用户配的 endpoint。

**法务边界**：
- VoxAI 不为 endpoint 本身的合规性负责（用户填什么 endpoint 是用户的事）
- 但 **隐私政策必须明确**：用户的文字内容会发到用户配置的 endpoint，VoxAI 不审查也不缓存——见 `APP_STORE_CHECKLIST.md` 第五节

### 5.2 用户的 API Key

存 macOS Keychain（DECISIONS DR-009）。

**法务边界**：
- VoxAI 永远不上传用户 key 到任何服务器
- VoxAI 不发起到 voxai.com / 类似域名的任何调用——避免被怀疑收集 key（见 RISKS R-009）
- 隐私政策明示

### 5.3 SFSpeechRecognizer 与 Apple 服务器

v1 默认走 Apple 服务器识别（DR-018），不开 on-device 模式。

**法务边界**：
- 这是 Apple 平台 SFSpeechRecognizer 的**标准默认行为**，VoxAI 没有选择的余地（除非主动设 `requiresOnDeviceRecognition = true`，但识别质量明显下降，违背 v1 体验定位）
- 用户使用 SFSpeechRecognizer 即视为接受 Apple 的隐私策略——这一点 macOS 系统已通过"Speech Recognition 权限弹窗"告知用户
- VoxAI 隐私政策需**明确告知**这一行为，不能写"音频不上传"——准确表述见 `APP_STORE_CHECKLIST.md` 第五节

### 5.4 剪贴板写入

DialogView 录音停止后自动把转录文字写入 `NSPasteboard.general`（DR-020），默认开启，Settings 给关闭开关。

**法务边界**：
- 剪贴板是 macOS 系统级共享资源，用户其他 app 可能读到
- 隐私政策需告知"VoxAI 会把转录结果写入系统剪贴板"，让用户知情（敏感行业用户可关闭）

## 六、提审前的法务自查清单

Phase 4 提审前要逐条对一遍：

- [ ] 所有 SPM 依赖的许可证都登记在本文件
- [ ] 没有任何 GPL/AGPL/LGPL 依赖
- [ ] Apache 2.0 依赖的 NOTICE 文件已经包含进 app bundle（如果适用）
- [ ] LICENSE 文件存在且正确（MIT 全文 + 年份 + 作者）
- [ ] App Store Connect "Third-Party Content Acknowledgements" 字段填写
- [ ] 没有用任何"逆向工程的私有 API"（Apple 的 SPI / Microsoft 私有 API 等）
- [ ] PrivacyInfo.xcprivacy 已声明所有数据访问
- [ ] 隐私政策网页已上线，Cloud TTS 的免责清楚

## 七、审计历史

| 日期 | 操作 | 操作人 |
|---|---|---|
| 2026-05-02 | 创建文件，建立审计基线 | Sage |

---

## 八、Rebecca 关心的问题（FAQ）

> **Rebecca 问：v1 这套技术有没有版权或开源使用规则的风险？**

**简答**：**v1 的法务路径已经清干净了。**

具体：
- VoxAI 自身 MIT，与所有依赖（swift-sdk MIT / SwiftNIO Apache 2.0 / Apple SDK）兼容
- 不打包任何 GPL 依赖（edge-tts 已明确砍掉）
- 不调用任何"逆向工程的私有 API"（System TTS 用 Apple 公开 API，Cloud TTS 用 OpenAI 公开 API）
- 用户的 OpenAI key 由用户接受 OpenAI ToS，VoxAI 不连带责任
- App Store Guideline 2.5.1（公开 API） + 5.2.2（第三方授权）都已规避

**还要做的**：
- Phase 1 引入实际 SPM 依赖时，每个新依赖都来这登记一条
- v1.1 引入 WhisperKit 时单独审一次
- 提审前走一遍第六节自查清单

> **Rebecca 拍板（2026-05-02）：v1 主推用嘴编程**

定位调整后法务面没变化——所有依赖、Apple SDK 用法、Cloud TTS 路径都不变。只是 ASR 路径成为主推，所以**SFSpeechRecognizer 的 Apple 服务器处理这件事必须在隐私政策里讲清楚**（见 §5.3）——之前文档草稿写"不上传任何音频"是错的，已修正。

# RISKS — 风险登记与应对

> **这份文件回答**：项目当前已知的工程 / 法务 / 用户体验风险，影响多大，怎么缓解。
>
> **谁该读**：每个 Phase 开始前；做大决策前；估工期前。
> **维护纪律**：发现新风险时**追加**条目；某条风险被消解时改状态为"已消解（YYYY-MM-DD）"，**不删除**——历史本身有价值。

---

## 状态约定

- 🔴 **活跃风险**：当前可能发生，需要持续关注 / 已有缓解方案在跑
- 🟡 **已识别但未触发**：可能发生，已有应对预案，触发了再行动
- 🟢 **已消解**：通过决策 / 实测 / 重构等方式已不构成风险

---

## R-001 用户填的第三方 TTS 服务挂掉 / 改协议

🟡 **已识别但未触发**

**影响**：用户配的 Cloud TTS 调用失败，朗读功能不可用。

**缓解方案**：
- `OpenAITTSClient` 给清晰错误提示（不是默默失败）
- **System TTS 始终可用作 fallback**——用户切回 System 模式立即恢复
- Settings 里 "Test Connection" 按钮帮用户排错

**触发条件**：用户报"speak 不出声"且 System 模式正常。

## R-002 苹果审核拒绝 MCP HTTP server

🟡 **已识别但未触发**

**影响**：上架失败，可能要重大改动。

**应对**：
- 苹果不禁止 localhost server（开发工具普遍如此），但要在 App Review Notes 解释清楚用途（参考 `APP_STORE_CHECKLIST.md` 第四节模板）
- 万一被拒，先在 Resolution Center 答辩；如果坚持拒，考虑改用 `Network.framework` 的 `NWListener`（Apple 原生路径）
- 极端情况：去掉 MCP server，改成 stdio CLI helper（但 Sandbox 下 Claude Code 调不到，等于功能阉割）—— **这条是最坏退路**

## R-003 Intel Mac 用户体验差

🟢 **已消解**（v1.0 范围内）

**理由**：
- v1.0 没有 NN 模型推理（TTS 走 AVSpeechSynthesizer 系统 + OpenAI 云端，ASR 走 SFSpeechRecognizer 系统）
- 跨架构无性能悬崖
- AVAudioEngine sampleRate 差异已在 ARCHITECTURE.md 记录处理方式

**v1.1 重新激活**：引入 WhisperKit 后要重新评估。

## R-004 MCP 协议演进，Claude Code 改接口

🟡 **已识别但未触发**

**影响**：工具失效或要紧急适配。

**缓解**：
- 用官方 swift-sdk（DECISIONS TD-001），SDK 持续跟进 spec 演进
- 关注 modelcontextprotocol.io 更新
- 做好版本协商（initialize 阶段返回 capabilities）

## R-005 Sandbox 下 SwiftNIO 绑定 localhost 端口失败

🟡 **已部分验证**

**影响**：MCP server 起不来，整个核心功能挂掉。

**已有验证**：Phase 0.3 SPM 路径（无 Sandbox）实测通过（DECISIONS TD-005）。

**未验证**：真 Sandbox 内绑定。Phase 2 Xcode 工程接入后才能彻底验。

**fallback 方案**：如果 SwiftNIO 在 Sandbox 下有问题，改用 `Network.framework` 的 `NWListener`——Apple 原生，Sandbox 兼容性最佳，但要自己写 HTTP/1.1 + SSE 编码（多 ~500 行代码）。

## R-006 Xcode 16.x universal binary bug（FB17019201）

🟡 **已识别但未触发**

**影响**：Xcode archive 出来只有 arm64 slice，Intel 用户装了打不开。

**已知事实**：
- 已在 Apple Feedback 记录（FB17019201）
- Phase 0.4 用 SPM 路径**未复现**（DECISIONS TD-006）
- 但 SPM 通了不等于 Xcode 项目通

**应对**：
- Phase 1.1 创建 Xcode 项目后**立即 archive 验证**，`lipo -info` 看到双 slice 才算过
- 如果出现：先尝试 archive build 路径；不行考虑 Xcode 版本选型（升级到更新版本或降到 15.x）

## R-007 第三方依赖许可证踩雷

🟡 **已识别，待 Phase 1 完成审计**

**影响**：开源协议冲突 / App Store 法务风险。

**已规避**：
- v1 不绑定 edge-tts（GPL/逆向 Microsoft 私有 API 双重风险）
- v1 不打包任何 Python 依赖

**待审计**：
- swift-sdk（MIT）✅
- SwiftNIO（Apache 2.0）✅
- 任何后续引入的 Swift package
- Phase 1 引入的所有 SPM 依赖统一审一遍

详见 `LICENSE_AUDIT.md`。

## R-008 v1 用户量低导致没反馈

🟡 **已识别但未触发**

**影响**：上架后没有用户反馈，无法 iterate。

**缓解**：
- 旧 VoxSage 已有用户基础，README 引导他们看商店版
- 开发者社区（GitHub / X / 即刻）小范围发布
- Claude Code 用户群体重叠度高，定位精准

**真要发生**：v1 免费，能稳定运行，没用户也不算亏 —— 视为"先把基础设施 ship 出去"。

## R-009 用户 OpenAI API Key 安全泄漏

🟡 **已识别但未触发**

**影响**：用户 key 被窃取造成经济损失。

**缓解**：
- API Key 存 macOS Keychain（不落 UserDefaults / 不写日志）
- mcp-config.json 文件权限 600（即使读到也只是 token，不是 OpenAI key）
- 隐私政策明确告知：key 仅本地，不上传任何服务器
- VoxAI 自己**永远不发起任何调用到 voxai.com 或类似域名**——避免任何"我们其实在收集 key"的怀疑

## R-010 ASR 在嘈杂环境识别率低导致差评

🟡 **已识别但未触发**

**影响**：用户体验差，App Store 评分低。

**缓解**：
- v1 不承诺"会议转录"级别的识别——定位是"开发者用嘴写 prompt"，使用场景偏静
- 文案明确："best in quiet environments"
- v1.1 引入 WhisperKit 后才考虑高噪场景

---

## 风险评分汇总（速览）

| ID | 主题 | 状态 | 主要应对 |
|---|---|---|---|
| R-001 | Cloud TTS 服务挂 | 🟡 | System fallback 始终可用 |
| R-002 | App Review 拒 MCP server | 🟡 | Notes 提前解释 |
| R-003 | Intel 性能差 | 🟢 | v1 无 NN，已消解 |
| R-004 | MCP 协议演进 | 🟡 | 用官方 SDK 跟进 |
| R-005 | Sandbox 绑端口失败 | 🟡 | NWListener fallback |
| R-006 | Xcode universal bug | 🟡 | Phase 1.1 立即验 |
| R-007 | 依赖许可证踩雷 | 🟡 | Phase 1 完成审计 |
| R-008 | v1 用户量低 | 🟡 | 旧 VoxSage 引流 |
| R-009 | API Key 泄漏 | 🟡 | Keychain + 不写日志 |
| R-010 | 嘈杂环境识别率 | 🟡 | 定位"安静场景" |

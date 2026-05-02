# DECISIONS — 决策日志

> **这份文件回答**："为什么做了 X？为什么放弃了 Y？"
>
> **特性**：
> - **只追加**，不修改历史条目（即使后来决策被推翻，也用新条目推翻，不改旧条目）
> - **倒序**——最新的在顶部，最老的在底部
> - **每条必填五要素**（见下方模板）
>
> **和 `changelog` 的区别**：
> changelog 是"做了什么"，DECISIONS 是"**为什么**做了什么 + 为什么**没**做另一种"。
> 没有"被否决的替代方案"这一项，这份文件就会退化成 changelog。
>
> **谁该读**：追溯某个设计原因时；想理解项目"为什么长成这样"时；不理解某段现状时。

---

## 写入格式（模板）

```markdown
### YYYY-MM-DD — [决定的简短标题]

- **决定**：具体做了什么
- **为什么**：动机、权衡、触发这个决策的问题
- **被否决的替代方案**：
  - 考虑过 A，为什么没选：...
  - 考虑过 B，为什么没选：...
- **影响范围**：哪些模块/文件/流程受影响
- **触发场景**：什么情况引发了这次决策（bug? 用户反馈? 方案讨论?）
```

---

## 决策记录（最新在顶）

<!-- 新条目追加到这条分隔线下方。不修改已有条目。 -->

---

### 2026-05-02 — 建立项目脑（DR-000）

- **决定**：采用 `brain/` v2 单文件夹结构（接续层 5 份核心 + 专题层 4 分类），项目根 `CLAUDE.md` 改造为接续协议入口（保留现有"工程师兜底原则"等项目特有规则）。把 PLAN.md / ROADMAP.md 内容拆解到 brain/ 各文件，原文件改为短索引指向 brain/。
- **为什么**：项目处于 Phase 0 完成、Phase 1 待启动的关键节点——再往前走代码、决策、风险都会快速增多，**现在搭骨架是成本最低的时机**。Rebecca 主动触发"了解项目信息并整理数据，构建项目脑"。
- **被否决的替代方案**：
  - **等 Phase 1 写完代码再整理**：到时候散文档已经堆积，重构成本变高
  - **只用 PLAN.md + ROADMAP.md 不套 brain/**：单文件混合"产品定位 / 当前状态 / 历史决策 / 路线图"，跨窗口接续时新会话不知道读哪部分先；项目越长越严重
  - **直接 1.5 迁移流程**：项目其实没有"散文档堆积"问题，1.4 + 内容拆解更合适
- **影响范围**：整个项目的文档组织、新会话接续机制、未来跨窗口协作
- **触发场景**：新项目 kick off + 已有 PLAN/ROADMAP 可作为原料拆解。方法论来自 `Sage_Memory_Core/MEMORY/L3-方法经验/skills/project_brain/` v2

---

### 2026-04-29 — 第三方依赖许可证审计（DR-014）

- **决定**：建立 `brain/topics/operations/LICENSE_AUDIT.md` 跟踪所有第三方依赖的许可证情况；Phase 1 引入新依赖时同步登记；提审前走完第六节自查清单
- **为什么**：v1 已经有意识规避了 GPL 依赖（不打包 edge-tts，详见 DR-008），但还需要一份**正式审计文档**——上架时 App Store Connect 要求填 "Third-Party Content Acknowledgements"，且未来 Rebecca 或律师查证时要有依据
- **被否决的替代方案**：
  - **不写专门文件，靠 README 一笔带过**：法务追溯时找不到完整事实表
  - **等提审前再做**：那时候已经引入了大量依赖，一次性梳理工作量大且容易漏
- **影响范围**：所有第三方依赖引入流程；Phase 4 提审；项目长期合规
- **触发场景**：Rebecca 主动提"注意之前使用的技术有没有版权或者开源使用规则"

---

### 2026-04-29 — VoxAI 自身许可证 = MIT（DR-013）

- **决定**：VoxAI 沿用 VoxSage 的 MIT 许可证
- **为什么**：保持双仓一致；MIT 是宽松许可证，对用户和潜在贡献者最友好；与所有引入的依赖（swift-sdk MIT / SwiftNIO Apache 2.0 / Apple SDK）兼容无冲突
- **被否决的替代方案**：
  - **GPL-3.0**：copyleft 太严，限制下游用户；与 App Store 商业分发兼容性差
  - **Apache 2.0**：和 MIT 兼容性都好，但 MIT 更简洁，VoxSage 已是 MIT，无理由改
  - **闭源**：与"双轨发布"的精神矛盾——旧 VoxSage 已开源，VoxAI 闭源会让用户困惑
- **影响范围**：开源策略、贡献者协议、依赖兼容性判定
- **触发场景**：Phase 0 完成准备进入 Phase 1，需要在仓库根加 LICENSE 文件前确认

---

### 2026-04-29 — Phase 0.4 Universal Binary 实测通过（TD-006）

- **决定**：用 SPM 路径验证 `swift build --triple` cross-compile 双架构；Phase 1.1 创建 Xcode 工程后**必须再次 archive 验证**，因为 SPM 通了不等于 Xcode 项目通
- **为什么**：Xcode 16.1/16.2 已知 universal binary bug（Apple FB17019201）—— archive 只产 arm64 slice。Phase 0.4 验证 Xcode 26.x SPM 路径未复现，但 Xcode project 路径未验
- **被否决的替代方案**：
  - **跳过 Phase 0.4 直接进 Phase 1**：投入工程后才发现 universal 出不来，回退成本高
  - **强制锁定 Xcode 15.x**：Xcode 26.x 已经稳定，无理由降级
- **影响范围**：Phase 1.1 必须立即 archive 验证；如果出问题切 archive build 路径或评估 Xcode 版本
- **触发场景**：Phase 0.4 实测，arm64 + x86_64 各自约 12MB，universal 23.82MB，`lipo -info` 显示双 slice

---

### 2026-04-29 — Phase 0.3 conformance server 实测通过（TD-005）

- **决定**：确认 `modelcontextprotocol/swift-sdk` + SwiftNIO 路径完全可用，Phase 2 直接迁移 `MCPConformance/Server/HTTPApp.swift` 模式
- **为什么**：实测 `mcp-everything-server` 启动成功，`curl` MCP `initialize` 返回 HTTP 200 + SSE 帧 + session ID + server capabilities，全链路通
- **被否决的替代方案**：
  - **直接进 Phase 1 不验**：把"SDK 真的能在本机跑通"留作未知，风险高
  - **手写 MCP 协议**：JSON-RPC + SSE + protocol negotiation + session 管理 ≥ 2000 行，造轮子
- **影响范围**：Phase 2 MCPServer 实现路径
- **触发场景**：Phase 0.3 实测（macOS 26.4 / Xcode 26.4.1 / Swift 6.3.1）

---

### 2026-04-29 — HTTP listener 方案 = SwiftNIO（TD-002）

- **决定**：用 SwiftNIO 做 HTTP listener，对接 swift-sdk
- **为什么**：官方 conformance server 现成代码可参考；`NIOHTTP1` 处理协议解析省事；Sandbox 下绑 localhost > 1024 端口已知允许
- **被否决的替代方案**：
  - **`Network.framework` 的 `NWListener`**：Apple 原生、零依赖、Sandbox 兼容性最佳，**但**要自己写 HTTP/1.1 解析 + SSE 帧编码——重复造轮子
  - **第三方 HTTP server 库（Vapor / Hummingbird）**：太重，VoxAI 不需要 web framework
- **影响范围**：MCPServer 实现；二进制大小（约 +10MB SwiftNIO 栈）；跨架构需 Phase 0.4 验证
- **触发场景**：Phase 0.2 选型时

---

### 2026-04-29 — Swift MCP SDK = 官方 swift-sdk v0.12.0（TD-001）

- **决定**：用官方 `modelcontextprotocol/swift-sdk` v0.12.0 而不是自写 JSON-RPC
- **为什么**：
  - 官方 SDK 已发布 0.12.0，活跃维护（107+ commits）
  - 最低 macOS 13.0，与 VoxAI 部署目标完全匹配
  - 内置 `StatefulHTTPServerTransport`：自带 session 管理 / SSE streaming / event store / HTTP request validation
  - JSON-RPC + SSE + 协议版本协商 + session 管理 + event store resumability，自写至少 2000 行 + 大量边界 case
- **被否决的替代方案**：
  - **自写 JSON-RPC**：理论可行（"几百行"是早期错估），实际要处理 session / SSE / spec 演进，造轮子
  - **`loopwork/swift-mcp-sdk`**：社区版本，活跃度和官方差距明显
- **影响范围**：MCPServer 整体实现路径；未来跟进 MCP spec 演进的成本
- **触发场景**：Phase 0.2 选型调研

---

### 2026-04-29 — API Key 存 macOS Keychain（DR-009）

- **决定**：Cloud TTS 的 API Key 存 macOS Keychain，不落 UserDefaults
- **为什么**：Sandbox 内 `Application Support/` 仅存 mcp-config（端口 + token，重启可重生成），但用户的第三方 API Key 是真敏感数据——Keychain 是 macOS 唯一合规存储
- **被否决的替代方案**：
  - **存 UserDefaults**：会被备份到 plist，可能被其他工具读到，不合规
  - **存 mcp-config.json**：和 MCP token 混在一起，提升 mcp-config 文件的敏感度
- **影响范围**：`AppSettings` 设计；Phase 2.4 实现；隐私政策表述
- **触发场景**：Phase 0 设计 Cloud TTS 路径时

---

### 2026-04-29 — Cloud TTS 改"用户自带 OpenAI key"（DR-008）

- **决定**：Cloud TTS 走 OpenAI 兼容协议（POST `{base_url}/audio/speech`），用户自带 OpenAI API Key。v1 主打 OpenAI 自家 API，Base URL 字段保留可改给高级用户接代理服务
- **为什么**：
  - **法务**：edge-tts 同时踩 App Store Guideline 2.5.1（only public APIs）+ 5.2.2（third-party 授权要求）；改"用户的 key、用户接受 OpenAI 服务条款"零法务风险
  - **协议**：HTTP POST + 音频流，比 edge-tts WebSocket 简单
  - **工期**：省 3-4 天开发
- **被否决的替代方案**：
  - **打包 edge-tts**：踩 GPL-3.0 + App Store Guideline 双雷
  - **App 自己内置 TTS 服务方 API Key**：要 VoxAI 团队为 API 调用付费，且把所有用户文字汇集到 VoxAI 服务器（隐私问题）
  - **直接 cover 多家 TTS API**（ElevenLabs / Cartesia / Deepgram）：v1 工期不允许，留 v1.x
- **影响范围**：Cloud TTS 整体架构；Settings UI；隐私政策表述；License audit 结论
- **触发场景**：评估 edge-tts 法务风险时

---

### 2026-04-29 — v1 不做会议模式（DR-004）

- **决定**：v1.0 不包含会议模式 / 声纹分离 / `list_meetings` / `get_meeting` 工具
- **为什么**：依赖 whisperx 离线转录 + pyannote 声纹分离，迁移到 WhisperKit 工作量 ≥ 2 周。优先把核心 MCP 语音 I/O 做扎实上线，会议模式 v1.1 补
- **被否决的替代方案**：
  - **v1 包含完整功能**：工期翻倍，且 WhisperKit 在 Intel Mac 上的性能要单独验证
  - **v1 用 Apple SpeechAnalyzer（macOS 26+）**：deployment target 拉到 26+ 会丢掉大量用户基数（VoxAI 用 13+ 是为兼容 Intel）
- **影响范围**：v1 功能范围；Phase 1-3 工期估算；用户预期管理（v1 文案要明确说"无会议模式，参考 VoxSage 旧版"）
- **触发场景**：双轨发布策略确定后规划 v1 范围

---

### 2026-04-29 — 后端语言 = 纯 Swift（DR-003）

- **决定**：VoxAI 不打包 Python，所有功能纯 Swift 实现
- **为什么**：
  - Sandbox 禁止 spawn 用户路径下的 Python
  - 打包 Python 进 bundle 复杂度极高（要处理 dynlib 路径、site-packages、版本兼容）
  - 即使打包成功，Apple 审核会问"为什么需要 Python"，难解释
- **被否决的替代方案**：
  - **打包 Python embedded**：复杂度高，bundle 体积膨胀（≥100MB），审核风险
  - **用 PythonKit 嵌入**：仍需用户系统装 Python，Sandbox 限制下仍走不通
- **影响范围**：所有功能模块；与 VoxSage 的功能差异（whisperx / mlx-audio / chatterbox 全砍）
- **触发场景**：评估 Sandbox 限制时

---

### 2026-04-29 — MCP transport = HTTP/SSE（DR-002）

- **决定**：MCP server 用 HTTP/SSE transport，不是 stdio
- **为什么**：App Sandbox 不允许 Claude Code 直接 spawn 沙盒应用内的可执行文件——stdio 路死。HTTP localhost + 一次性 token 是最干净的方案
- **被否决的替代方案**：
  - **stdio transport**：Sandbox 下不可达
  - **WebSocket**：MCP spec 不强制，HTTP/SSE 已经够用，且 swift-sdk 内置支持
  - **Unix domain socket**：Sandbox 内的 socket 路径外部进程访问受限
- **影响范围**：MCPServer 整个架构；用户配置流程（要复制 mcp-config 而不是 binary 路径）
- **触发场景**：Sandbox 限制评估

---

### 2026-04-29 — 双轨发布策略（DR-001）

- **决定**：建立 VoxAI 新仓走 App Store 路线，VoxSage 旧仓继续 GitHub Releases / Notarized DMG 路线，两个仓不共享二进制
- **为什么**：旧 VoxSage 架构（Python + spawn subprocess + edge-tts）和 App Store Sandbox 有结构性冲突，无法在原仓改造上架。开新仓重写 Swift 子集，原仓保留全功能服务开发者用户
- **被否决的替代方案**：
  - **只走 App Store，砍掉旧仓全功能**：损失现有开发者用户和会议模式核心能力
  - **只走 GitHub DMG，不上架**：放弃普通用户触达
  - **在 VoxSage 仓内开 App Store 分支**：耦合太重，git 历史混乱
- **影响范围**：项目战略；用户群分流；功能取舍；维护成本
- **触发场景**：评估 VoxSage 上架可行性时发现 Sandbox 不兼容

---

### 2026-04-29 — Bundle ID = com.ethanys.voxai（DR-010）

- **决定**：Bundle ID 用 `com.ethanys.voxai`
- **为什么**：Rebecca 的开发者账号是个人账号 ethanys；voxai 是产品名（区分 voxsage）
- **被否决的替代方案**：
  - **com.voxai.app** 等品牌前缀：需要单独申请 voxai.com 域名归属证明，麻烦
  - **com.ethanys.voxsage**：会和旧 VoxSage 仓 Bundle ID 冲突（如果旧仓也上架）
- **影响范围**：Sandbox 容器路径 `~/Library/Containers/com.ethanys.voxai/`；App Store Connect 注册；公证流程
- **触发场景**：Phase 4 准备时讨论命名

---

### 2026-04-29 — 最低系统 = macOS 13.0 Ventura（DR-005）

- **决定**：deployment target = macOS 13.0
- **为什么**：
  - macOS 13+ 原生支持 ASR 自动标点（`addsPunctuation`）
  - macOS 13+ 同时支持 Intel 和 Apple Silicon
  - 已覆盖大部分 Mac 装机量
  - 旧 VoxSage 是 14+，VoxAI 放宽到 13+ 增加用户基数
- **被否决的替代方案**：
  - **macOS 14+**：丢掉 Ventura 用户
  - **macOS 12+**：没有自动标点功能
  - **macOS 26+（Apple SpeechAnalyzer）**：丢掉 Intel + Apple Silicon 大量装机
- **影响范围**：API 兼容性；用户基数；测试矩阵
- **触发场景**：Phase 0 基础设施选型

---

<!-- 历史决议（已收录其他 brain/topics 文件中） -->

历史决议（PLAN §8 中的"决议事项"和 §9 中的 DR）已分类沉淀：
- **DR-001 双轨发布**：本文件已记录
- **DR-002 MCP HTTP/SSE**：本文件已记录
- **DR-003 纯 Swift**：本文件已记录
- **DR-004 v1 不含会议模式**：本文件已记录
- **DR-005 最低系统 13.0**：本文件已记录
- **DR-006 中文本地 TTS 砍**：见 `PROJECT.md` "刻意不做什么"
- **DR-007 名字 = VoxAI**：见 `PROJECT.md` "项目起源"
- **DR-008 Cloud TTS = OpenAI key**：本文件已记录
- **DR-009 API Key Keychain**：本文件已记录
- **DR-010 Bundle ID**：本文件已记录
- **DR-011 隐私政策托管 GitHub Pages**：见 `topics/operations/APP_STORE_CHECKLIST.md`
- **DR-012 主语言英文 + 中文 Localized**：见 `topics/operations/APP_STORE_CHECKLIST.md`
- **DR-013 自身 = MIT**：本文件已记录
- **DR-014 LICENSE_AUDIT 建立**：本文件已记录
- **TD-001 swift-sdk**：本文件已记录
- **TD-002 SwiftNIO**：本文件已记录
- **TD-003 mcp-config 存储**：见 `topics/systems/SANDBOX.md`
- **TD-004 Keychain**：见 DR-009
- **TD-005 Phase 0.3 实测**：本文件已记录
- **TD-006 Phase 0.4 实测**：本文件已记录

---

## ⚠️ 待 Rebecca 拍板的产品决策（不在本文件追加，等她拍板后追加）

- **v1 付费 vs 免费**（建议：免费）
- **GitHub 公开 vs 闭源**（建议：开源继承 MIT）

这两个决定后，本文件追加新条目。

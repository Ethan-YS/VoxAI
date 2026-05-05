# MAP — 项目地图

> **这份文件回答**："项目长什么样？想找某个信息应该去哪？"
>
> **特性**：随项目结构演进。只到**模块级粒度**，不涉及具体函数/文件细节。
> 太细的东西放到 `brain/topics/` 下的专题文档里。
>
> **谁该读**：**每次开新会话的第一件事**。

---

## 一、快速开始

> 给新会话醒来后最快的接入路径。

**当前状态**：Phase 0 完成，Phase 1 待启动。**还没有 Xcode 工程**——下一步是创建。

**项目仓库根**：`/Users/yisang/Developer/VoxAI/`

**Phase 0 验证产物**（仅供参考，不进 build）：`.references/swift-sdk/` 是 `modelcontextprotocol/swift-sdk` 的本地 clone，验证过 `swift build --product mcp-everything-server`。

**Phase 1 启动指令**（待 Rebecca 拍板两个产品决策后才执行）：
```bash
# Phase 1.1 — 创建 Xcode 工程
# 详见 topics/planning/ROADMAP.md Phase 1 任务表
```

**接续验证**：
```bash
git status                      # 应该 clean
ls brain/                       # 应有 5 份核心 + topics/ + handoffs/
grep -rn "⚠️ 待填 ⚠️" brain/   # 应只在 HANDOFF.md / topics 子 README 里出现（其余已填实）
```

## 二、模块清单

> 当前还没动工——这张表会随 Phase 1+ 逐步充实。

| 模块 | 职责 | 状态 | 主要位置 |
|---|---|---|---|
| Xcode 工程骨架 | 项目文件 + entitlements + Info.plist | ✅ Phase 1.1 完成（2026-05-03） | `VoxAI.xcodeproj/`、`VoxAI/VoxAI.entitlements` |
| `TranscriptionService` | ASR（SFSpeechRecognizer + AVAudioEngine + sessionGeneration 防过期回调） | ✅ Phase 1.5 完成（2026-05-03） | `VoxAI/Services/TranscriptionService.swift` |
| `AppSettings` | 配置（UserDefaults） | ✅ Phase 1.4 完成（2026-05-03） | `VoxAI/Models/AppSettings.swift` |
| `DialogView` | 悬浮录音窗 + 歌词渲染 + 自动复制剪贴板（三态 UI） | ✅ Phase 1.6 完成（2026-05-03） | `VoxAI/Views/DialogView.swift` |
| `MenuBarContent` | 菜单栏图标 + 状态行 + Show Dialog + Quit | ✅ Phase 1.7 完成（基础版）；Phase 2.3 加错误状态 badge | `VoxAI/VoxAIApp.swift` 内 |
| `VoxAILogoMark` | logo 渲染（DialogView 标题 + MenuBarExtra label 共用）| ✅ 已实现 | `VoxAI/Views/DialogView.swift` 内 |
| `VoxAIApp` | 主入口 + 3 Scenes + DI | ✅ Phase 1.7 完成（2026-05-03） | `VoxAI/VoxAIApp.swift` |
| `SettingsView`（v1.0 极简版） | 设置面板：autoCopy 开关 + 关于 | ⏳ Phase 2.1 实现 | 当前 `VoxAI/VoxAIApp.swift` 内 `SettingsPlaceholderView` |

### v1.0 不实现（DR-021 / DR-022 切片砍掉，留 v1.1+）

| 模块 | v1.0 状态 | 备注 |
|---|---|---|
| ~~`MCPServer`~~ | ❌ 砍掉 | DR-022；v1.1+ 视用户反馈重启 |
| ~~`TTSEngine`~~ | ❌ 砍掉 | DR-021 |
| ~~`SystemTTSEngine`~~ | ❌ 砍掉 | DR-021 |
| ~~`OpenAITTSClient`~~ | ❌ 砍掉 | DR-021 |
| ~~`KeychainHelper`~~ | ❌ 砍掉 | 没 Cloud TTS 不需要存 API Key |

## 三、模块依赖关系（v1.0 切片版）

```
DialogView ──→ TranscriptionService ──→ AppSettings
          └─→ NSPasteboard.general (录音停止时自动写入，DR-020)

SettingsView ──→ AppSettings (Phase 2.1 实现)

VoxAIApp ──→ 启动时初始化 AppSettings + TranscriptionService(settings:)
         └─→ 3 个 Scene：dialog / Settings / MenuBarExtra
```

无循环依赖，无 TTS / MCP / Cloud / Keychain 模块——v1.0 切片副作用：架构最小化。完整数据流见 `topics/systems/ARCHITECTURE.md`。

## 四、接续层五份核心（brain/ 直接子文件）

> 新会话醒来先读 MAP 和 STATUS，存在 HANDOFF 也读，其余按需。

| 文件 | 回答什么 | 何时读 |
|---|---|---|
| `PROJECT.md` | 初衷、非目标 | 首次接触、范围模糊时 |
| `MAP.md` | 模块结构、文档索引 | 每次开窗口 |
| `STATUS.md` | 当下状态、下一步 | 每次开窗口 |
| `HANDOFF.md` | 上个 Sage 切窗口前的最新交接 | 每次开窗口（如果存在） |
| `DECISIONS.md` | 历史决策 | 追溯某个设计原因时 |

`handoffs/` — 历史 HANDOFF 归档目录（当前为空）。

## 五、专题文档（brain/topics/）

### systems/（系统设计专题）

| 文件 | 是什么 | 何时读 |
|---|---|---|
| `ARCHITECTURE.md` | 整体架构图、模块职责、数据流、跨架构兼容 | 动 MCP / TTS / ASR / Settings 任何模块前 |
| `SANDBOX.md` | App Sandbox entitlements / Info.plist / 调试 | 动 entitlements 之前；改 MCP 网络绑定方案前 |

### operations/（运维/流程类）

| 文件 | 是什么 | 何时读 |
|---|---|---|
| `APP_STORE_CHECKLIST.md` | 上架资产、提审流程、Review Notes 模板 | Phase 4 提审前；任何时候想确认上架还差什么 |
| `RISKS.md` | 工程 / 法务 / UX 风险登记 + 应对 | 每个 Phase 开始前；做大决策前 |
| `LICENSE_AUDIT.md` | 第三方依赖许可证审计 | 引入新依赖前；提审前；担心法务时 |

### planning/（计划/路线图）

| 文件 | 是什么 | 何时读 |
|---|---|---|
| `ROADMAP.md` | v1.0 4 周路线图（Phase 0-4） + v1.1 / v2 展望 | 开始新 Phase 时；估工期时；同步进度时 |

### feedback/（反馈/追踪）

| 文件 | 是什么 | 何时读 |
|---|---|---|
| _空_ | v1 上架前没有用户反馈，本目录留空 | v1 上架后开始填 |

## 六、MAP 自我校准约定

> MAP 最大的敌人是陈旧。这份文件必须有主动维护机制。

**触发更新的场景**：
- 模块新增 / 删除 / 状态变化 → 更新 **二**（模块清单）
- 某个模块有**大的结构变化**（例如重构、引入新子系统）→ 更新 **二、三**
- 有新文档加入 / 删除 / 大改 → 更新 **五**
- 启动方式变化 → 更新 **一**（快速开始）

**MAP 校准扫描**（不自动跑，由 Rebecca 触发或 Sage 主动提议）：
- 扫描 `brain/topics/`：发现文件存在但 MAP 第五节里未登记 → 报告"未登记文件"
- 扫描 MAP 登记项：发现登记了但文件不存在 → 报告"失效条目"
- 发现某文件登记信息和实际内容明显不符 → 报告"条目漂移"
- **触发时机**：
  - Rebecca 说"MAP 校准 / 整理项目记忆"时
  - 完成了某个大的模块改动之后（Sage 主动提议跑校准）

## 七、与项目根其他文件的关系

| 文件 | 角色 | 说明 |
|---|---|---|
| `CLAUDE.md` | 接续协议入口 | Claude Code 自动加载，引导新会话先读 brain/MAP + brain/STATUS。包含项目特有规则（工程师兜底、Rebecca 头大信号等） |
| `PLAN.md` | 短索引 | 历史保留；内容已拆进 brain/，本文件只保留指向 brain/ 的导航 |
| `ROADMAP.md` | 短索引 | 同上，指向 `brain/topics/planning/ROADMAP.md` |
| `.references/swift-sdk/` | Phase 0 验证产物 | 本地 clone 的 MCP SDK，验证用，不进 build；`.gitignore` 已排除 |
| `LICENSE` | ✅ 已建 | MIT 全文（2026-05-02 创建，DR-013/DR-017） |
| `VoxAI.xcodeproj/` | ✅ 已建 | Xcode 项目（2026-05-03 Phase 1.1） |
| `VoxAI/` | ✅ 已建 | App 源码目录（默认 SwiftUI 模板，待 Phase 1.5-1.7 重写） |
| `README.md` | 待建 | Phase 4.6 创建用户文档 |
| `VoxAI.xcodeproj/` | 待建 | Phase 1.1 创建 |
| `VoxAI/` | 待建 | Phase 1.1 创建（App 源码） |
| `VoxAITests/` | 待建 | Phase 3.4 创建 |
| `docs/` | 待建 | Phase 4 创建（隐私政策网页等） |

# STATUS — 当前开发状态

> **这份文件回答**："现在停在哪？下一步做什么？什么卡住了？"
>
> **特性**：**瞬时状态**。**硬上限 ~80 行**。可以放心覆写。
> 有价值的内容沉淀到 `MAP.md`（结构变化）或 `DECISIONS.md`（决策原因）**之后**再覆写。
>
> **谁该读**：每次开新会话。

---

## 现在在做什么

**项目脑搭好 + 产品定位拍板**（2026-05-02）。Phase 0（技术风险验证）已全部完成，**Phase 1 已解锁待启动**——所有产品决策（v1 主推用嘴编程 / 免费 / 开源 MIT / 自动复制剪贴板 / SFSpeechRecognizer 默认服务器 / MCP speak 打断当前）已拍板，记录在 DECISIONS DR-015~020。

## 下一步

**Phase 1.1**：创建 Xcode 项目。具体子任务：

1. Xcode 工程：macOS 13+ deployment target、`ARCHS = $(ARCHS_STANDARD)`、Sandbox 开启
2. **工程创建后立即 archive 一次**验证 universal binary 双 slice（防 Xcode 16.x bug）
3. Bundle ID `com.ethanys.voxai` —— 顺便建议 Rebecca 在 App Store Connect 抢注锁定（避免后续被占要全文档 rename）
4. entitlements: `app-sandbox` + `device.audio-input` + `network.client` + `network.server`
5. Info.plist：`NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription`（中英两版）
6. 项目根加 `LICENSE` 文件（MIT 全文）

完整 Phase 1 任务表见 `topics/planning/ROADMAP.md` Phase 1 节。

## 卡点 / 待确认

- 🟡 Bundle ID `com.ethanys.voxai` 在 App Store Connect 是否被占——Rebecca 方便时可去 ASC 锁定
- 🟡 Phase 0.4 Universal Binary 在 SPM 路径已通过，**Xcode project 路径仍未验证**——Phase 1.1 创建工程后立即 archive 验
- 🟡 Phase 1.5 SystemTTSEngine 完成后，需要 Rebecca 试听 5-10 段典型 AI 输出（中英混杂、技术术语）判断 v1 中文音质是否"够用"——这是非阻塞但影响 v1 体验的产品验收

## 未提交的改动

无。最新 commit 已包含 brain/ 搭建 + 定位调整级联更新。

## 最近一次会话做了什么

2026-05-02 这次会话：
- 搭建 brain/ v2 项目脑（17 个文件，含 LICENSE_AUDIT 法务审计）
- 清理项目根 CLAUDE.md：删除"工程师兜底原则"等规训性表达，只保留技术决策
- **重大产品定位调整**：Rebecca 提出 v1 主卖点是"用嘴编程"——ASR 输入侧聚焦，TTS 是次要功能
- 拍板 6 条决策（DR-015~020）：定位 / 免费 / 开源 / SFSpeechRecognizer 默认服务器 / MCP speak 打断 / 自动复制剪贴板
- 修正隐私政策表述（"不上传任何音频"→"VoxAI 本身不收集；ASR 由 Apple SFSpeechRecognizer 处理可能经 Apple 服务器"）
- 级联更新 PROJECT.md / ARCHITECTURE.md / APP_STORE_CHECKLIST.md / SANDBOX.md / ROADMAP.md / LICENSE_AUDIT.md

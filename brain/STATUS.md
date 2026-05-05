# STATUS — 当前开发状态

> **这份文件回答**："现在停在哪？下一步做什么？什么卡住了？"
>
> **特性**：**瞬时状态**。**硬上限 ~80 行**。可以放心覆写。
>
> **谁该读**：每次开新会话。

---

## 现在在做什么

🔄 **v1.0 切片到 ASR-only MVP**（2026-05-04）。Rebecca 在 Phase 1 跑通后重新评估范围，拍板**砍掉 TTS（AI 朗读）+ MCP server + 语言切换 UI + 自动 paste**——v1.0 只发"用嘴编程"主流程，让用户先用上看反馈。详见 DR-021~024。

切片**意外好处**：entitlements 缩到 2 条（`app-sandbox` + `audio-input`）；无第三方 SPM 依赖；R-001/002/004/005/007/009 风险全部🟢已规避；App Review Notes 极简。工期从 ~4 周压到 ~6-7 天。

下一步：Phase 2 切片版第一个工程任务——**Settings UI + 错误反馈**。

## 下一步

按新切片版 ROADMAP Phase 2-4：

1. **Phase 2.1 SettingsView**（极简版）—— 自动复制 toggle + 关于；替换 VoxAIApp 的 `SettingsPlaceholderView`
2. **Phase 2.2 MenuBarExtra 加 Settings 入口**—— SettingsLink (macOS 14+) / showPreferencesWindow fallback
3. **Phase 2.3 错误反馈**—— 菜单栏图标 badge（warning 变体）+ 浮窗 alert（麦克风拒 / Speech 不可用）
4. **Phase 2.4 Localizable.xcstrings 中英双语**—— 所有 UI 文字 + Info.plist
5. **Phase 2.5 entitlements 已移除 network.***（Sage 已在 brain pivot 时同步处理）
6. **Phase 3 合规 + Intel 测试** → **Phase 4 上架资产 + 提审**

完整任务表见 `topics/planning/ROADMAP.md`（已重写为切片版）。

## 卡点 / 待确认

- ✅ Bundle ID 锁定 / Apple Development 证书已生成 / 浮窗 floating 验证通过 / DR-020 自动复制闭环验证通过
- 🟡 等 Rebecca Codex 给 App Icon 图（Phase 4.1 用）
- 🟡 等 Rebecca 朋友 Intel Mac（Phase 3.3 用）
- ⚠️ **当前 build 状态待验**：linter 改了 VoxAIApp.swift / DialogView.swift 引入新的 `VoxAILogoMark` 组件——需要 Sage build 验证还能编译

## 未提交的改动

- brain/ 大量文档反映 v1.0 切片
- VoxAI.entitlements 移除 network.client + network.server
- DialogView.swift / VoxAIApp.swift 的 linter 改动（VoxAILogoMark 重构）

下一步 commit：`pivot v1.0 to ASR-only MVP (cut TTS + MCP)`

## 最近一次会话做了什么

2026-05-04 这次会话（**v1.0 切片决策 + 实战修复**）：

**核心决策（DR-021~024 拍板）**：
- DR-021 v1.0 砍 TTS（AI 朗读）—— 主推 ASR，TTS 留 v1.1
- DR-022 v1.0 砍 MCP HTTP server —— TTS 砍了 MCP 没意义，连锁简化（无 SwiftNIO / swift-sdk / network.* entitlements）
- DR-023 v1.0 不暴露语言切换 UI —— 主市场中文，默认 zh-CN
- DR-024 v1.0 不做"自动 paste 到下层 App" —— Accessibility 权限摩擦 + 审核风险，留 v1.x 看反馈

**实战修复（Phase 1 上手测试发现）**：
- 多浮窗 bug：`WindowGroup` → `Window`（单例）
- 单段 alpha 太暗：LyricsView opacity 函数加 `total == 1` 特例
- 浮窗 floating 不稳：双层 DispatchQueue.main.async + `.fullScreenAuxiliary` collectionBehavior

**brain 大改**（反映切片）：
- DECISIONS 追加 4 条
- PROJECT.md 重写"刻意不做什么"
- ROADMAP.md 重写 Phase 2-4（4 周 → 6-7 天）
- ARCHITECTURE.md 重写为 v1.0 视角 + 第八节 v1.1+ 预留设计
- SANDBOX.md entitlements 表 + Review Notes 极简版
- VoxAI.entitlements 真删 network.client + network.server
- APP_STORE_CHECKLIST 关键词中文聚焦
- RISKS R-001/002/004/005/007/009 标 🟢 已规避
- LICENSE_AUDIT v1.0 实际无第三方依赖
- MAP.md 模块清单更新 + 加"v1.0 不实现"区块

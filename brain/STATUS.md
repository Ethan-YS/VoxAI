# STATUS — 当前开发状态

> **这份文件回答**："现在停在哪？下一步做什么？什么卡住了？"
>
> **特性**：**瞬时状态**。**硬上限 ~80 行**。可以放心覆写。
>
> **谁该读**：每次开新会话。

---

## 现在在做什么

🎉 **Phase 3 闭环**（2026-05-05）。所有上架前的合规 + 跨架构验证完成：

- PrivacyInfo.xcprivacy 已建（声明 UserDefaults / 不追踪 / 不收集）
- Apple Silicon E2E 8 项 checklist 全过（Rebecca 验）
- **Intel Mac 实测通过**（朋友"弘"验证：双击启动 OK / 中文识别准 / DR-020 复制到微信工作 / 无崩溃）
- README.md 中英双语用户文档
- **Notarize 流程预演成功**——为朋友测试做的 Developer ID 签名 + 公证 + Staple 全程跑通，Phase 4 提审是同一套 toolchain

下一步：Phase 4——上架资产 + 提审。

## 下一步：Phase 4 上架资产 + 提审

| # | 任务 | 谁做 |
|---|---|---|
| 4.1 | App Icon 集成 | ✅ 已完成（Codex 生成，已在 Assets.xcassets，含 1024×1024）|
| 4.2 | App Store 截图（13" + 16" 各 ≥3 张：浮窗待机 / 录音中歌词 / 录音停止 transcript）| Sage 起草 / Rebecca 截图 |
| 4.3 | 应用描述（中文主 + 英文）+ 关键词 + 类别 | Sage 起草 / Rebecca 审 |
| 4.4 | 隐私政策网页（`docs/privacy.html`，托管 GitHub Pages）| Sage |
| 4.5 | App Store Connect 创建 record（账户登录步骤）→ Sage 准备 archive → upload → 提审 | Rebecca 操作 ASC / Sage 准备包 |
| 4.6 | App Review Notes（极简版）| Sage 起草 |

## 旧的下一步

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

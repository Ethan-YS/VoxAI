# STATUS — 当前开发状态

> **这份文件回答**："现在停在哪？下一步做什么？什么卡住了？"
>
> **特性**：**瞬时状态**。**硬上限 ~80 行**。可以放心覆写。
> 有价值的内容沉淀到 `MAP.md`（结构变化）或 `DECISIONS.md`（决策原因）**之后**再覆写。
>
> **谁该读**：每次开新会话。

---

## 现在在做什么

**项目脑刚搭完**（2026-05-02）。Phase 0（技术风险验证）已全部完成，Phase 1（Xcode 工程 + ASR 闭环）待启动。

## 下一步

按优先级：

1. **等 Rebecca 拍板两个产品决策**——这两个不拍板就不动 Phase 1：
   - v1 付费 vs 免费（建议：免费）
   - GitHub 公开 vs 闭源（建议：开源继承 MIT）
2. **Phase 1.1**：创建 Xcode 项目（macOS 13+ deployment target、`ARCHS = $(ARCHS_STANDARD)`、Sandbox 开启）。**工程创建后立即 archive 一次验证双架构产物**（防 Xcode 16.x universal bug）
3. **Phase 1.2**：配 Bundle ID + entitlements + Info.plist 隐私描述
4. **Phase 1.5-1.6**：移植 `TranscriptionService` + `DialogView`（重写，不复制）

详细路线图见 `topics/planning/ROADMAP.md`。

## 卡点 / 待确认

- ⏳ Rebecca 待拍板：v1 付费 vs 免费
- ⏳ Rebecca 待拍板：GitHub 公开 vs 闭源
- 🟡 Phase 0.4 Universal Binary 在 SPM 路径已通过，**Xcode project 路径仍未验证**——Phase 1.1 创建工程后必须立即 archive 验证 `lipo -info` 双 slice

## 未提交的改动

无未提交改动。最新 commit 是 brain/ 搭建（"scaffold brain/ + content migration"）。

## 最近一次会话做了什么

2026-05-02 这次会话：
- Rebecca 触发"了解项目并构建项目脑"
- Sage 评估适用边界，定为 1.4 新项目 kick off + 内容拆解（不是 1.5 迁移）
- `git init` 项目仓库（陷阱 13 工程默认操作）
- 套 brain/ v2 模板骨架
- 把 PLAN.md / ROADMAP.md 内容拆解到 brain/ 各文件：
  - PROJECT.md（项目定位 / 刻意不做什么）
  - DECISIONS.md（13 条决策含 DR-001~014 + TD-001/002/005/006）
  - MAP.md（结构地图）
  - topics/systems/ARCHITECTURE.md + SANDBOX.md
  - topics/planning/ROADMAP.md
  - topics/operations/APP_STORE_CHECKLIST.md + RISKS.md + **LICENSE_AUDIT.md**（Rebecca 主动提的法务审计）
- PLAN.md / ROADMAP.md 改为短索引指向 brain/
- 项目根 CLAUDE.md 头部加 brain/ 接续协议引导

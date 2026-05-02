# PLAN.md — 已迁移到 brain/

> 这份文件原本是项目的产品规格 SSOT（v1.0 设计稿，2026-04-29），已于 2026-05-02 拆解到 `brain/` 项目脑结构中。
>
> **不要往这里加新内容**——按下面索引去对应的 brain/ 文件写。

---

## 内容去哪了

| 原 PLAN 章节 | 现在去哪找 |
|---|---|
| §1 背景与定位 | [brain/PROJECT.md](brain/PROJECT.md) |
| §2 v1.0 功能范围 | [brain/PROJECT.md](brain/PROJECT.md)（"做什么 / 不做什么"）+ [brain/topics/planning/ROADMAP.md](brain/topics/planning/ROADMAP.md) |
| §3 技术架构 | [brain/topics/systems/ARCHITECTURE.md](brain/topics/systems/ARCHITECTURE.md) |
| §4 项目结构 | [brain/topics/systems/ARCHITECTURE.md](brain/topics/systems/ARCHITECTURE.md) §七 |
| §5 沙盒 Entitlements | [brain/topics/systems/SANDBOX.md](brain/topics/systems/SANDBOX.md) |
| §6 开发路线图 | [brain/topics/planning/ROADMAP.md](brain/topics/planning/ROADMAP.md) |
| §7 上架清单 | [brain/topics/operations/APP_STORE_CHECKLIST.md](brain/topics/operations/APP_STORE_CHECKLIST.md) |
| §8 决议事项 + §9 决策记录（DR-001~009）| [brain/DECISIONS.md](brain/DECISIONS.md) |
| §10 风险登记 | [brain/topics/operations/RISKS.md](brain/topics/operations/RISKS.md) |
| **新增**：第三方依赖许可证审计 | [brain/topics/operations/LICENSE_AUDIT.md](brain/topics/operations/LICENSE_AUDIT.md) |

---

## 想从头了解项目？

按这个顺序读：

1. [CLAUDE.md](CLAUDE.md) — 项目入口和接续协议
2. [brain/MAP.md](brain/MAP.md) — 项目地图，文档索引
3. [brain/STATUS.md](brain/STATUS.md) — 当前停在哪
4. [brain/PROJECT.md](brain/PROJECT.md) — 项目定位和"刻意不做什么"

---

## 历史快照

如果你要看 2026-05-02 之前的 PLAN.md 完整版，看 git history：

```bash
git log --oneline PLAN.md
git show 85b7123:PLAN.md   # 拆解前的最后一个版本
```

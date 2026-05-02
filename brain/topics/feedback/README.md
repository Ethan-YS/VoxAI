# feedback/

> **这里放什么**：用户反馈、bug 追踪、triage 流程。
>
> **判断标准**：问自己——"这个文档回答的问题是**用户 / 现实告诉我们什么**吗？"

---

## 典型内容

三件套最常见：

| 文件 | 用途 |
|---|---|
| `FEEDBACK_INBOX.md` | **原始**反馈收件箱，按时间倒序，保留用户原话 |
| `BUG_TRACKER.md` | 从 inbox 筛出的 **actionable bug**，按 ID 跟踪状态 |
| `FEEDBACK_TEMPLATES.md` | 给用户的反馈填写模板 + 回复模板 + triage 流程 + 严重度 rubric |

## 不属于这里的

- ❌ 系统设计 → `systems/`（bug 的**根因分析**可能影响 systems 文档，但 bug 条目本身属于这里）
- ❌ 发版流程 → `operations/`
- ❌ 功能规划 → `planning/`
- ❌ bug 修好后的**决策原因** → `brain/DECISIONS.md`（如果修复涉及不可逆设计变化）

## 三份文件的分工原则

- **INBOX = 原始**：**保留用户原话**，不做加工、不合并、不删减。它是"数据来源"，不是"todo list"。
- **TRACKER = actionable**：从 inbox 里筛出"我们要修"的条目，分配 BUG-XXX ID，跟踪状态流转。
- **TEMPLATES = 流程**：给用户的模板 + 给自己的流程 + rubric。

**反向链接规则**：每个 bug 有独立 ID（BUG-XXX）。在 INBOX 条目里提到某个 bug 时引用 ID（"已归入 BUG-008"），在 TRACKER 条目里也可以引用原始反馈的日期来源。互相引用，方便追溯"这个 bug 是哪个用户先报的"。

## 隐私规则（必读）

FEEDBACK_INBOX 会收到真实用户的信息。**不进 git**的：
- ❌ 真实姓名 / 邮箱 / 电话 / 实名社交账号
- ❌ 激活码 / 付款凭证 / 订单号
- ❌ 含用户隐私的截图

**可以进 git 的**：
- ✅ 用户昵称（`@ethan` / `@晴月`）
- ✅ 公开的产品反馈内容
- ✅ 系统信息（OS 版本、App 版本）

## 迁移阈值

bug 数量 **>50 再考虑迁移到 GitHub Issues**。在那之前 markdown-based 足够轻量，也避免把用户反馈里的敏感内容推到公开 repo。

## 状态流转

建议的 bug 状态：
```
Inbox → Triaging → In Progress → Resolved → Released
                                    │
                                    └→ Won't Fix / Deferred
```

每次发版前把"In Progress"清零或标注"延到下个版本"。发版后把"Resolved"迁到"Released"。

# STATUS — 当前开发状态

> **这份文件回答**："现在停在哪？下一步做什么？什么卡住了？"
>
> **特性**：**瞬时状态**。**硬上限 ~80 行**。可以放心覆写。
>
> **谁该读**：每次开新会话。

---

## 现在在做什么

**v1.0 已上架 Mac App Store** 🎉（2026-05-06）→ **进入 v1.x 迭代规划**（2026-06-24）

- **产品页**：https://apps.apple.com/cn/app/voxai-用嘴编程/id6766570591
- **ASC App ID**：`6766570591`
- **Bundle ID**：`com.ethanys.voxai`
- **状态**：可供分发 / Ready for Distribution（已通过审核 + 已在 App Store 索引到）
- **2026-06-24**：Rebecca 启动 v1.x 增功能。Sage 已通读 6 个 Swift 源文件 + 决策/架构/sandbox/风险/路线图，掌握全貌，待定功能范围

## 下一步

**定 v1.x 功能范围**（Rebecca 主导）。候选功能池见 [`DECISIONS.md`](DECISIONS.md) DR-021~024（v1.0 砍掉的 TTS / MCP / 语言切换 / 自动 paste，每条都有"为什么砍 + v1.1 重启参考"）+ [`ROADMAP.md`](topics/planning/ROADMAP.md)（原定 v1.1 = 会议模式）。AppSettings 已为 TTS / 语言 / Cloud 字段留底，数据层重启成本低。选定方向后走 brainstorm → 排期 → 实现。

**§14 GitHub 收尾**（剩两个可选项，等 Rebecca 意愿）：
- ✅ 14.1 Release / 14.2 repo homepage / 14.5 README badge — 已完成 + push
- ⏳ 14.3 Social preview image / 14.4 GitHub Discussions（不推荐开）

## 卡点 / 待确认

无。项目进入"等用户反馈 / 看下载量"的产品阶段。

## 未提交的改动

无。上架收尾那一波已全部 commit + push（最新 `c69fe98` Phase 4.6 + tag `v1.0`，本地 == origin）。本次 STATUS 校准 commit 即将 push。

## 最近一次会话做了什么

2026-05-06 **审核通过 + 上架 + GitHub 收尾**：

- Apple 在提交后**当天**就给了 "可供分发" 状态（比预期 1-3 天快得多）
- Rebecca 直接搜到 VoxAI 在 App Store 出现 → 上架确认
- Sage 接管 §14 GitHub 收尾：
  - **README** 头部加 3 个 badge + 中英文安装段填上真实 App Store URL + 隐私政策从相对路径换 live URL + "提审中" → "已上架"
  - **GitHub Release v1.0** source-only 创建（不挂 binary，分发走 Mac App Store）
  - **Repo homepage** 从 `privacy.html` 换成 `apps.apple.com/app/id6766570591`
- brain 同步：STATUS 覆写 / ASC drafts §13.5 加上架时间戳

**Sage 守住的边界**：联系信息 PII / 出口合规法律声明 / 提交以供审核（不可逆）—— 全程没擅自做。这次的成功上架是契约边界里 Sage 该做的都做了。

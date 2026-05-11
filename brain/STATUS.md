# STATUS — 当前开发状态

> **这份文件回答**："现在停在哪？下一步做什么？什么卡住了？"
>
> **特性**：**瞬时状态**。**硬上限 ~80 行**。可以放心覆写。
>
> **谁该读**：每次开新会话。

---

## 现在在做什么

**v1.0 已上架 Mac App Store** 🎉（2026-05-06）

- **产品页**：https://apps.apple.com/cn/app/voxai-用嘴编程/id6766570591
- **ASC App ID**：`6766570591`
- **Bundle ID**：`com.ethanys.voxai`
- **状态**：可供分发 / Ready for Distribution（已通过审核 + 已在 App Store 索引到）

## 下一步

跑完 [`ASC_SUBMISSION_DRAFTS.md`](topics/operations/ASC_SUBMISSION_DRAFTS.md) §14 GitHub 收尾的剩余事项：

- ✅ 14.1 GitHub Release v1.0 — Sage 创建
- ✅ 14.2 改 `Ethan-YS/VoxAI` repo homepage URL 指向 ASC — Sage 改
- ✅ 14.5 README 加 Mac App Store badge — Sage 改
- ⏳ 14.3 Social preview image（可选） — Rebecca 看意愿
- ⏳ 14.4 GitHub Discussions（v1.0 不推荐开）— Rebecca 看意愿
- ⏳ push 那一波 ahead commits 到 origin/main — 等所有改动 commit 完后 Sage 一次性 push

**v1.x 范围**：见 [`topics/planning/ROADMAP.md`](topics/planning/ROADMAP.md)。等真实用户反馈再启动。

## 卡点 / 待确认

无。项目进入"等用户反馈 / 看下载量"的产品阶段。

## 未提交的改动

`brain/STATUS.md` / `brain/HANDOFF.md`（已归档旧版到 handoffs/） / `brain/topics/operations/ASC_SUBMISSION_DRAFTS.md` / `README.md`（加 App Store badge + 替换"即将上线"占位 + 隐私政策 live URL）。

ahead origin/main 5 commits + 这次改动 → 准备打包成 §14 GitHub 收尾的一组 commit 一波 push。

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

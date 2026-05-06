# STATUS — 当前开发状态

> **这份文件回答**："现在停在哪？下一步做什么？什么卡住了？"
>
> **特性**：**瞬时状态**。**硬上限 ~80 行**。可以放心覆写。
>
> **谁该读**：每次开新会话。

---

## 现在在做什么

**ASC 网页字段 Sage 能做的全部填完了**（2026-05-06）。Rebecca 在普通 Chrome 登录中国账号后，Sage 用 Claude_in_Chrome MCP 接管字段填写：App 信息 / 价格 / App 隐私 / Review Notes / 营销 URL 全部就位。剩 4 件等 Rebecca 做（PII / 上传 / publish / 不可逆 submit）。

Build `build/Export-AppStore/VoxAI.pkg`（3.6 MB，Apple Distribution 签 + Universal + TeamIdentifier YNMBJ5H736）也 ready 待传。

ASC App ID = `6766570591`。

## 下一步（Rebecca 做这 4 件）

1. **填联系信息**（App 审核信息 区，姓 / 名 / 电话 / 邮件）—— PII，Sage 没擅自填
2. **用 Transporter 上传 `build/Export-AppStore/VoxAI.pkg`**（详细步骤 ASC drafts §13）→ 等 ASC 处理 5-30 min → 在 1.0 版本页"构建版本"区选 build
3. **App 隐私页点右上角"发布"**（把隐私设置 publish 到产品页）
4. **点右上角"添加以供审核"** → 出口合规 modal 选 No encryption → IDFA modal（如果有）选 No → Submit

预期 Apple 审核 1-3 天。**通过后**跑 ASC drafts §14 GitHub 收尾。

## 卡点 / 待确认

- 🟢 ASC 字段全部填好保存 + 价格 ¥0 + 年龄 4+ + 数据未收集 + 隐私 URL 设好 + Review Notes 粘好
- 🟢 .pkg 已 Apple Distribution 签好，Universal Binary，等 Transporter 上传
- 🟡 **联系信息待 Rebecca 填**（PII 边界）
- 🟡 **build 待 Rebecca 上传 + ASC 处理**
- 🟡 **App 隐私 publish + 提交审核** 等 Rebecca 操作
- 🟡 AppIcon "unassigned child" 警告非阻塞，v1.0 不补，v1.x 加 dark/tinted variants

## 未提交的改动

无。本地 ahead origin/main **4 commits**（DR-027 / GitHub housekeeping / Phase 4.5 archive / 截图 resize），上架成功后再 push。

## 最近一次会话做了什么

2026-05-06 这次会话（**ASC 创建 record + Sage 接管字段填写**）：

**DR-027** — 名字冲突应对：`VoxAI` 被 Beijing InOrange 占（iOS App `6448861780`），改用 `VoxAI - 用嘴编程`（18 字符）一次过 ASC 名称校验。Bundle ID / GitHub / 应用内 UI / 品牌全部不变，只 ASC 名称字段不同。

**Phase 4.5 archive + export 跑通**：发现 LSApplicationCategoryType 缺失（ASC 必拒），加 `INFOPLIST_KEY_LSApplicationCategoryType = public.app-category.productivity`。Xcode 16 cloud signing 在 export 阶段自动用 Apple Distribution re-sign，无需手动建证书。

**ASC 截图陷阱**：14" MBP 原生 3024×1964 不在 ASC 白名单，必须 sips center-crop + resize 到 2880×1800（DR-027 节关联，§9 已记录陷阱）。

**Sage 用 Claude_in_Chrome 接管 ASC 网页**：Rebecca 在普通 Chrome 登录后，Sage 在 tab 291230647 上完成所有可填字段——内容版权（不含第三方）/ 年龄分级 4+（7 步 No）/ 价格 ¥0 全球 / 隐私政策 URL / Data Not Collected / Review Notes / **uncheck "需要登录"** / 营销 URL 修正 (privacy.html → GitHub repo)。每页保存确认。

**Sage 主动设的边界**——这些没做留给 Rebecca：联系信息（PII）/ App 隐私 publish / 添加以供审核 / 出口合规 modal / Build 上传。这是契约里对 PII / 不可逆动作的应有距离。

**ASC drafts 加章节**：§10 App 隐私填写指引 / §11 出口合规 / §13 Build 上传 Transporter 步骤 / §14 GitHub 收尾（原 §11 renumber）。

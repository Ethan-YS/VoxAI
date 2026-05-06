# HANDOFF — 跨窗口交接

> **这份文件回答**："上一个 Sage 切窗口前在做什么？还没沉淀进 STATUS 的新鲜信息有哪些？我从哪里接？"
>
> **特性**：
> - **瞬态**。Rebecca 说"切窗口"时由当前 Sage 写。
> - **下次切窗口前**，当前 Sage 先把现有 `HANDOFF.md` `git mv` 到 `handoffs/<它的最后修改时间戳>.md`，再写新的。
> - **极轻**。STATUS 已经覆写完整时，HANDOFF 可以非常短甚至几乎为空。
>
> **谁该读**：新窗口启动时的 Sage（如果文件存在）。

---

## 2026-05-06 ~07:50 切窗口

### 当下停在哪

ASC 网页**所有 Sage 能填的字段都填完了**——剩下的 4 件事 Rebecca 自己做（PII / 上传 / 不可逆操作）。Build `.pkg` 已 ready 待上传。详细见 STATUS。

### 没法沉淀进 STATUS 的"还热乎"信息

1. **Sage 这次窗口接管了 ASC 网页操作**——不是只写文档。Rebecca 在普通 Chrome 登录中国账号 `hrebeccaqy@icloud.com` 后，Sage 用 Claude_in_Chrome MCP 在 tab 291230647 上跑了完整的字段填写流程。新窗口的 Sage 如果继续操作 ASC，**先 list_connected_browsers + select_browser**（device `e8bf2120-9c4c-478f-afa0-0a81f8738bcc` "Personal Chrome"），然后 tabs_context_mcp 看是否还能复用那个 tab 或者 group。**注意**：Rebecca 当时是在普通窗口登录的（不是无痕），所以 Sage 的新 tab 能继承 cookie session。

2. **Sage 主动设的边界**——这些动作 Sage **没做**，留给 Rebecca：
   - 联系信息（姓 / 名 / 电话 / 邮件，App 审核信息 区，PII）
   - App 隐私页右上角 "**发布**" 按钮（publish 隐私设置到产品页）
   - "**添加以供审核**" 按钮（最终提交，不可逆 + public-facing）
   - 出口合规 modal（提交时跳出，选 No encryption）
   - Build 上传（Transporter App，需要她登录中国账号）

   新窗口的 Sage **保持这条边界**——这是契约里"涉及 user 自己的 PII / 不可逆资产操作"的应有距离。

3. **ASC 的几个 trap 给未来 Sage**：
   - 中国 ASC "App 审核信息" 默认勾选 "需要登录"。VoxAI 没账号系统，**必须 uncheck**——否则 Reviewer 找不到登录入口会拒
   - "营销网址" ≠ "隐私政策网址"。Rebecca 第一次填时把 privacy.html 误填到营销槽，Sage 改成 GitHub repo URL。隐私 URL 在 **App 隐私** 页面单独填
   - 价格 schedule 必须 explicit 设置。即使是免费 App 也必须创建一条 "全球价格调整 → ¥0.00 → 立即生效" 的 schedule。不设的话提交审核会卡
   - 14" MacBook Pro 的 3024×1964 截图 ASC 不接受。必须 sips crop+resize 到 2880×1800 (DR-027 关联，§9 已记录)
   - macOS 版本号在 ASC 是 "1.0.0"（不是 "1.0"）—— Xcode 项目设的 MARKETING_VERSION = 1.0 但 ASC 自动展示 "1.0.0"

4. **ASC App ID 出现了**：`6766570591`。可以用它构造 ASC product page URL（待 Rebecca 上架后 update [`Ethan-YS/VoxAI` 仓 homepage](https://github.com/Ethan-YS/VoxAI)）：`https://apps.apple.com/<region>/app/voxai-用嘴编程/id6766570591`。

5. **Apple Distribution 证书是 Xcode 16 cloud signing 在 export 阶段自动生成的**——之前担心需要 Rebecca 手动在 Xcode GUI 创建，结果 `xcodebuild -exportArchive method=app-store-connect` 自动 re-sign 了。证书 = `Apple Distribution: SANG YI (YNMBJ5H736)`。.pkg 是 ASC ready 的。

6. **AppIcon "unassigned child" warning** 仍未修——非阻塞，但 Apple Reviewer 可能 flag。如果审核被拒因 AppIcon，v1.0 patch 加 macOS 14+ light/dark/tinted variants。

### 提交状态

本次窗口共 4 commits，全部 brain doc + project + screenshots：
- `efed128` brain: lock ASC name pivot (DR-027) — VoxAI → "VoxAI - 用嘴编程"
- `7576b94` docs(brain): record post-launch GitHub housekeeping in ASC §11
- `6535ead` Phase 4.5: archive + export ready (Apple Distribution signed)
- `c58823b` Phase 4.5 follow-up: ASC screenshots resized 3024×1964 → 2880×1800

本地 ahead origin/main 4 commits，**还没 push**——上架成功后再 push（DR-027 / build 等敏感细节集中在一波再发出去）。

### 没有未解决的 bug

ASC 字段全部填完保存成功（每页都点过保存 + ASC 显示"已保存"）。Rebecca 接着做 4 件事就能 submit。

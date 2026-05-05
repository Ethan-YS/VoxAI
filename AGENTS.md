# VoxAI — App Store 上架版（项目级入口）

VoxSage 的姊妹仓库，专门为 **Mac App Store 上架** 而新建。双轨发布：旧仓 VoxSage 走 GitHub Releases / Notarized DMG；本仓走 App Store。

---

## 🧠 接续协议

这个项目用 `project_brain` v2 方法论组织。新会话按顺序读：

1. **`brain/MAP.md`** — 项目地图，知道当前有哪些模块、文档分布
2. **`brain/STATUS.md`** — 当下停在哪、下一步、卡点
3. **`brain/HANDOFF.md`**（如果存在）— 上一个会话切窗口前留下的最新交接
4. 然后按需读：
   - 范围模糊 / 首次接触 → `brain/PROJECT.md`
   - 想知道某个决策为什么 → `brain/DECISIONS.md`
   - 动具体模块前 → `brain/topics/systems/*`
   - 提审 / 法务相关 → `brain/topics/operations/*`
   - 看路线图 → `brain/topics/planning/ROADMAP.md`

读完 MAP + STATUS 后给一句简短报告，比如："这是 VoxAI，当前停在 [STATUS 第一节]，下一步 [STATUS 第二节]"——让 Rebecca 确认项目状态被正确接住，再开始动手。

项目根的 `PLAN.md` / `ROADMAP.md` 是短索引，内容已拆进 `brain/`。新内容写到对应的 `brain/topics/` 文件。

---

## 关键技术约束

- **纯 Swift，零 Python 依赖** — App Sandbox 不允许 spawn 用户路径下的进程
- **macOS 13.0+（Ventura）** — 同时支持 Intel + Apple Silicon
- **Universal Binary**（arm64 + x86_64，Xcode 默认配置即可）
- **App Sandbox 全程开启**
- **v1 不做会议模式** — 留给 v1.1
- **TTS 云端走"OpenAI 兼容协议 + 用户自带 key"** — 不打包 edge-tts（同时踩 App Store Guideline 2.5.1 公开 API + 5.2.2 第三方授权两条硬条款）

---

## 路径

| 路径 | 用途 |
|---|---|
| `/Users/yisang/Developer/VoxAI/` | 本仓库（App Store 上架版，纯 Swift） |
| `/Users/yisang/Program file/🔬 AI 探索/VoxSage/` | 旧仓库（双轨发布的完整版，参考用） |

---

## 当前进度

见 [`brain/STATUS.md`](brain/STATUS.md)（瞬时状态，权威来源）。决策追溯见 [`brain/DECISIONS.md`](brain/DECISIONS.md)。

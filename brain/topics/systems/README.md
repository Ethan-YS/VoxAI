# systems/

> **这里放什么**：系统设计、架构、技术选型相关文档。
>
> **判断标准**：问自己——"这个文档回答的问题是**这个东西是怎么设计的**吗？"

---

## 典型内容

- **架构文档**：记忆系统架构、数据流设计、模块边界
- **技术选型**：为什么选 Qdrant 而不是 Pinecone、为什么选 Electron
- **协议 / 接口设计**：API 契约、跨模块通信协议
- **领域模型**：情绪系统、关系系统、权限模型
- **红线 / 约束**：系统层面的不可违反规则（如隔离边界）

## 不属于这里的

- ❌ 发版步骤 → `operations/`
- ❌ 路线图 / 将来要做什么 → `planning/`
- ❌ 用户反馈 / bug → `feedback/`
- ❌ 当前会话状态 → `brain/STATUS.md`
- ❌ 历史决策记录 → `brain/DECISIONS.md`（DECISIONS 记录**为什么**，systems/ 记录**是什么 + 怎么运作**）

## 文件命名建议

- 大写字母 + 下划线，如 `MEMORY_ARCHITECTURE.md` / `AI_PROVIDERS.md`
- 名字要能一眼看出"是什么系统 / 什么主题"
- 避免项目名前缀（`SAGE_MEMORY.md` → `MEMORY_ARCHITECTURE.md`）

## 维护纪律

- 每份顶部写"这份文件回答：xxx"说明边界
- 修改重大设计时，同步在 `brain/DECISIONS.md` 追加决策条目

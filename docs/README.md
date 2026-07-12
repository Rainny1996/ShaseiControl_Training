# 📚 ControlTraining 文档中心

> 项目：男性控制训练 App（iOS · SwiftUI · 纯本地离线）
> 整理日期：2026-07-11

---

## 文档结构速查

```
docs/
├── README.md              ← 你在这里
├── BUG-TASK-ASSIGNMENT.md    — 【✅ 已完结】Bug 修复任务分配（v0.0.2 · 4/4 已修复，详见 v5.9 复查报告）
│
├── specs/                 ← 📋 项目核心规格文档
│   ├── requirements.md    — 需求文档（v2.0，含验收标准编号 AC-x.y）
│   ├── design.md          — 架构设计文档（v2.0 + v2.1 训练计划增强设计 §5 已完整合并需求 10/11/12，自包含，匹配需求）
│   └── tasks.md           — 实现任务拆分（v2.0，绑定 AC 编号）
│
├── ai-workflow/           ← 🔧 AI 协作工作流（活跃草案）
│   └── plan-v2.1/
│       └── open-questions.md   — 【✅ 已完结·设计冻结】需求 10/11/12 决策记录（Q1–Q6 已确认）
│                                （其余 design-需求10/11/12 + 01~04 分工 Prompt 已归档 → docs/archive/plan-v2.1/）
│
├── archive/               ← 📦 历史里程碑归档（含 MANIFEST）
│   └── plan-v2.1/         — v2.1 训练计划增强设计草案归档（含 MANIFEST.md，三份设计已完整并入 specs/design.md §5，此处为历史快照）
│
└── reviews/               ← 🔍 代码审查报告
    ├── v5.9-BUG修复复查报告.md    — 【最新】用户反馈 4 项 Bug 修复源码复查：✅ 4/4 通过（#1 评估跳转 / #2 智能调整 / #3 挤压图标 / #4 密码·FaceID 冷启动），含编译验证
    ├── v4.0-测试覆盖审查报告.md   — 测试体系审查（已补测试 target/集成/UI）
    └── archive/           ← 历史审查报告（不再维护）
        ├── v3.0-代码审查报告.md         — 已失效（未经验证，被 v5.1 推翻）
        ├── v5.0-代码审查报告.md         — 全量代码审查，5 项 P0（被 v5.1 替代）
        ├── v5.1-代码复查报告.md         — 修复复核，BUG-CT-11 退化（被 v5.2 替代）
        ├── v5.2-代码复查报告.md         — 已失效（静态误判「✅ 通过」，被 v5.3 推翻）
        ├── v5.3-代码审查报告.md         — 构建实证：34 编译错误（v5.4 复审基线）
        ├── v5.4-代码复查报告.md         — v5.3 修复复审：2 错误残留（v5.5 复审基线）
        ├── v5.5-代码复查报告.md         — 本地复审「✅ 通过」但审查版本 ≠ CI 构建版本（虚假通过，被 v5.6 推翻）
    ├── v5.6-代码复查报告.md         — 含虚假结论：误判「Group A 本地已修」，被 v5.7 实测推翻
        ├── v1.0-代码审查报告.md         — 初版（6 缺陷 + 8 建议）
        ├── v2.0-代码审查报告.md         — 修复验证（引入 1 回归）
        ├── IPA构建v1.0-代码审查报告.md  — momc 崩溃分析
        └── IPA构建v2.0-代码审查报告.md  — Core Data codegen 修复确认
```

---

## 给不同角色的阅读指引

| 角色 | 推荐阅读顺序 |
|------|-------------|
| **新加入的开发者** | README（根目录）→ `specs/requirements.md` → `specs/design.md` |
| **架构设计 AI** | `specs/requirements.md` → `specs/design.md` |
| **编码实现 AI** | `specs/tasks.md` → `specs/requirements.md` → 源码 `ControlTraining/` |
| **代码审查 AI** | `reviews/v5.9-BUG修复复查报告.md` → 以 CI 实编译日志为真相，逐条读盘核实已修/残留 |
| **运维/CI AI** | `specs/requirements.md` §4（技术约束）→ `reviews/archive/IPA构建v2.0.md` → `.github/workflows/build-ipa.yml` |
| **产品经理** | `specs/requirements.md` → UI 预览 `preview/versions/v0.0.2.html` |

---

## 文档版本对齐

| 文档 | 版本 | 状态 |
|------|------|------|
| requirements.md | v2.0 | 当前活跃 |
| design.md | v2.0 + v2.1 | v2.0 对齐需求；v2.1 训练计划增强设计（需求 10/11/12）已**完整合并**至 §5（含 AC 映射/流程图/数据模型/契约/决策记录），原草案归档至 docs/archive/plan-v2.1/ 作为快照 |
| tasks.md | v2.0 | 对齐需求 v2.0 |
| 审查报告 | v5.9 | ✅ 4/4 用户反馈 Bug 修复通过（含编译验证），详见 v5.9-BUG修复复查报告.md |
| UI 预览 | v0.0.2 | preview/versions/v0.0.2.html（液态玻璃风格 + 4 项 Bug 修复面板） |

---

> 💡 如需添加新文档，请在此 README 中更新索引。

# 归档清单 · v1.0.0-cleanup

> **归档日期**：2026-07-11
> **操作类型**：文件整理与版本归档
> **操作人**：AI Assistant（CodeBuddy）

---

## 变更摘要

项目根目录文件杂乱，本次整理将所有文档统一归位到 `docs/` 目录，清理构建产物，建立清晰的目录结构。

---

## 变更清单

### 删除（4 项）

| 文件 | 原因 |
|------|------|
| `ControlTraining.ipa` | CI 构建产物，不应留在源码仓库（`.gitignore` 已有规则） |
| `训练计划`（无扩展名） | 已重命名为 `训练计划.md` |
| `.joycode/rules/`（空目录） | 空目录，从未使用 |
| `.joycode/specs/ejaculation-control-training-ios/` | 内容已迁移到 `docs/specs/` |

### 移动（8 项）

| 源位置 | 目标位置 |
|--------|----------|
| `docs/代码审查报告.md` | `docs/reviews/archive/v1.0-代码审查报告.md` |
| `docs/代码审查报告-v2.0.md` | `docs/reviews/archive/v2.0-代码审查报告.md` |
| `docs/代码审查报告-v3.0.md` | `docs/reviews/v3.0-代码审查报告.md`（保留为最新） |
| `docs/代码审查报告-IPA构建v1.0.md` | `docs/reviews/archive/IPA构建v1.0-代码审查报告.md` |
| `docs/代码审查报告-IPA构建v2.0.md` | `docs/reviews/archive/IPA构建v2.0-代码审查报告.md` |
| `.joycode/specs/ejaculation-control-training-ios/requirements.md` | `docs/specs/requirements.md` |
| `.joycode/specs/ejaculation-control-training-ios/design.md` | `docs/specs/design.md` |
| `.joycode/specs/ejaculation-control-training-ios/tasks.md` | `docs/specs/tasks.md` |

### 新增（4 项）

| 文件 | 说明 |
|------|------|
| `README.md`（根目录） | 项目概述、目录结构、快速开始 |
| `docs/README.md` | 文档中心索引、不同角色阅读指引 |
| `训练计划.md` | 原 `训练计划` 补全 `.md` 扩展名 |
| `archive/v1.0.0-cleanup/MANIFEST.md` | 本文档 |

---

## 整理后的文档结构

```
docs/
├── README.md                   ← 文档中心索引
├── specs/                      ← 核心规格文档（从 .joycode 迁移）
│   ├── requirements.md
│   ├── design.md
│   └── tasks.md
└── reviews/                    ← 代码审查报告
    ├── v3.0-代码审查报告.md     ← 最新（通过）
    └── archive/                ← 历史版本
        ├── v1.0-代码审查报告.md
        ├── v2.0-代码审查报告.md
        ├── IPA构建v1.0-代码审查报告.md
        └── IPA构建v2.0-代码审查报告.md
```

---

## 未变动的目录

| 目录 | 说明 |
|------|------|
| `ControlTraining/` | 主应用源码（未动） |
| `ControlTrainingTests/` | 测试（未动） |
| `.github/` | CI 工作流（未动） |
| `.joycode/memory/` | AI 助理内部数据（未动） |
| `.joycode/specs/results.json` | AI 任务状态追踪（未动） |
| `preview/` | UI 预览（未动） |
| `project.yml` | XcodeGen 配置（未动） |

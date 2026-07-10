# 🤖 AI 协作文档归档指南

> 本文档为 AI 助手提供项目文档的权威路径与上下文。请将其作为 prompt 的一部分发送给其他 AI。

---

## 1. 项目根目录

```
d:\Project\男性控制训练\男性控制训练\
```

**入口文档**: `README.md` — 项目概述、技术栈、目录结构速查

**构建配置**: `project.yml` — XcodeGen 配置（iOS 17.0, Swift 5.9, 纯本地离线）

---

## 2. 核心文档路径（AI 必读）

### 需求文档（Requirements）
```
📄 docs/specs/requirements.md
```
- 版本: v2.0
- 含完整验收标准编号（AC-x.y），供架构/编码/测试反向追溯
- 目标用户: 35-55 岁男性（设计约束: 大字、高对比、≤2次点击、通俗文案）

### 架构设计（Design）
```
📄 docs/specs/design.md
```
- 版本: v2.0
- 架构: MVVM + Clean Architecture
- 模块划分: Home / Training / Coach / Plan / CheckIn / Review / Analysis / Settings
- 数据流: View → ViewModel → Service → Repository → Core Data
- 安全: AES-256-GCM + Keychain + Face ID / Touch ID

### 任务拆分（Tasks）
```
📄 docs/specs/tasks.md
```
- 版本: v2.0
- 每条任务绑定 AC 编号
- 标记 `[x]` 已完成、`[ ]` 待办

---

## 3. 代码审查报告路径

```
📄 docs/reviews/v4.0-测试覆盖审查报告.md       ← 测试体系审查（已补测试 target/集成/UI）
📄 docs/reviews/v5.2-代码复查报告.md          ← 最新代码复查，✅ 通过（P0/P1 全修复，主 Target 编译阻断消除）
📁 docs/reviews/archive/                       ← 历史版本（已归档，仅供参考）
    ├── v3.0-代码审查报告.md   （已失效：未经验证，被 v5.1 推翻）
    ├── v5.0-代码审查报告.md   （全量代码审查，5 项 P0 编译阻断，被 v5.1 复核替代）
    ├── v5.1-代码复查报告.md   （修复复核，BUG-CT-11 退化；被 v5.2 复核替代）
    ├── v1.0-代码审查报告.md
    ├── v2.0-代码审查报告.md
    ├── IPA构建v1.0-代码审查报告.md
    └── IPA构建v2.0-代码审查报告.md
```

审查历史:
```
v1.0 → 6 缺陷 + 8 建议
v2.0 → 6 缺陷关闭 ⚠️ 引入 1 回归
v3.0 → 全部关闭 ✅（结论未经验证，已被 v5.1 推翻，已归档）
v4.0 → 测试体系审查：补测试 target / 5 集成测试 / 2 UI 冒烟测试，CI 运行 test.yml
v5.0 → 全量代码审查：❌ 不通过，5 项 P0 编译阻断（已归档，被 v5.1 复核替代）
v5.1 → 修复复核：❌ 仍不通过，BUG-CT-11 退化→1 项 P0 仍阻断（已归档，被 v5.2 复核替代）
v5.2 → 修复复核：✅ 通过，P0/P1 全修复 + ARC-03/04/07 修复，主 Target 编译阻断消除（剩 ARC-01/05/06 三项 P2 非阻断）
```

---

## 4. 源码路径

### 主应用
```
📁 ControlTraining/
  ├── App/                    — AppDelegate, ContentView, Info.plist
  ├── Core/Data/              — CoreDataStack, Models, Repositories
  ├── Core/Services/          — Audio, Crypto, Keychain, Notification, Security
  ├── Core/Utilities/         — Extensions (Color, Date)
  └── Modules/                — 8 个业务模块
      ├── Home/               — 首页（含 OnboardingView）
      ├── Training/           — 训练方法列表/详情
      ├── Coach/              — 陪练模式（呼吸引导 + 语音）
      ├── Plan/               — 训练计划 + 评估问卷
      ├── CheckIn/            — 打卡系统
      ├── Review/             — 复盘报告 + 问卷
      ├── Analysis/           — 状态分析 + 雷达图
      └── Settings/           — 隐私/数据/设置（仅 Views，无 ViewModel/Service）
```

### 测试
```
📁 ControlTrainingTests/
  ├── Core/Data/ModelTests.swift
  ├── Core/Data/RepositoryTests.swift
  ├── Core/Services/AnalysisServiceTests.swift
  ├── Core/Services/PlanServiceTests.swift
  ├── Core/Services/SecurityServiceTests.swift
  ├── Core/Performance/PerformanceTests.swift
  └── Core/ViewModels/HomeViewModelTests.swift
```

### CI/CD
```
📁 .github/workflows/build-ipa.yml    — GitHub Actions IPA 构建
```

---

## 5. 当前版本状态

| 维度 | 状态 | 文件 |
|------|------|------|
| 需求 | ✅ v2.0 | `docs/specs/requirements.md` |
| 设计 | ✅ v2.0 | `docs/specs/design.md` |
| 任务 | ✅ v2.0 | `docs/specs/tasks.md` |
| 审查 | ✅ v5.2 通过（P0/P1 全修复，主 Target 编译阻断消除；剩 3 项 P2 非阻断）；v4.0 测试体系已就绪 | `docs/reviews/v5.2-代码复查报告.md`（历史见 `docs/reviews/archive/v5.1-代码复查报告.md`） |
| UI 预览 | 🚧 v0.0.1 | `preview/versions/v0.0.1.html` |
| IPA 构建 | ⏳ 待实证（P0 已清除，建议跑 `build-ipa.yml` 确认产物 30-80MB） | `.github/workflows/build-ipa.yml` |
| 测试运行 | ⏳ 待实证（主 Target 应可编译，可跑 `test.yml` 验证 166 用例） | `.github/workflows/test.yml` |

---

## 6. AI 角色专用指令

### 给架构设计 AI
```
你的工作目录: d:\Project\男性控制训练\男性控制训练\
必读文件（按顺序）:
  1. docs/specs/requirements.md    — 完整需求 + AC 编号
  2. docs/specs/design.md           — 当前架构设计
  3. docs/reviews/v5.2-代码复查报告.md  — 当前已知问题（✅ 主 Target 编译阻断已消除，剩 3 项 P2 非阻断）；v3.0/v5.1 已归档且失效
输出位置: docs/specs/design.md（请以版本更新形式修改，标注修订日期）
```

### 给编码实现 AI
```
你的工作目录: d:\Project\男性控制训练\男性控制训练\
必读文件（按顺序）:
  1. docs/specs/tasks.md            — 任务列表（含 AC 绑定）
  2. docs/specs/requirements.md     — 验收标准（AC-x.y）
  3. docs/specs/design.md           — 架构约束
源码位置: ControlTraining/ 和 ControlTrainingTests/
关键约束:
  - MVVM + Clean Architecture
  - 纯本地离线，不连网
  - AES-256-GCM + Keychain
  - Face ID / Touch ID 保护
  - 字号默认大号、高对比度、44pt 最小点击区域
  - Core Data entity codeGenerationType="category"(详见 IPA构建v2.0 报告)
```

### 给运维/CI AI
```
你的工作目录: d:\Project\男性控制训练\男性控制训练\
必读文件:
  1. docs/specs/requirements.md §4   — 技术约束
  2. docs/reviews/archive/IPA构建v2.0-代码审查报告.md  — Core Data codegen + pipefail 建议
  3. .github/workflows/build-ipa.yml — 当前构建脚本
关键点:
  - 管理 .github/workflows/build-ipa.yml
  - 注意 pipefail（xcodebuild 失败但 tee 成功时不会中断）
  - IPA 正常大小应 30-80MB，非 14KB
```

### 给测试/审查 AI
```
你的工作目录: d:\Project\男性控制训练\男性控制训练\
必读文件:
  1. docs/reviews/v5.2-代码复查报告.md  — 最新审查结论（✅ 通过，P0/P1 全修复，主 Target 编译阻断消除）
  2. docs/specs/requirements.md         — AC 编号可追溯
  3. docs/specs/tasks.md                — 任务覆盖度检查
测试目录: ControlTrainingTests/（unit-test）+ ControlTrainingUITests/（ui-testing）
当前: 166 用例（159 单测 + 5 集成 + 2 UI 冒烟）；v5.2 已消除主 Target P0 编译阻断，可直接 `xcodebuild build` + `test.yml` 实证
详见: docs/reviews/v4.0-测试覆盖审查报告.md
```

---

## 7. 文档维护规则

1. **需求变更** → 更新 `docs/specs/requirements.md`，同步更新 `design.md` 和 `tasks.md`
2. **审查完成** → 新报告放 `docs/reviews/`，旧版移入 `archive/`
3. **设计变更** → 更新 `docs/specs/design.md`，标注修订日期
4. **新文档** → 放入 `docs/` 对应子目录，更新 `docs/README.md` 索引
5. **版本归档** → 重要里程碑在 `archive/` 下创建新目录 + MANIFEST

---

## 8. 版本记录

| 日期 | 操作 | 说明 |
|------|------|------|
| 2026-07-11 | 整理归档 | 统一文档到 `docs/`，清理根目录 |
| 2026-07-11 | v0.0.1 UI 预览 | 液态玻璃风格 |
| 2026-07-11 | v5.2 代码复查 | ✅ 通过，P0/P1 全修复 + ARC-03/04/07 修复，主 Target 编译阻断消除（剩 ARC-01/05/06 三项 P2） |
| 2026-07-11 | v5.1 代码复查（已归档） | ❌ 仍不通过，BUG-CT-11 退化→1 项 P0 仍阻断 |
| 2026-07-11 | v5.0 代码审查（已归档） | ❌ 不通过，5 项 P0 编译阻断；ARC-02 死代码误判已撤回 |
| 2026-07-11 | v4.0 测试体系审查 | 补测试 target / 集成 / UI 冒烟 |
| 2026-07-10 | v3.0 审查（已失效，已归档） | 全部缺陷关闭，但结论未经真实构建验证 |

---

> 📋 **使用方式**: 将此文件内容复制，粘贴到与新 AI 的对话开头，作为初始 prompt。

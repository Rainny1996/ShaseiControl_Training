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
📄 docs/reviews/v5.7-代码复查报告.md          ← 最新代码复查（GitHub 四次实编译失败复审），❌ 构建失败（首轮 12 错误 + 二次 2 处真实本地错误 + 三次 1 处自引入 `CCPBKDFPRF` 回归 + 四次 `project.yml` 嵌入 6 个系统框架致 Embed 失败，均已修复，待重跑 CI；v5.6「Group A 已修」系误判，已被推翻）
📁 docs/reviews/archive/                       ← 历史版本（已归档，仅供参考）
    ├── v3.0-代码审查报告.md   （已失效：未经验证，被 v5.1 推翻）
    ├── v5.0-代码审查报告.md   （全量代码审查，5 项 P0 编译阻断，被 v5.1 复核替代）
    ├── v5.1-代码复查报告.md   （修复复核，BUG-CT-11 退化；被 v5.2 复核替代）
    ├── v5.2-代码复查报告.md   （已失效：静态误判「✅ 通过」，被 v5.3 实编译推翻）
    ├── v5.3-代码审查报告.md   （构建实证：34 编译错误，作为 v5.4 复审基线）
    ├── v5.4-代码复查报告.md   （v5.3 修复复审：2 错误残留，作为 v5.5 复审基线）
    ├── v5.5-代码复查报告.md   （本地复审「✅ 通过」但审查版本 ≠ CI 构建版本，虚假通过，作为 v5.6 基线）
    ├── v5.6-代码复查报告.md   （已归档·含虚假结论：误判「Group A 本地已修」，被 v5.7 实测推翻）
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
v5.2 → 修复复核：❌ 原判「✅ 通过」系静态误判（未实编译），被 v5.3 实编译推翻（已归档·失效）
v5.3 → 构建实证审查：❌ 不通过，CI `xcodebuild build` 暴露 34 个编译错误（11 文件），主 Target 完全无法编译（已归档，作为 v5.4 复审基线）
v5.4 → v5.3 修复复审：❌ 仍不通过，8 类根因 7 类已修，但 RC-7b 未修 + RC-3 引入 `rounds:` 新回归，2 错误残留（已归档，被 v5.5 复审替代）
v5.5 → v5.4 修复复审：✅ 通过，RC-7b（TrainingGoal.icon）已补、RC-3 改 `iterations:`，全部已知根因关闭；建议实跑 `build-ipa.yml` 最终确认
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
| 审查 | ❌ v5.7 构建失败（CI "Build APP" 12 错误，已修复本地代码待推送重跑；v5.6「Group A 本地已修」系误判已被推翻，v5.5 系版本错位虚假通过）；v4.0 测试体系已就绪 | `docs/reviews/v5.7-代码复查报告.md`（历史见 `docs/reviews/archive/v5.6-代码复查报告.md`） |
| UI 预览 | 🚧 v0.0.1 | `preview/versions/v0.0.1.html` |
| IPA 构建 | ❌ 构建失败（"Build APP" 步骤 `** BUILD FAILED **`，34 编译错误） | `.github/workflows/build-ipa.yml` |
| 测试运行 | ❌ 阻塞（主 Target 无法编译，test target 依赖主 Target） | `.github/workflows/test.yml` |

---

## 6. AI 角色专用指令

### 给架构设计 AI
```
你的工作目录: d:\Project\男性控制训练\男性控制训练\
必读文件（按顺序）:
  1. docs/specs/requirements.md    — 完整需求 + AC 编号
  2. docs/specs/design.md           — 当前架构设计
  3. docs/reviews/v5.7-代码复查报告.md  — 当前已知问题（❌ CI 构建失败，12 错误已定位并修复本地代码，待推送重跑；v5.6「Group A 已修」误判已被推翻，v5.5 为版本错位的虚假通过）；v3.0/v5.1~v5.6 已归档
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
  1. docs/reviews/v5.7-代码复查报告.md  — 最新审查结论（v5.7 首轮修复推送后 CI 仍失败，复现 2 处真实本地错误：CoreDataStack:19 setOption String→NSObject、SecurityService PBKDF2 类型未导出；已二次修正待重跑 CI；v5.6「Group A 已修」误判已被实测推翻）
  2. docs/specs/requirements.md         — AC 编号可追溯
  3. docs/specs/tasks.md                — 任务覆盖度检查
测试目录: ControlTrainingTests/（unit-test）+ ControlTrainingUITests/（ui-testing）
当前: 166 用例（159 单测 + 5 集成 + 2 UI 冒烟）；v5.7 复审：CI 实编译暴露 12 错误（CoreDataStack 缺括号 / SecurityService PBKDF2 / PrivacySettingsView Section 非法 / DataViewModel 缺 await），首轮已定位并修复本地代码推送；重跑 CI 仍失败，复现 2 处真实本地错误（CoreDataStack:19 setOption String→NSObject 须 `as NSString`；本环境 CryptoKit 未导出 `PBKDF2` 类型，改用 CommonCrypto `CCKeyDerivationPBKDF`），已二次修正待重跑 `xcodebuild build` + `test.yml`（⚠️ v5.6「Group A 本地已修」系未读盘误判，被 v5.7 推翻；v5.5 审查版本与构建版本错位，结论作废）
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
| 2026-07-11 | v5.7 代码复查（GitHub 第四次实编译失败复审） | ❌ "Build APP" `BUILD FAILED`：首轮 12 错误 + 二次 2 处真实本地错误（已修）；二次修正推送后重跑仍失败，复现 1 处自引入回归（SecurityService:317 误用 `CCPBKDFPRF(kCCPRFHmacSHA256)` 且 `kCCPRFHmacSHA256` 未导出），第三次修正为原始值 `3`；四次失败转为 `project.yml` 将 Charts/AVFoundation/LocalAuthentication/CryptoKit/Security/UserNotifications 6 个系统框架默认 `embed: true` 致 Embed 拷贝失败，已改 `embed: false`，待重跑 CI；推翻 v5.6「Group A 已修」误判 |
| 2026-07-11 | v5.6 代码复查（已归档·含虚假结论） | ❌ 误判「Group A 本地已修」，被 v5.7 实测推翻；showError/Data?解包/TrainingGoal.description 三项修复有效并已推送 |
| 2026-07-11 | v5.5 代码复查（已归档·虚假通过） | ❌ 原判「✅ 通过」系审查版本 ≠ CI 构建版本（本地领先 GitHub）的错位误判，被 v5.6 实编译推翻 |
| 2026-07-11 | v5.4 代码复查（已归档） | ❌ 仍不通过，RC-7b 未修 + RC-3 新回归（`rounds:`），2 错误残留 |
| 2026-07-11 | v5.3 代码审查（构建实证·已归档） | ❌ 不通过，CI 实编译 34 错误（11 文件），主 Target 无法编译 |
| 2026-07-11 | v5.2 代码复查（已归档·失效） | ❌ 原判「✅ 通过」系静态误判，被 v5.3 实编译推翻 |
| 2026-07-11 | v5.1 代码复查（已归档） | ❌ 仍不通过，BUG-CT-11 退化→1 项 P0 仍阻断 |
| 2026-07-11 | v5.0 代码审查（已归档） | ❌ 不通过，5 项 P0 编译阻断；ARC-02 死代码误判已撤回 |
| 2026-07-11 | v4.0 测试体系审查 | 补测试 target / 集成 / UI 冒烟 |
| 2026-07-10 | v3.0 审查（已失效，已归档） | 全部缺陷关闭，但结论未经真实构建验证 |

---

> 📋 **使用方式**: 将此文件内容复制，粘贴到与新 AI 的对话开头，作为初始 prompt。

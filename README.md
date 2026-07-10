# 男性控制训练 · ControlTraining

> iOS 原生 App（SwiftUI）· 纯本地离线运行 · 目标用户 35–55 岁男性

---

## 项目概述

通过科学、系统的射精控制训练方法，帮助用户安全、渐进地提升控制能力。

- **平台**：iOS 17.0+（iPhone 优先）
- **技术栈**：Swift 5.9 / SwiftUI / Core Data / CryptoKit / AVFoundation
- **架构**：MVVM + Clean Architecture（Module → Service → Repository → Core Data）
- **安全**：AES-256-GCM + Keychain + Face ID / Touch ID + 后台模糊遮罩

---

## 快速开始

```bash
# 安装依赖（仅需 XcodeGen）
brew install xcodegen

# 生成 .xcodeproj
cd 男性控制训练
xcodegen generate

# 用 Xcode 打开
open ControlTraining.xcodeproj
```

---

## 目录结构

```
男性控制训练/
├── README.md                    ← 你在这里
├── 训练计划.md                  — 8 周训练总计划（个人参考）
├── project.yml                  — XcodeGen 项目配置
│
├── docs/                        — 📚 项目文档中心
│   ├── README.md                — 文档索引与阅读指引
│   ├── specs/                   — 需求 / 设计 / 任务规格
│   └── reviews/                 — 代码审查报告（最新 v3.0 ✅）
│
├── ControlTraining/             — 🎯 主应用源码
│   ├── App/                     — App 入口 + ContentView
│   ├── Core/                    — 核心层（Data/Services/Utilities）
│   └── Modules/                 — 业务模块（Home/Training/Coach/Plan/…）
│
├── ControlTrainingTests/        — 🧪 单元测试
├── .github/                     — CI/CD（GitHub Actions 构建 IPA）
├── preview/                     — 🎨 UI 设计预览
│   ├── ui-preview.html          — 原始版预览
│   └── versions/                — 液态玻璃风格迭代版（v0.0.x）
└── archive/                     — 📦 版本归档
```

---

## 设计预览

最新 UI 预览（iOS 27 液态玻璃风格）：

> 浏览器打开 `preview/versions/v0.0.1.html`

---

## 当前状态

| 维度 | 状态 |
|------|------|
| 需求文档 | ✅ v2.0（含 AC 编号） |
| 设计文档 | ✅ v2.0（对齐需求） |
| 源码实现 | ✅ 首轮完成 |
| 代码审查 | ✅ v3.0 通过 |
| IPA 构建 | ✅ GitHub Actions 可用 |
| UI 预览 | ✅ v0.0.1（液态玻璃） |

---

## 文档快速导航

- [需求文档](docs/specs/requirements.md)
- [架构设计](docs/specs/design.md)
- [实现任务](docs/specs/tasks.md)
- [最新审查报告](docs/reviews/v5.6-代码复查报告.md)
- [文档中心索引](docs/README.md)

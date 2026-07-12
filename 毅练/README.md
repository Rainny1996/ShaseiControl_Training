# 毅练 (YiLian) — iOS 控时训练 App

将"停-动"（Start-Stop）行为训练法数字化的一款 iOS 应用。通过**语音引导 + 极简屏幕交互**，帮助用户在私密环境中完成男性行为控时训练，所有记录均存储在本地、可加密保护。

> 本 README 依据产品需求文档（PRD）与当前代码实现整理，反映截至最新提交 `69ea1fd` 的功能与状态。

---

## 目录

- [产品定位](#产品定位)
- [需求概览](#需求概览)
- [功能模块](#功能模块)
- [技术栈](#技术栈)
- [架构与目录结构](#架构与目录结构)
- [训练状态机](#训练状态机)
- [训练记录与状态解析](#训练记录与状态解析)
- [隐私与安全](#隐私与安全)
- [构建与运行](#构建与运行)
- [语音音频](#语音音频)
- [当前状态与已知问题](#当前状态与已知问题)
- [合规提示（App Store 审核）](#合规提示app-store-审核)

---

## 产品定位

- **目标用户**：希望改善行为控时能力的男性用户。
- **核心场景**：私密、无人打扰环境下的自主训练。
- **设计原则**：
  - 语音为主、屏幕极简（避免训练时频繁注视屏幕）。
  - 全程本地运行，无网络请求、无账号系统。
  - 隐私优先，离开应用即模糊、可加生物锁。

## 需求概览

依据 PRD，应用需满足以下核心需求：

1. **结构化训练流程**：准备 →（可选）唤醒 → 低兴奋区 → 可控区间 → 7 分调整 → 回落等待 → 射精许可 / 完成，支持多轮循环。
2. **语音引导**：每个阶段由语音（预录音频优先，TTS 备选）引导，关键节点（7 分、回落 15 秒、超时）自动提醒。
3. **本地记录与趋势**：保存每次训练的轮次、平均可控时长、是否使用挤捏法、是否早泄等，并以列表 + 自绘趋势图展示。
4. **隐私保护**：生物识别 / 独立密码锁、后台模糊、Core Data 文件级加密。
5. **可配置训练参数**：循环次数、回落等待时长、唤醒开关、语音语速/音量等。

## 功能模块

| 模块 | 说明 |
| --- | --- |
| 训练准备 | 准备清单淡入，用户点击"我已准备好"进入下一阶段 |
| 唤醒阶段 | 可选（设置可关），循环播放唤醒引导，3 分钟超时提醒 |
| 低兴奋区 | 进入可控状态前的缓冲，区分普通轮 / 最后一轮语音 |
| 可控区间 | 进入"控制区"，可选 20 秒周期性控制提醒 |
| 7 分调整 | 到达 7 分时停止并倒计时回落，15 秒节点语音提示 |
| 停止-挤压法 | 回落等待超时弹窗指导挤捏法，可"继续等待"延长 30 秒（仅一次） |
| 射精许可 | 用户确认后可射精，完成后展示统计 |
| 训练记录 | 列表 + 自绘趋势图，支持查看历史会话 |
| 记录详情 | 点击记录查看每轮各阶段时长明细（低兴奋/控制区/停止回落/挤捏）与各项分析 |
| 状态解析雷达图 | 列表顶部与详情页以自绘雷达图展示控制力/恢复力/耐力/稳定性/完成度（读取时派生，兼容老记录） |
| 隐私锁 | 面容 / 指纹 + 独立密码（假密码功能留后续版本） |
| 设置中心 | 循环次数、回落时长、唤醒开关、语音参数 |

## 技术栈

- **SwiftUI** + **MVVM + Combine**
- **Core Data**（`NSPersistentContainer(name: "Model")`，`NSFileProtectionComplete` 文件级加密）
- **AVSpeechSynthesizer** 语音（预录 `.m4a` 优先，TTS 备选）
- **LocalAuthentication**（面容 / 指纹）+ Keychain 密码
- 最低支持 **iOS 15**，适配 iPhone（含 iPad 通用）

## 架构与目录结构

采用 **MVVM + 状态机** 模式：状态机为单一事实来源，视图模型订阅并镜像状态，视图仅做展示与事件转发。

```
毅练/
├── 毅练.xcodeproj
└── 毅练/
    ├── App/              # App 入口、锁屏/模糊/状态栏逻辑 (YiLianApp.swift)
    ├── Models/          # 状态枚举、配置、Core Data 实体
    ├── StateMachine/    # 训练状态机（单一事实来源）
    ├── Services/        # 语音、计时、存储、认证、触感
    ├── ViewModels/      # MVVM 视图模型
    ├── Views/           # 全部 SwiftUI 视图
    ├── Model.xcdatamodeld  # Core Data 数据模型
    └── Resources/       # 资产目录、音频、脚本
```

- `StateMachine/TrainingStateMachine.swift` — 阶段流转、超时、循环计数、射精许可逻辑
- `ViewModels/TrainingViewModel.swift` — 持有状态机，向视图暴露 `@Published` 状态
- `Services/` — `VoiceService`、`TimerScheduler`、`CoreDataStack`、`LocalAuthManager`、`HapticManager`

## 训练状态机

`TrainingStateMachine` 通过 `send(_:)` 接收事件、按 `(state, event)` 决定流转：

```
.prepare
  └─ .prepared ─▶ .arousal (可选, 设置 enableArousal)
                    └─ .aroused ─▶ .lowArousal(cycle:1)
                                    └─ .enteredControl ─▶ .controlZone
                                                            └─ .reachedSeven ─▶ .stopWaiting
                                                                                  ├─ .fallBackConfirmed ─▶ 完成本轮 → .lowArousal(下一轮)
                                                                                  ├─ .doubleFingerHold ─▶ .squeeze ─▶ .lowArousal
                                                                                  └─ .continueWaiting ─▶ 延长等待
  .ejaculateReady (任意控制/低兴奋阶段) ─▶ .finished
  .prematureEjaculation (控制区) ─▶ .finished
```

视图模型通过 `machine.$state` 订阅并镜像到自身的 `@Published var state`，确保 SwiftUI 可靠刷新（尤其嵌套 `ObservableObject` 的状态冒泡）。

## 训练记录与状态解析

### 阶段计时（数据来源）
状态机在 `transitionTo(_:)` 切换阶段前调用 `settleCurrentPhase()` 结算上一阶段时长，并在 `finish()` 收尾结算最后一阶段。每个**循环阶段**（低兴奋 `lowArousal` / 控制区 `controlZone` / 停止回落 `stopWaiting` / 挤捏 `squeeze`）的累计时长按 `cycle-1` 索引聚合进 `phaseByCycle: [[String: Double]]`，最终写入 Core Data 新字段 `phaseDurations`（JSON 编码 `[[String: Double]]`）。非循环阶段（准备/唤醒/射精许可）不计入，避免污染轮次明细。

> 阶段明细仅对 2026-07-12 之后的新训练记录生效；早期记录进入详情页会显示降级提示，但仍可用概览 / 雷达图 / 可控区间时长查看。

### 记录详情（`RecordDetailView`）
点击列表任意记录进入，包含：
- **概览卡片**：日期、总时长、循环数、挤捏/提前射精标记、刹车点。
- **每轮阶段时长**：逐轮展示各阶段累计时长，带进度条与中文标签；同时保留各轮「可控区间时长」明细。
- **状态雷达图**：针对本条记录绘制。
- **各项分析**：控制力/恢复力/耐力/稳定性/完成度逐维度得分与说明。

### 状态解析雷达图（自绘，iOS 15 兼容）
- 列表顶部「最新状态解析」与详情页均使用 `RadarChartView`（纯 `Path` 绘制，无第三方依赖，风格与现有趋势图一致）。
- 五个维度 **0–100 分，读取记录时实时派生**，仅依赖已有字段，故全部历史记录均可生成：
  - **控制力**：平均可控区间时长 / 60s × 100，提前射精重罚。
  - **恢复力**：循环数 / 5 × 70 +（使用挤捏法 ? 30 : 0）。
  - **耐力**：总时长 / 1800s × 60 + 循环数 / 5 × 40。
  - **稳定性**：100 − |刹车点 − 7| × 25，提前射精重罚。
  - **完成度**：循环数 / 5 × 100，提前射精扣分。
  - 各维度裁剪至 `[0, 100]`。

## 隐私与安全

- **本地优先**：无网络请求、无埋点、无云端账号。
- **生物锁**：启动 / 回到前台需面容或指纹解锁；独立密码作为备选。
- **后台模糊**：应用退到后台或被系统遮挡时立即模糊预览（`willResignActiveNotification`）。
- **数据加密**：Core Data 持久化存储设置 `FileProtectionType.complete`，设备锁定时文件不可读。

## 构建与运行

1. 在 **macOS + Xcode 15+** 环境中打开 `毅练/毅练.xcodeproj`。
2. 选择目标设备（iPhone 模拟器或真机）。
3. 真机运行需在 **Signing & Capabilities** 中配置自己的 Team 与 Bundle ID。
   - CI 使用 `CODE_SIGNING_ALLOWED=NO` 进行无签名构建验证。
4. `⌘R` 编译运行。

> 资源目录需包含 `AppIcon.appiconset` 与 `AccentColor.colorset`（已补齐，详见[当前状态](#当前状态与已知问题)）。

## 语音音频

`VoiceService` 优先加载 `毅练/毅练/Resources/Audio/<key>.m4a` 预录音频，缺失时自动降级为系统 TTS，**不会崩溃**。

请按 `VoiceScripts.swift` 中各文本对应的 key（如 `prepare`、`arousalLoop`、`lowArousal`、`controlZone`、`sevenStopGuide`、`squeezeGuide`、`ejaculateReady`、`finished` 等）录制音频后放入 `Resources/Audio/` 目录（当前为占位，未包含实际音频文件）。

## 当前状态与已知问题

截至提交 `69ea1fd`，已修复的构建与运行时问题：

| 提交 | 问题 | 修复 |
| --- | --- | --- |
| `beff847` | Xcode 16 `momc` 崩溃 | Core Data `codeGenerationType` 改为 `none` |
| `c47411c` | actool 失败：缺 `AppIcon` / `AccentColor` | 补齐对应 `Contents.json` 资源集 |
| `730a895` | Core Data 容器名不匹配（`YiLianModel` vs `Model.xcdatamodeld`） | 改用 `NSPersistentContainer(name: "Model")` |
| `69ea1fd` | 训练流程跳过准备、唤醒后 UI 卡住 | `start()` 不再自动 `send(.prepared)`；视图模型镜像状态机 `state` 保证刷新 |

**已知 / 待验证**：

- 记录页闪退（BUG 1）预期已由 `730a895` 的 Core Data 修复解决，需新构建在真机/LiveContainer 验证。
- 非阻塞警告：部分视图存在未使用变量（如 `TrainingContainerView` 的 `cycle`），不影响功能。
- 预录音频文件尚未提供，`VoiceService` 默认走 TTS。
- 假密码（诱饵密码）功能按 PRD 留待后续版本。

**本次新增（训练记录增强）**：
- 状态机按阶段计时，`TrainingSession` 新增可选 `phaseDurations`（Core Data 轻量自动迁移，不破坏旧库），`Model.xcdatamodeld` 已声明该属性。
- 新增 `RadarChartView`（自绘雷达图）与 `RecordDetailView`（训练记录详情），并在 `RecordsView` 列表顶部加入「最新状态解析」雷达图。
- 已知边界：阶段明细仅对新增训练记录生效；雷达图指标为启发式派生，权重可后续在 `RecordsViewModel.radarScores(for:)` 中调优。

## 合规提示（App Store 审核）

- **类别**：健康 / 健身。
- **元数据措辞**：避免直接医学/敏感表述，使用"控时训练""男性健康"等中性用语。
- **免责声明**："本品仅为行为训练辅助，不替代专业医疗建议。"
- **隐私**：无数据采集，上架时需如实填写隐私营养标签（无数据收集）。

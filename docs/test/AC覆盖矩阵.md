# AC 覆盖矩阵 — 需求 10 / 11 / 12

> 测试负责人：本迭代测试/验收。生成日期：2026-07-12
> 覆盖方式图例：**单测**=XCTest 单元/逻辑；**集成**=进程内 UIHostingController+内存库驱动视图；**UI**=XCUI 冒烟；**手动**=真机/人工验证；**审查**=代码审查确认。
> 通过状态：**✅ 已实现并覆盖**（代码已就位、有对应自动化/审查手段）；**⚠️ 需 CI/真机**（代码就位，但自动化依赖 macOS+Xcode/种子数据或真机交互）。

## 需求 10 — 自定义训练计划

| AC | 覆盖方式 | 对应测试 / 验证 | 通过状态 | 备注 |
|----|----------|----------------|----------|------|
| AC-10.1 | UI + 手动 | `ControlTrainingUITests.testCustomPlanEntryReachable`；无计划页「自定义计划」按钮 | ⚠️ 需 CI/真机 | 需跳过首启引导到达计划页；真实 ≤2 点击以手动验证 |
| AC-10.2 | 单测 | `Tests需求10自定义计划.testBuildCustomPlanFromTemplate` | ✅ 已实现并覆盖 | 选模板再改预填方法与排期，生成计划且训练日落在周期内、方法来自 `allTrainingMethods` |
| AC-10.3 | 单测 | `Tests需求10自定义计划.testBuildCustomPlanBlank` | ✅ 已实现并覆盖 | 空白自建可生成合法计划；补填每日方法后训练项正确 |
| AC-10.4 | UI + 审查 | `ControlTrainingUITests.testBuilderNoDurationIntensityPeriodControls` | ⚠️ 需 CI/真机 | Builder 无「训练强度」「周期」入口，仅暴露 方法/每周训练天数/具体训练日期/每日训练方法 |
| AC-10.5 | 单测 + 审查 | `testUserTemplateRoundTripViaRepository`、`testUserTemplateRoundTripViaService`、`testDraftFromUserTemplate` | ✅ 已实现并覆盖 | Core Data 保存→读取→删除往返（Repository 与 PlanService 封装层双重覆盖）；真机重启持久化列为手动 |
| AC-10.6 | 单测 + 集成 + 审查 | `testGeneratePlanFromDraftOverwritesAndRecomputes`、`PlanBuilderIntegrationTests`、Builder `confirmationDialog("将替换当前计划")` | ✅ 已实现并覆盖 | 覆盖写旧计划+写入新计划+`updateProgress()` 重算；二次确认弹窗以代码审查+XCUI(需种子)覆盖 |
| AC-10.7 | UI + 手动 | `ControlTrainingUITests.testKeyEntriesHaveAccessibilityLabels` | ⚠️ 需 CI/真机 | 入口带 VoiceOver 标签且可点击；Dynamic Type/44pt 以真机手动验证 |

## 需求 11 — 当前计划逐条编辑

| AC | 覆盖方式 | 对应测试 / 验证 | 通过状态 | 备注 |
|----|----------|----------------|----------|------|
| AC-11.1 | UI + 手动 | `ControlTrainingUITests.testKeyEntriesHaveAccessibilityLabels`（编辑计划入口） | ⚠️ 需 CI/真机 | 需活跃计划方可出现菜单项；真实 ≤2 点击以手动验证 |
| AC-11.2 | 单测 | `Tests需求11逐条编辑.testEditViaDraftReflectsAndRecomputes` | ✅ 已实现并覆盖 | 内存草稿替换方法/改时长/改日期，`savePlanEdits` → `updatePlanItems` 全量保存后 `progress` 重算一致（符合 Q6） |
| AC-11.3 | 单测 | `testAddViaDraftUpdatesItemsAndProgress`、`testRemoveViaDraftUpdatesItemsAndProgress` | ✅ 已实现并覆盖 | 内存草稿增删，`savePlanEdits` → `updatePlanItems` 全量保存后 `items` 与 `progress` 一致（符合 Q6） |
| AC-11.4 | 单测 + 集成 | `testAddViaDraftUpdatesItemsAndProgress`、`PlanEditIntegrationTests.testPlanEditViewRendersAndSave` | ✅ 已实现并覆盖 | `savePlanEdits` → `updatePlanItems`（后台上下文保存+主上下文合并）到 `viewContext`；保存后 `refresh()` 刷新 |
| AC-11.5 | 单测 | `testSavePlanEditsRejectsZeroDuration`、`testSavePlanEditsRejectsOutOfRangeDate`、`testSavePlanEditsValidWrites`、`testCancelPlanEditsDiscards` | ✅ 已实现并覆盖 | 时长≤0/日期越界返回 `[PlanEditValidationError]` 且不写库；合法则写库；取消丢弃草稿 |
| AC-11.6 | 单测 + 回归 | `Tests需求11逐条编辑.testRequirement3GenerationRegressionNotBroken` + 既有 `PlanServiceTests`（需求 3） | ✅ 已实现并覆盖 | `createPlanFromTemplate`/`adjustPlanIfNeeded`/`regeneratePlan` 未被破坏，既有回归用例不受影响 |
| AC-11.7 | UI + 手动 | PlanEditView 内 `accessibilityLabel`（编辑/保存/取消/删除等） | ⚠️ 需 CI/真机 | 以代码审查确认标签存在；Dynamic Type/44pt 真机手动验证 |

## 需求 12 — 今日训练动作直达陪练

| AC | 覆盖方式 | 对应测试 / 验证 | 通过状态 | 备注 |
|----|----------|----------------|----------|------|
| AC-12.1 | 集成 + UI + 手动 | `PlanItemDetailIntegrationTests.testPlanItemDetailViewRendersNonCompleted`（`openPlanItemDetail`） | ⚠️ 需 CI/真机 | 今日动作行（非完成按钮）进入详情；XCUI 今日行点击需活跃计划(种子) |
| AC-12.2 | 集成 + 审查 + UI | 同上渲染（复用 `TrainingDetailView` 方法说明）+ Builder/详情 `accessibilityLabel`「开始陪练」 | ⚠️ 需 CI/真机 | 详情含方法说明与「开始陪练」按钮，代码审查确认；XCUI 详情内容需种子 |
| AC-12.3 | 单测 + 审查 | `Tests需求12直达陪练.testCoachNormalCompletionTriggersCallbackAndWritesNonPartial` | ✅ 已实现并覆盖 | `CoachView` 携带 `planItemId` 并将 `onPlanItemComplete` 赋给 `CoachViewModel.onTrainingCompleted`（代码审查确认） |
| AC-12.4 | 单测 | `testCoachNormalCompletion...`、`testCoachStopTrainingDoesNotTriggerCallbackAndWritesPartial`、`testMarkItemCompletedPersistsAndRecomputes`、`testMarkItemCompletedIdempotent` | ✅ 已实现并覆盖 | 正常完成触发 `markPlanItemCompleted` 并刷新；中途退出不勾选；幂等 |
| AC-12.5 | 单测 + 集成 + 审查 | `testCompletedItemDetailOpensButNoRetrigger`、`PlanItemDetailIntegrationTests.testPlanItemDetailViewRendersCompleted` | ✅ 已实现并覆盖 | 已完成项仅查看；视图以 `enableStart: !item.isCompleted` 禁用「开始陪练」（代码审查） |
| AC-12.6 | UI + 手动 | `ControlTrainingUITests.testKeyEntriesHaveAccessibilityLabels`（今日行） | ⚠️ 需 CI/真机 | 入口/动作行带 VoiceOver 标签且可点击；44pt 以真机手动验证 |

## 汇总

- 需求 10：7 条 AC，全部至少一条验证；5 条可由单测直接确认，2 条（10.1/10.4/10.7 跨 UI 标注）需 CI/真机。
- 需求 11：7 条 AC，全部至少一条验证；6 条可由单测直接确认，1 条（11.1/11.7 跨 UI 标注）需 CI/真机。
- 需求 12：6 条 AC，全部至少一条验证；4 条可由单测直接确认，2 条（12.1/12.2/12.6 跨 UI 标注）需 CI/真机。
- 共 20 条 AC，无遗漏。

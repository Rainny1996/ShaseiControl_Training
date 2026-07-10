# 代码审查报告 — IPA 构建 / Core Data 模型（复审 v1.0）

> ⚠️ **归档说明**：此报告关于 momc 崩溃问题，结论被 v2.0 修正。
> 最新 IPA 构建审查见 `IPA构建v2.0-代码审查报告.md`。

- **审查对象**：`ControlTraining/Core/Data/Models/ControlTrainingModel.xcdatamodeld/ControlTrainingModel.xcdatamodel/contents`
- **审查背景**：GitHub Actions 构建 IPA 时 momc 崩溃（Unexpected code generation type in xml: category/extension），产出 14KB 空壳 IPA。
- **审查结论**：⚠️ 修复不完整 — 重新构建仍会失败（新的编译错误）

## 关键发现

`contents` 中原有的 8 处 `codeGenerationType="category/extension"`（非法 UI 显示值）已被完全移除。

⚠️ 但删除 codeGenerationType 属性后，Xcode/momc 默认回退为 "class" 自动生成模式，与项目手写的 8 个 `CD*+CoreDataClass.swift`（包含完整 `@NSManaged` 属性）冲突，导致重复符号编译错误。

## v1.0 建议方案（后更正）

v1.0 建议使用 `codeGenerationType="manual/none"`。

⚠️ **v2.0 更正**：编码 AI 实际采用 `category` 方案（配合空壳类），经复审确认正确。

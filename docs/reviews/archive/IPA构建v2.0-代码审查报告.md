# 代码审查报告 — IPA 构建 / Core Data 模型（复审 v2.0）

- **审查对象**：
  - `ControlTrainingModel.xcdatamodeld/.../contents`（8 实体 `codeGenerationType`）
  - `CoreDataEntities/CD*+CoreDataClass.swift`（8 个手写 NSManagedObject 子类）
- **审查背景**：v1.0 指出删除 `codeGenerationType` 属性会触发重复符号错误，并建议 `manual/none`。本次复审确认编码 AI 实际采用 `category` 方案后的情况。
- **审查结论**：✅ **修复正确、双侧一致，可正常构建（放行通过）**

---

## 一、关键更正（对 v1.0 的自我修正）

v1.0 的结论"只有 `manual/none` 正确"是**基于修复前的旧手写文件状态**得出的——当时 `CD*+CoreDataClass.swift` 内含完整的 `@NSManaged` 属性。本次复审发现，编码 AI 做了**双侧协同修复**：

1. `contents` 中 8 实体统一设为 `codeGenerationType="category"`（合法 XML 值，对应 Xcode "Category/Extension" 模式）；
2. 同时把 8 个 `CD*+CoreDataClass.swift` 全部改为**空类壳**，将 `@NSManaged` 属性交给 Xcode 自动生成。

因此 `category` 模式现在**完全自洽**，v1.0 担心的"重复属性"不再成立。特此更正。

---

## 二、当前状态验证（全部通过）

### 2.1 模型文件（`contents`）

8 个实体均为合法 `category`（无 `category/extension` 非法值）：

```
L3  CDUser            codeGenerationType="category"  ✅
L14 CDTrainingMethod  codeGenerationType="category"  ✅
L28 CDTrainingRecord  codeGenerationType="category"  ✅
L40 CDTrainingPlan    codeGenerationType="category"  ✅
L49 CDPlanItem        codeGenerationType="category"  ✅
L59 CDCheckInRecord   codeGenerationType="category"  ✅
L66 CDAbilityProfile  codeGenerationType="category"  ✅
L78 CDReviewNote      codeGenerationType="category"  ✅
```

### 2.2 手写子类（8 个，全部为空壳）

所有 `CD*+CoreDataClass.swift` 均为空壳类（含 "属性声明由 Xcode 自动生成" 注释）。

### 2.3 一致性推导

```
model: codeGenerationType="category"
  → momc 生成 CD*+CoreDataProperties.swift（含全部 @NSManaged 属性）
hand-written: CD*+CoreDataClass.swift（仅空类壳 + 便利方法扩展）
  → 文件名/内容均不重叠
结果：无重复符号，编译通过 ✅
```

---

## 三、结论

- **v1.0 隐患已消除**：`category` + 空壳类 的组合是 Xcode 标准且正确的代码生成模式。
- **放行**：修复正确，可以重新触发 GitHub Actions 构建并安装验证。
- 仅保留 1 条非阻塞的 CI 脚本健壮性建议（`set -o pipefail`）。

import XCTest
import CoreData
import UIKit
import SwiftUI
@testable import ControlTraining

/// 需求 11（当前计划逐条编辑）单元测试 + 进程内集成断言
/// 覆盖：AC-11.2 / AC-11.3 / AC-11.4 / AC-11.5 / AC-11.6（AC-11.1/11.7 见 XCUI 与手动验证）
final class Tests需求11逐条编辑: XCTestCase {

    var dc: DataController!
    var repo: PlanRepository!

    override func setUp() {
        super.setUp()
        dc = DataController(inMemory: true)
        repo = PlanRepository(dataController: dc)
    }

    override func tearDown() {
        dc = nil
        repo = nil
        super.tearDown()
    }

    func waitUntil(_ condition: @escaping () -> Bool, timeout: TimeInterval = 3) {
        let start = Date()
        while !condition() && Date().timeIntervalSince(start) < timeout {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
    }

    private func methods() -> [TrainingMethod] {
        Array(TrainingContentData.allTrainingMethods().prefix(3))
    }

    private func seedPlan(completedIndices: Set<Int> = []) -> TrainingPlan {
        let ms = methods()
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        var items: [PlanItem] = []
        for (i, m) in ms.enumerated() {
            items.append(PlanItem(date: start,
                                  methodId: m.id,
                                  methodName: m.name,
                                  duration: 300,
                                  isCompleted: completedIndices.contains(i)))
        }
        let plan = TrainingPlan(startDate: start, endDate: end, items: items)
        repo.saveTrainingPlan(plan)
        waitUntil { self.repo.fetchActivePlan() != nil }
        return repo.fetchActivePlan()!
    }

    // MARK: - AC-11.2 / 11.3 / 11.4 增删改 + 进度重算（内存草稿 + updatePlanItems 全量保存，符合 Q6 冻结设计）

    /// AC-11.3 新增：编辑态在内存草稿增项，保存走 updatePlanItems，进度重算
    func testAddViaDraftUpdatesItemsAndProgress() {
        let plan = seedPlan(completedIndices: [0])   // 1/3 完成
        let vm = PlanViewModel(planRepository: repo,
                               trainingRepository: TrainingRepository(dataController: dc))
        vm.loadPlan()
        vm.beginPlanEditing()
        let method = methods()[0]
        vm.addItem(method: method, date: plan.startDate)
        let errors = vm.savePlanEdits()
        XCTAssertTrue(errors.isEmpty, "合法输入不应有校验错误")
        waitUntil { self.repo.fetchActivePlan()?.items.count == 4 }

        let updated = repo.fetchActivePlan()!
        XCTAssertEqual(updated.items.count, 4)
        XCTAssertEqual(updated.progress, 1.0 / 4.0, accuracy: 0.001, "新增后进度应重算为 1/4")
    }

    /// AC-11.2 替换方法 / 改时长 / 改日期：编辑落内存草稿，保存走 updatePlanItems，进度重算
    func testEditViaDraftReflectsAndRecomputes() {
        let plan = seedPlan(completedIndices: [0, 1, 2]) // 全部完成 → 1.0
        let vm = PlanViewModel(planRepository: repo,
                               trainingRepository: TrainingRepository(dataController: dc))
        vm.loadPlan()
        vm.beginPlanEditing()
        guard let target = vm.editingDraft?.items.last else { XCTFail("应存在可编辑项"); return }
        let replacement = methods()[1]   // 真实方法，替换目标项（AC-11.2 替换方法）
        vm.editItemMethod(target.id, method: replacement)
        vm.editItemDuration(target.id, duration: 450)
        vm.editItemDate(target.id, date: target.date)
        let errors = vm.savePlanEdits()
        XCTAssertTrue(errors.isEmpty, "合法输入不应有校验错误")
        waitUntil { self.repo.fetchActivePlan()?.items.first(where: { $0.id == target.id })?.methodName == replacement.name }

        let updated = repo.fetchActivePlan()!
        XCTAssertEqual(updated.items.first(where: { $0.id == target.id })?.methodName, replacement.name)
        XCTAssertEqual(updated.progress, 1.0, accuracy: 0.001, "编辑保留完成态，全部完成后进度应为 1.0")
    }

    /// AC-11.3 删除：编辑态在内存草稿删项，保存走 updatePlanItems，进度重算
    func testRemoveViaDraftUpdatesItemsAndProgress() {
        let plan = seedPlan(completedIndices: [0]) // 1/3
        let vm = PlanViewModel(planRepository: repo,
                               trainingRepository: TrainingRepository(dataController: dc))
        vm.loadPlan()
        vm.beginPlanEditing()
        guard let target = vm.editingDraft?.items[1] else { XCTFail("应存在可删除项"); return }
        vm.removeItem(target.id)
        let errors = vm.savePlanEdits()
        XCTAssertTrue(errors.isEmpty, "合法输入不应有校验错误")
        waitUntil { self.repo.fetchActivePlan()?.items.count == 2 }

        let updated = repo.fetchActivePlan()!
        XCTAssertEqual(updated.items.count, 2)
        XCTAssertEqual(updated.progress, 0.5, accuracy: 0.001, "移除 1 项后 1/2 = 0.5")
        XCTAssertNil(updated.items.first(where: { $0.id == target.id }))
    }

    // MARK: - AC-11.5 校验拒写（不落库）

    /// 注入 spy Repository，断言非法输入返回错误且未调用写库
    private func makeSpy() -> SpyPlanRepository {
        SpyPlanRepository(dataController: dc)
    }

    func testSavePlanEditsRejectsZeroDuration() {
        let spy = makeSpy()
        let vm = PlanViewModel(planRepository: spy,
                               trainingRepository: TrainingRepository(dataController: dc))
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        vm.editingDraft = PlanEditDraft(
            planId: UUID(), startDate: start, endDate: end,
            items: [PlanItem(date: start, methodId: UUID(), methodName: "X", duration: 0)]
        )

        let errors = vm.savePlanEdits()
        XCTAssertFalse(errors.isEmpty, "时长 <= 0 应返回校验错误")
        XCTAssertFalse(spy.updatePlanItemsCalled, "校验失败时不应写库")
    }

    func testSavePlanEditsRejectsOutOfRangeDate() {
        let spy = makeSpy()
        let vm = PlanViewModel(planRepository: spy,
                               trainingRepository: TrainingRepository(dataController: dc))
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        let outOfRange = Calendar.current.date(byAdding: .day, value: 10, to: start)! // 超出 endDate
        vm.editingDraft = PlanEditDraft(
            planId: UUID(), startDate: start, endDate: end,
            items: [PlanItem(date: outOfRange, methodId: UUID(), methodName: "X", duration: 300)]
        )

        let errors = vm.savePlanEdits()
        XCTAssertFalse(errors.isEmpty, "日期越界应返回校验错误")
        XCTAssertFalse(spy.updatePlanItemsCalled, "校验失败时不应写库")
    }

    func testSavePlanEditsValidWrites() {
        let spy = makeSpy()
        let vm = PlanViewModel(planRepository: spy,
                               trainingRepository: TrainingRepository(dataController: dc))
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        vm.editingDraft = PlanEditDraft(
            planId: UUID(), startDate: start, endDate: end,
            items: [PlanItem(date: start, methodId: UUID(), methodName: "X", duration: 300)]
        )

        let errors = vm.savePlanEdits()
        XCTAssertTrue(errors.isEmpty, "合法输入不应有校验错误")
        XCTAssertTrue(spy.updatePlanItemsCalled, "合法输入应写库")
    }

    // MARK: - AC-11.5 取消不落库

    func testCancelPlanEditsDiscardsDraft() {
        let vm = PlanViewModel(planRepository: repo,
                               trainingRepository: TrainingRepository(dataController: dc))
        // 预置活跃计划以便进入编辑
        let plan = seedPlan()
        vm.loadPlan()
        vm.beginPlanEditing()
        XCTAssertNotNil(vm.editingDraft)

        // 模拟编辑修改
        if let first = vm.editingDraft?.items.first {
            vm.editItemDuration(first.id, duration: 999)
        }
        vm.cancelPlanEdits()
        XCTAssertNil(vm.editingDraft, "取消后草稿应被丢弃")
        XCTAssertFalse(vm.showPlanEditor)
    }

    // MARK: - AC-11.6 回归：既有生成/智能调整逻辑未被破坏

    func testRequirement3GenerationRegressionNotBroken() {
        let vm = PlanViewModel(planRepository: repo,
                               trainingRepository: TrainingRepository(dataController: dc))
        // createPlanFromTemplate 复用需求 3 的生成算法，不应抛错
        XCTAssertNoThrow(vm.createPlanFromTemplate(PlanService.planTemplates().first!))
        XCTAssertNotNil(repo.fetchActivePlan(), "生成后应存在活跃计划")

        // adjustPlanIfNeeded / regeneratePlan 在无记录/无存档时仅早退，不抛错
        XCTAssertNoThrow(vm.adjustPlanIfNeeded())
        XCTAssertNoThrow(vm.regeneratePlan())
    }
}

/// 用于断言「写库是否被调用」的 spy（子类多态注入 PlanViewModel）
final class SpyPlanRepository: PlanRepository {
    var updatePlanItemsCalled = false
    var savedItems: [PlanItem]?

    override func updatePlanItems(planId: UUID, items: [PlanItem]) {
        updatePlanItemsCalled = true
        savedItems = items
        super.updatePlanItems(planId: planId, items: items)
    }
}

// MARK: - 进程内 SwiftUI 集成：PlanEditView 可渲染、保存/取消路径

final class PlanEditIntegrationTests: XCTestCase {

    func testPlanEditViewRendersAndCancel() {
        let dc = DataController(inMemory: true)
        let repo = PlanRepository(dataController: dc)
        let vm = PlanViewModel(planRepository: repo,
                               trainingRepository: TrainingRepository(dataController: dc))

        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        let plan = TrainingPlan(startDate: start, endDate: end,
                                items: [PlanItem(date: start,
                                                methodId: TrainingContentData.allTrainingMethods().first!.id,
                                                methodName: "方法A", duration: 300)])
        repo.saveTrainingPlan(plan)
        vm.loadPlan()
        vm.beginPlanEditing()

        let vc = UIHostingController(rootView: PlanEditView(viewModel: vm))
        _ = vc.view

        // 取消不落库
        vm.cancelPlanEdits()
        XCTAssertNil(vm.editingDraft)
    }

    func testPlanEditViewRendersAndSave() {
        let dc = DataController(inMemory: true)
        let repo = PlanRepository(dataController: dc)
        let vm = PlanViewModel(planRepository: repo,
                               trainingRepository: TrainingRepository(dataController: dc))

        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 7, to: start)!
        let plan = TrainingPlan(startDate: start, endDate: end,
                                items: [PlanItem(date: start,
                                                methodId: TrainingContentData.allTrainingMethods().first!.id,
                                                methodName: "方法A", duration: 300)])
        repo.saveTrainingPlan(plan)
        vm.loadPlan()
        vm.beginPlanEditing()

        let vc = UIHostingController(rootView: PlanEditView(viewModel: vm))
        _ = vc.view

        let errors = vm.savePlanEdits()
        XCTAssertTrue(errors.isEmpty)
        XCTAssertNil(vm.editingDraft, "保存后草稿应清空")
    }
}

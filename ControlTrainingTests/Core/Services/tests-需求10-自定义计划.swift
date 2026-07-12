import XCTest
import CoreData
import UIKit
import SwiftUI
@testable import ControlTraining

/// 需求 10（自定义训练计划）单元测试 + 进程内集成断言
/// 覆盖：AC-10.2 / AC-10.3 / AC-10.5 / AC-10.6（AC-10.1/10.4/10.7 见 XCUI 与手动验证）
final class Tests需求10自定义计划: XCTestCase {

    var dc: DataController!
    var repo: PlanRepository!
    var service: PlanService!

    override func setUp() {
        super.setUp()
        // 每个用例独立内存栈，避免相互污染
        dc = DataController(inMemory: true)
        repo = PlanRepository(dataController: dc)
        service = PlanService(dataController: dc)
    }

    override func tearDown() {
        dc = nil
        repo = nil
        service = nil
        super.tearDown()
    }

    // MARK: - 辅助

    /// 轮询等待异步（background context 保存 + 主上下文合并）完成
    func waitUntil(_ condition: @escaping () -> Bool, timeout: TimeInterval = 3) {
        let start = Date()
        while !condition() && Date().timeIntervalSince(start) < timeout {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
    }

    func firstMethod() -> TrainingMethod {
        TrainingContentData.allTrainingMethods().first!
    }

    // MARK: - AC-10.2 选模板再改

    /// 选定预设模板后编辑器预填其方法与排期，可生成合法计划
    func testBuildCustomPlanFromTemplate() {
        let template = PlanService.planTemplates().first!
        let draft = service.draftFromTemplate(template)
        XCTAssertFalse(draft.dayDrafts.isEmpty, "选模板再改应预填训练日与方法")

        let plan = service.buildCustomPlan(dayDrafts: draft.dayDrafts, baseTemplate: template)
        XCTAssertFalse(plan.items.isEmpty, "由模板草稿生成的计划应包含训练项")
        assertPlanItemsValid(plan, goalDescription: template.goal.description)
    }

    // MARK: - AC-10.3 空白自建

    /// 空白自建（无预填）也能生成合法计划；补填每日方法后训练日落在周期内
    func testBuildCustomPlanBlank() {
        // 完全空白：无训练日
        let emptyPlan = service.buildCustomPlan(dayDrafts: [])
        XCTAssertGreaterThan(emptyPlan.endDate, emptyPlan.startDate, "空白计划周期仍合法")
        XCTAssertEqual(emptyPlan.items.count, 0)
        XCTAssertEqual(emptyPlan.goal, "自定义训练计划")

        // 空白起点后自行挑选方法与日期
        let method = firstMethod()
        let draft = PlanDraft(
            goal: .control,
            difficulty: .beginner,
            dayDrafts: [
                DayDraft(dayOffset: 0, methodSelections: [MethodSelection(methodId: method.id)]),
                DayDraft(dayOffset: 3, methodSelections: [MethodSelection(methodId: method.id), MethodSelection(methodId: firstMethod2().id)])
            ]
        )
        let plan = service.buildCustomPlan(dayDrafts: draft.dayDrafts, goal: .control)
        XCTAssertEqual(plan.items.count, 3, "空白自建补填：0 日 1 法 + 3 日 2 法 = 3 项")
        assertPlanItemsValid(plan, goalDescription: TrainingGoal.control.description)
    }

    // MARK: - AC-10.2/10.3 公共断言：训练日落在周期内、方法来自 allTrainingMethods

    private func assertPlanItemsValid(_ plan: TrainingPlan, goalDescription: String) {
        let validMethodIds = Set(TrainingContentData.allTrainingMethods().map { $0.id })
        for item in plan.items {
            // 训练日落在 [startDate, endDate] 周期内
            XCTAssertTrue(item.date >= plan.startDate && item.date <= plan.endDate,
                          "训练项日期应落在计划周期内")
            // 方法来自 allTrainingMethods
            XCTAssertTrue(validMethodIds.contains(item.methodId), "方法应来自 allTrainingMethods")
            XCTAssertGreaterThan(item.duration, 0, "AC-10.4：时长不应为 0（固定 defaultDuration）")
        }
        XCTAssertEqual(plan.goal, goalDescription)
    }

    private func firstMethod2() -> TrainingMethod {
        // 取一个与 firstMethod 不同的方法，确保多方法场景
        let methods = TrainingContentData.allTrainingMethods()
        return methods.count > 1 ? methods[1] : methods[0]
    }

    // MARK: - AC-10.5 我的模板：Repository 直接往返

    func testUserTemplateRoundTripViaRepository() {
        let template = makeUserTemplate()
        repo.saveUserTemplate(template)
        waitUntil { !self.repo.fetchUserTemplates().isEmpty }

        let fetched = repo.fetchUserTemplates()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, template.name)
        XCTAssertEqual(fetched.first?.days.count, template.days.count)

        repo.deleteUserTemplate(template.id)
        waitUntil { self.repo.fetchUserTemplates().isEmpty }
        XCTAssertTrue(repo.fetchUserTemplates().isEmpty, "删除后模板库应为空")
    }

    // MARK: - AC-10.5 我的模板：PlanService 封装层（注入内存库）

    func testUserTemplateRoundTripViaService() {
        let template = makeUserTemplate()
        service.saveUserTemplate(template)
        waitUntil { !self.service.loadUserTemplates().isEmpty }

        let fetched = service.loadUserTemplates()
        XCTAssertEqual(fetched.first?.name, template.name)

        // 合并选择器：预设模板 + 我的模板
        let all = service.allTemplatesForSelection()
        XCTAssertGreaterThan(all.count, PlanService.planTemplates().count,
                              "allTemplatesForSelection 应合并预设模板与我的模板")
    }

    // MARK: - AC-10.5 由我的模板还原草稿

    func testDraftFromUserTemplate() {
        let template = makeUserTemplate()
        let draft = service.draftFromUserTemplate(template)
        XCTAssertEqual(draft.dayDrafts.count, template.days.count)
        XCTAssertEqual(draft.goal, template.goal)
        XCTAssertEqual(draft.dayDrafts.first?.dayOffset, template.days.first?.dayOffset)
    }

    // MARK: - AC-10.6 覆盖写活跃计划 + 进度重算

    func testGeneratePlanFromDraftOverwritesAndRecomputes() {
        let vm = PlanViewModel(planRepository: repo,
                               trainingRepository: TrainingRepository(dataController: dc))

        // 预置一个旧的活跃计划
        let oldPlan = TrainingPlan(
            startDate: Calendar.current.startOfDay(for: Date()),
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            items: [PlanItem(date: Date(),
                             methodId: firstMethod().id,
                             methodName: firstMethod().name,
                             duration: 300)]
        )
        repo.saveTrainingPlan(oldPlan)
        vm.loadPlan()
        XCTAssertNotNil(vm.currentPlan, "应已加载旧的活跃计划")

        // 设置自定义草稿（含 1 日 1 法）
        let method = firstMethod()
        vm.customPlanDraft = PlanDraft(
            goal: .endurance,
            difficulty: .beginner,
            dayDrafts: [DayDraft(dayOffset: 1, methodSelections: [MethodSelection(methodId: method.id)])]
        )

        // 生成（覆盖写）
        vm.generatePlanFromDraft()
        waitUntil { self.repo.fetchActivePlan()?.items.count == 1 }

        let active = repo.fetchActivePlan()
        XCTAssertEqual(active?.items.count, 1, "新计划应含 1 个训练项")
        XCTAssertEqual(active?.items.first?.methodId, method.id)
        XCTAssertEqual(active?.progress, 0, "新计划尚无完成项，进度应为 0（按 updateProgress 规则重算）")
        XCTAssertFalse(vm.showCustomPlanBuilder, "生成后编辑器应关闭")
        XCTAssertEqual(repo.fetchAllPlans().count, 1, "覆盖写后仅保留 1 个活跃计划（旧计划已删除）")
    }

    // MARK: - 工厂

    private func makeUserTemplate() -> UserPlanTemplate {
        UserPlanTemplate(
            name: "测试模板",
            difficulty: .beginner,
            frequency: 2,
            goal: .endurance,
            icon: "leaf.fill",
            days: [
                UserPlanTemplateDay(dayOffset: 0, methodSelections: [MethodSelection(methodId: firstMethod().id)]),
                UserPlanTemplateDay(dayOffset: 2, methodSelections: [MethodSelection(methodId: firstMethod().id)])
            ],
            description: "单元测试用例模板"
        )
    }
}

// MARK: - 进程内 SwiftUI 集成：PlanBuilderView 可渲染且生成流程不崩溃

/// AC-10.6 集成：渲染真实 PlanBuilderView（内存库驱动），覆盖写逻辑可通过 viewModel 触发
final class PlanBuilderIntegrationTests: XCTestCase {

    func testPlanBuilderViewRendersAndGenerates() {
        let dc = DataController(inMemory: true)
        let repo = PlanRepository(dataController: dc)
        let vm = PlanViewModel(planRepository: repo,
                               trainingRepository: TrainingRepository(dataController: dc))

        // 预置旧活跃计划，使覆盖确认路径可走
        let old = TrainingPlan(
            startDate: Calendar.current.startOfDay(for: Date()),
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            items: [PlanItem(date: Date(),
                             methodId: TrainingContentData.allTrainingMethods().first!.id,
                             methodName: "旧方法", duration: 300)]
        )
        repo.saveTrainingPlan(old)
        vm.loadPlan()

        let method = TrainingContentData.allTrainingMethods().first!
        vm.customPlanDraft = PlanDraft(
            goal: .endurance, difficulty: .beginner,
            dayDrafts: [DayDraft(dayOffset: 0, methodSelections: [MethodSelection(methodId: method.id)])]
        )

        // 渲染真实视图（强制 body 求值），不应崩溃
        let vc = UIHostingController(rootView: PlanBuilderView(viewModel: vm))
        _ = vc.view

        // 通过 viewModel 触发生成（视图内 private generate() 的等价公共路径）
        vm.generatePlanFromDraft()

        let start = Date()
        while repo.fetchActivePlan()?.items.count != 1 && Date().timeIntervalSince(start) < 3 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        XCTAssertEqual(repo.fetchActivePlan()?.items.count, 1, "集成：生成后活跃计划含 1 项")
        XCTAssertFalse(vm.showCustomPlanBuilder)
    }
}

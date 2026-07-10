import XCTest
import CoreData
@testable import ControlTraining

/// 跨层集成测试（Repository → Service → ViewModel）
///
/// 目的：现有 159 个用例均为单层单元测试，缺少"写入持久化 → 跨层读取 → 业务计算 → ViewModel 反映"的端到端闭环验证。
/// 本文件验证数据在真实 Core Data 栈（内存库）中跨层流动的正确性，对应 tasks.md 任务 11"补集成测试"要求。
final class IntegrationTests: XCTestCase {

    var dataController: DataController!
    var trainingRepo: TrainingRepository!
    var checkInRepo: CheckInRepository!
    var planRepo: PlanRepository!
    var abilityRepo: AbilityProfileRepository!
    var reviewRepo: ReviewNoteRepository!
    var analysisService: AnalysisService!
    var viewModel: HomeViewModel!

    override func setUp() {
        super.setUp()
        dataController = DataController(inMemory: true)
        trainingRepo = TrainingRepository(dataController: dataController)
        checkInRepo = CheckInRepository(dataController: dataController)
        planRepo = PlanRepository(dataController: dataController)
        abilityRepo = AbilityProfileRepository(dataController: dataController)
        reviewRepo = ReviewNoteRepository(dataController: dataController)
        analysisService = AnalysisService(
            abilityProfileRepository: abilityRepo,
            trainingRepository: trainingRepo,
            reviewNoteRepository: reviewRepo
        )
        viewModel = HomeViewModel(
            trainingRepository: trainingRepo,
            checkInRepository: checkInRepo,
            planRepository: planRepo,
            analysisService: analysisService
        )
    }

    override func tearDown() {
        dataController.deleteAllUserData()
        viewModel = nil
        analysisService = nil
        reviewRepo = nil
        abilityRepo = nil
        planRepo = nil
        checkInRepo = nil
        trainingRepo = nil
        dataController = nil
        super.tearDown()
    }

    /// 等待内存库后台写入合并到主上下文（与既有单测一致的 0.5s 合并窗口）
    private func flush() {
        let e = expectation(description: "flush background save")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { e.fulfill() }
        waitForExpectations(timeout: 2)
    }

    // MARK: - 训练记录闭环（Repository → Service → ViewModel）

    /// AC-2.6 / AC-5.2 / AC-6.1：训练记录写入后，跨层可读取并驱动评分与首页统计
    func testTrainingRecordEndToEnd() {
        let methodId = UUID()
        let record = TrainingRecord(
            methodId: methodId,
            duration: 600,
            completionRate: 0.9,
            selfRating: 4,
            mode: .basic
        )
        trainingRepo.saveTrainingRecord(record)
        flush()

        // 1. Repository 层应读回当日记录
        let today = trainingRepo.fetchTodayRecords()
        XCTAssertEqual(today.count, 1, "Repository 应读回当日训练记录")
        XCTAssertEqual(today.first?.methodId, methodId)

        // 2. AnalysisService 基于持久化数据计算综合评分（AC-6.1）
        let score = analysisService.calculateOverallScore()
        XCTAssertGreaterThan(score, 0, "有训练数据后综合评分应 > 0")
        XCTAssertLessThanOrEqual(score, 100, "综合评分不应超过 100")

        // 3. HomeViewModel.loadData 应反映统计
        viewModel.loadData()
        XCTAssertGreaterThanOrEqual(viewModel.totalTrainingCount, 1, "ViewModel 应统计到训练记录")
        XCTAssertGreaterThan(viewModel.todayTrainingDuration, 0, "ViewModel 今日训练时长应 > 0")
    }

    // MARK: - 计划闭环（PlanService → Repository → ViewModel）

    /// AC-3.2 / AC-3.5 / AC-4.1：生成计划 → 持久化 → 标记完成驱动进度 → 首页加载今日计划
    func testPlanAndCheckInEndToEnd() {
        let assessment = Assessment(
            age: 30,
            currentAbilityScore: 5,
            trainingExperience: .beginner,
            physicalCondition: .normal,
            trainingGoal: .endurance
        )
        let plan = PlanService.shared.generatePlan(from: assessment)
        XCTAssertFalse(plan.items.isEmpty, "应生成非空计划")

        planRepo.saveTrainingPlan(plan)
        flush()

        // 1. Repository 读回活跃计划
        let active = planRepo.fetchActivePlan()
        XCTAssertNotNil(active, "应读到活跃计划")
        XCTAssertEqual(active?.items.count, plan.items.count)

        // 2. 标记首个计划项完成，计划进度应上升（AC-3.5）
        if let firstItem = active?.items.first {
            planRepo.markPlanItemCompleted(itemId: firstItem.id)
            flush()
            let rate = planRepo.fetchPlanCompletionRate(planId: plan.id)
            XCTAssertGreaterThan(rate, 0, "标记完成后计划完成率应 > 0")
        }

        // 3. ViewModel 反映今日计划项（AC-4.1）
        viewModel.loadData()
        XCTAssertGreaterThanOrEqual(viewModel.todayPlanItems.count, 1, "ViewModel 应加载到今日计划项")
    }

    // MARK: - 打卡闭环（Repository → 统计）

    /// AC-4.2 / AC-4.3：保存打卡记录后，今日状态、总天数、连续天数一致
    func testCheckInEndToEnd() {
        XCTAssertFalse(checkInRepo.hasCheckedInToday(), "初始应未打卡")

        let record = CheckInRecord(date: Date(), checkInTime: Date())
        checkInRepo.saveCheckInRecord(record)
        flush()

        XCTAssertTrue(checkInRepo.hasCheckedInToday(), "打卡后今日状态应为 true")
        XCTAssertEqual(checkInRepo.fetchTotalCheckInDays(), 1, "总打卡天数应为 1")
        XCTAssertEqual(checkInRepo.fetchConsecutiveCheckInDays(), 1, "连续打卡天数应为 1")
    }

    // MARK: - 删除全部数据闭环（AC-8.3 / BUG-CT-02）

    /// 删除全部用户数据后，所有仓库应回到空态，验证 viewContext.reset() 生效
    func testDeleteAllUserDataClearsRepositories() {
        trainingRepo.saveTrainingRecord(
            TrainingRecord(methodId: UUID(), duration: 300, completionRate: 0.5, selfRating: 3, mode: .basic)
        )
        checkInRepo.saveCheckInRecord(CheckInRecord(date: Date(), checkInTime: Date()))
        flush()

        XCTAssertGreaterThanOrEqual(trainingRepo.fetchTotalRecordCount(), 1, "删除前应存在训练记录")
        XCTAssertTrue(checkInRepo.hasCheckedInToday(), "删除前应已打卡")

        dataController.deleteAllUserData()
        flush()

        XCTAssertEqual(trainingRepo.fetchTotalRecordCount(), 0, "删除后训练记录应为 0")
        XCTAssertFalse(checkInRepo.hasCheckedInToday(), "删除后今日打卡应为 false")
    }

    // MARK: - 复盘统计闭环（AC-5.3）

    /// 写入复盘笔记后，ReviewNoteRepository 的统计聚合应反映记录数
    func testReviewNoteStatisticsEndToEnd() {
        let recordId = UUID()
        let note = ReviewNote(
            trainingRecordId: recordId,
            feelingScore: 4,
            difficultyScore: 3,
            bodyReaction: "轻微疲劳",
            notes: "完成良好"
        )
        reviewRepo.saveReviewNote(note)
        flush()

        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        let stats = reviewRepo.fetchReviewStatistics(from: startDate, to: endDate)

        XCTAssertEqual(stats.totalCount, 1, "复盘统计应聚合到 1 条记录")
        XCTAssertEqual(stats.averageFeelingScore, 4.0, "平均感受分应为 4")
    }
}

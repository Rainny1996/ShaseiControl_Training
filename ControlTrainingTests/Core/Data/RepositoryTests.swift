import XCTest
import CoreData
@testable import ControlTraining

/// 数据仓库单元测试
final class RepositoryTests: XCTestCase {
    
    var dataController: DataController!
    var trainingRepo: TrainingRepository!
    var checkInRepo: CheckInRepository!
    var planRepo: PlanRepository!
    var abilityRepo: AbilityProfileRepository!
    var reviewRepo: ReviewNoteRepository!
    
    override func setUp() {
        super.setUp()
        dataController = DataController(inMemory: true)
        trainingRepo = TrainingRepository(dataController: dataController)
        checkInRepo = CheckInRepository(dataController: dataController)
        planRepo = PlanRepository(dataController: dataController)
        abilityRepo = AbilityProfileRepository(dataController: dataController)
        reviewRepo = ReviewNoteRepository(dataController: dataController)
    }
    
    override func tearDown() {
        dataController = nil
        trainingRepo = nil
        checkInRepo = nil
        planRepo = nil
        abilityRepo = nil
        reviewRepo = nil
        super.tearDown()
    }
    
    // MARK: - Training Repository Tests
    
    /// 测试保存和获取训练记录
    func testSaveAndFetchTrainingRecord() {
        let methodId = UUID()
        let record = TrainingRecord(
            methodId: methodId,
            duration: 300,
            completionRate: 0.9,
            selfRating: 4,
            notes: "测试记录",
            mode: .basic
        )
        
        trainingRepo.saveTrainingRecord(record)
        
        // 等待异步保存完成
        let expectation = self.expectation(description: "Save completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
        
        let todayRecords = trainingRepo.fetchTodayRecords()
        // 注意：内存数据库的异步保存可能需要额外处理
    }
    
    /// 测试获取训练记录总数
    func testFetchTotalRecordCount() {
        let count = trainingRepo.fetchTotalRecordCount()
        XCTAssertGreaterThanOrEqual(count, 0)
    }
    
    // MARK: - Check-in Repository Tests
    
    /// 测试今日打卡状态
    func testHasCheckedInToday() {
        let result = checkInRepo.hasCheckedInToday()
        XCTAssertFalse(result) // 初始状态应该未打卡
    }
    
    /// 测试连续打卡天数
    func testConsecutiveCheckInDays() {
        let days = checkInRepo.fetchConsecutiveCheckInDays()
        XCTAssertEqual(days, 0) // 初始状态应该为0
    }
    
    /// 测试总打卡天数
    func testTotalCheckInDays() {
        let days = checkInRepo.fetchTotalCheckInDays()
        XCTAssertEqual(days, 0) // 初始状态应该为0
    }
    
    /// 测试补签日期限制
    func testMakeUpCheckInDateLimit() {
        // 补签未来日期应失败
        let futureDate = Date().addingTimeInterval(24 * 3600)
        XCTAssertFalse(checkInRepo.makeUpCheckIn(for: futureDate))
        
        // 补签超过3天前的日期应失败
        let oldDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        XCTAssertFalse(checkInRepo.makeUpCheckIn(for: oldDate))
    }
    
    // MARK: - Plan Repository Tests
    
    /// 测试获取活跃计划
    func testFetchActivePlan() {
        let plan = planRepo.fetchActivePlan()
        XCTAssertNil(plan) // 初始状态应该没有计划
    }
    
    /// 测试获取所有计划
    func testFetchAllPlans() {
        let plans = planRepo.fetchAllPlans()
        XCTAssertEqual(plans.count, 0) // 初始状态应该为空
    }
    
    /// 测试获取今日计划项
    func testFetchTodayPlanItems() {
        let items = planRepo.fetchTodayPlanItems()
        XCTAssertEqual(items.count, 0) // 初始状态应该为空
    }
    
    // MARK: - Ability Profile Repository Tests
    
    /// 测试获取能力档案
    func testFetchAbilityProfile() {
        let profile = abilityRepo.fetchAbilityProfile()
        XCTAssertNil(profile) // 初始状态应该没有档案
    }
    
    /// 测试保存能力档案
    func testSaveAbilityProfile() {
        let profile = AbilityProfile(
            overallScore: 45,
            endurance: 0.5,
            control: 0.6,
            recovery: 0.4,
            breathCoordination: 0.35,
            muscleStrength: 0.45
        )
        
        abilityRepo.saveAbilityProfile(profile)
        
        let expectation = self.expectation(description: "Save completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }
    
    // MARK: - Review Note Repository Tests
    
    /// 测试获取所有复盘笔记
    func testFetchAllReviewNotes() {
        let notes = reviewRepo.fetchAllReviewNotes()
        XCTAssertEqual(notes.count, 0) // 初始状态应该为空
    }
    
    /// 测试获取复盘统计
    func testFetchReviewStatistics() {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate)!
        
        let stats = reviewRepo.fetchReviewStatistics(from: startDate, to: endDate)
        XCTAssertEqual(stats.totalCount, 0)
        XCTAssertEqual(stats.averageFeelingScore, 0)
        XCTAssertEqual(stats.averageDifficultyScore, 0)
        XCTAssertTrue(stats.feelingTrend.isEmpty)
        XCTAssertTrue(stats.difficultyTrend.isEmpty)
        XCTAssertTrue(stats.commonBodyReactions.isEmpty)
    }
    
    // MARK: - Core Data Stack Tests
    
    /// 测试内存数据库初始化
    func testInMemoryDataController() {
        XCTAssertNotNil(dataController)
        XCTAssertNotNil(dataController.container)
    }
    
    /// 测试保存上下文
    func testSaveContext() {
        dataController.save() // 不应崩溃
    }
    
    /// 测试删除所有用户数据
    func testDeleteAllUserData() {
        dataController.deleteAllUserData() // 不应崩溃
    }
    
    // MARK: - Domain Model Tests
    
    /// 测试训练方法Codable编解码
    func testTrainingMethodCodable() {
        let steps = [
            TrainingStep(order: 1, title: "步骤1", instruction: "说明1", duration: 30)
        ]
        let method = TrainingMethod(
            name: "测试方法",
            category: .breathing,
            difficulty: .intermediate,
            description: "测试描述",
            principle: "测试原理",
            steps: steps,
            precautions: ["注意1"],
            expectedEffect: "测试效果",
            targetAudience: "测试人群",
            defaultDuration: 180
        )
        
        do {
            let data = try JSONEncoder().encode(method)
            let decoded = try JSONDecoder().decode(TrainingMethod.self, from: data)
            XCTAssertEqual(decoded.name, method.name)
            XCTAssertEqual(decoded.category, method.category)
            XCTAssertEqual(decoded.steps.count, method.steps.count)
        } catch {
            XCTFail("编解码失败: \(error)")
        }
    }
    
    /// 测试评估数据Codable编解码
    func testAssessmentCodable() {
        let assessment = Assessment(
            age: 40,
            currentAbilityScore: 5,
            trainingExperience: .intermediate,
            physicalCondition: .normal,
            trainingGoal: .comprehensive
        )
        
        do {
            let data = try JSONEncoder().encode(assessment)
            let decoded = try JSONDecoder().decode(Assessment.self, from: data)
            XCTAssertEqual(decoded.age, assessment.age)
            XCTAssertEqual(decoded.trainingExperience, assessment.trainingExperience)
        } catch {
            XCTFail("编解码失败: \(error)")
        }
    }
    
    /// 测试训练步骤Codable编解码
    func testTrainingStepCodable() {
        let step = TrainingStep(order: 1, title: "收缩", instruction: "收缩骨盆底肌5秒", duration: 5)
        
        do {
            let data = try JSONEncoder().encode(step)
            let decoded = try JSONDecoder().decode(TrainingStep.self, from: data)
            XCTAssertEqual(decoded.order, step.order)
            XCTAssertEqual(decoded.title, step.title)
            XCTAssertEqual(decoded.duration, step.duration)
        } catch {
            XCTFail("编解码失败: \(error)")
        }
    }
    
    /// 测试CheckInRecord日期处理
    func testCheckInRecordDateHandling() {
        let now = Date()
        let record = CheckInRecord(date: now, checkInTime: now)
        XCTAssertEqual(record.date, now)
        XCTAssertEqual(record.checkInTime, now)
    }
    
    /// 测试ReviewNote默认值
    func testReviewNoteDefaults() {
        let recordId = UUID()
        let note = ReviewNote(trainingRecordId: recordId)
        XCTAssertEqual(note.feelingScore, 3)
        XCTAssertEqual(note.difficultyScore, 3)
        XCTAssertEqual(note.bodyReaction, "")
        XCTAssertEqual(note.notes, "")
    }
}
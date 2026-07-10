import XCTest
import CoreData
@testable import ControlTraining

/// 性能测试 - 测试关键操作的性能指标
final class PerformanceTests: XCTestCase {
    
    var dataController: DataController!
    var trainingRepo: TrainingRepository!
    var abilityRepo: AbilityProfileRepository!
    var reviewRepo: ReviewNoteRepository!
    var analysisService: AnalysisService!
    var planService: PlanService!
    var securityService: SecurityService!
    
    override func setUp() {
        super.setUp()
        dataController = DataController(inMemory: true)
        trainingRepo = TrainingRepository(dataController: dataController)
        abilityRepo = AbilityProfileRepository(dataController: dataController)
        reviewRepo = ReviewNoteRepository(dataController: dataController)
        analysisService = AnalysisService(
            abilityProfileRepository: abilityRepo,
            trainingRepository: trainingRepo,
            reviewNoteRepository: reviewRepo
        )
        planService = PlanService.shared
        securityService = SecurityService.shared
    }
    
    override func tearDown() {
        dataController = nil
        trainingRepo = nil
        abilityRepo = nil
        reviewRepo = nil
        analysisService = nil
        planService = nil
        securityService = nil
        super.tearDown()
    }
    
    // MARK: - 数据查询性能测试
    
    /// 测试训练记录保存性能
    func testTrainingRecordSavePerformance() {
        let methodId = UUID()
        
        measure {
            for i in 0..<50 {
                let record = TrainingRecord(
                    methodId: methodId,
                    date: Date().addingTimeInterval(Double(-i) * 86400),
                    duration: Double.random(in: 300...1200),
                    completionRate: Double.random(in: 0.3...1.0),
                    selfRating: Int.random(in: 1...5),
                    mode: .basic
                )
                trainingRepo.saveTrainingRecord(record)
            }
        }
    }
    
    /// 测试训练记录查询性能
    func testTrainingRecordFetchPerformance() {
        // 预先插入数据
        let methodId = UUID()
        for i in 0..<100 {
            let record = TrainingRecord(
                methodId: methodId,
                date: Date().addingTimeInterval(Double(-i) * 86400),
                duration: 600,
                completionRate: 0.8,
                selfRating: 4,
                mode: .basic
            )
            trainingRepo.saveTrainingRecord(record)
        }
        
        let expectation = self.expectation(description: "Data saved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3)
        
        // 测量查询性能
        measure {
            let startOfDay = Calendar.current.startOfDay(for: Date())
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            _ = trainingRepo.fetchTrainingRecords(from: startOfDay, to: endOfDay)
        }
    }
    
    /// 测试总记录数查询性能
    func testFetchTotalRecordCountPerformance() {
        // 预先插入数据
        let methodId = UUID()
        for i in 0..<200 {
            let record = TrainingRecord(
                methodId: methodId,
                date: Date().addingTimeInterval(Double(-i) * 3600),
                duration: 600,
                completionRate: 0.8,
                selfRating: 4,
                mode: .basic
            )
            trainingRepo.saveTrainingRecord(record)
        }
        
        let expectation = self.expectation(description: "Data saved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3)
        
        measure {
            _ = trainingRepo.fetchTotalRecordCount()
        }
    }
    
    // MARK: - 分析服务性能测试
    
    /// 测试综合评分计算性能
    func testCalculateOverallScorePerformance() {
        // 预先插入数据
        let methodId = UUID()
        for i in 0..<50 {
            let record = TrainingRecord(
                methodId: methodId,
                date: Date().addingTimeInterval(Double(-i) * 86400),
                duration: 600,
                completionRate: 0.8,
                selfRating: 4,
                mode: .basic
            )
            trainingRepo.saveTrainingRecord(record)
        }
        
        let expectation = self.expectation(description: "Data saved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
        
        measure {
            _ = analysisService.calculateOverallScore()
        }
    }
    
    /// 测试维度评分计算性能
    func testCalculateAllDimensionsPerformance() {
        measure {
            _ = analysisService.calculateAllDimensions()
        }
    }
    
    /// 测试薄弱环节识别性能
    func testIdentifyWeaknessesPerformance() {
        measure {
            _ = analysisService.identifyWeaknesses()
        }
    }
    
    /// 测试改善建议生成性能
    func testGenerateImprovementSuggestionsPerformance() {
        measure {
            _ = analysisService.generateImprovementSuggestions()
        }
    }
    
    /// 测试完整分析流程性能
    func testFullAnalysisFlowPerformance() {
        measure {
            _ = analysisService.calculateOverallScore()
            _ = analysisService.calculateAllDimensions()
            _ = analysisService.identifyWeaknesses()
            _ = analysisService.generateImprovementSuggestions()
            _ = analysisService.recommendTrainingCategories()
        }
    }
    
    // MARK: - 计划服务性能测试
    
    /// 测试计划生成性能
    func testGeneratePlanPerformance() {
        let assessment = Assessment(
            age: 30,
            currentAbilityScore: 5,
            trainingExperience: .beginner,
            physicalCondition: .normal,
            trainingGoal: .endurance
        )
        
        measure {
            _ = planService.generatePlan(from: assessment)
        }
    }
    
    /// 测试不同目标的计划生成性能
    func testGeneratePlanForAllGoalsPerformance() {
        let goals: [TrainingGoal] = [.endurance, .control, .recovery, .comprehensive]
        
        measure {
            for goal in goals {
                let assessment = Assessment(
                    age: 30,
                    currentAbilityScore: 5,
                    trainingExperience: .beginner,
                    physicalCondition: .normal,
                    trainingGoal: goal
                )
                _ = planService.generatePlan(from: assessment)
            }
        }
    }
    
    /// 测试计划调整性能
    func testAdjustPlanPerformance() {
        let assessment = Assessment(
            age: 30,
            currentAbilityScore: 5,
            trainingExperience: .beginner,
            physicalCondition: .normal,
            trainingGoal: .endurance
        )
        let plan = planService.generatePlan(from: assessment)
        
        var records: [TrainingRecord] = []
        let methodId = plan.items.first?.methodId ?? UUID()
        for _ in 0..<10 {
            let record = TrainingRecord(
                methodId: methodId,
                duration: 600,
                completionRate: 0.8,
                selfRating: 4,
                mode: .basic
            )
            records.append(record)
        }
        
        measure {
            _ = planService.adjustPlan(plan, basedOn: records)
        }
    }
    
    // MARK: - 加密解密性能测试
    
    /// 测试数据加密性能
    func testEncryptDataPerformance() {
        let testData = Data(repeating: 0x41, count: 1024) // 1KB数据
        
        measure {
            for _ in 0..<10 {
                _ = securityService.encryptData(testData)
            }
        }
    }
    
    /// 测试数据解密性能
    func testDecryptDataPerformance() {
        let testData = Data(repeating: 0x41, count: 1024)
        guard let encrypted = securityService.encryptData(testData) else {
            XCTFail("加密失败")
            return
        }
        
        measure {
            for _ in 0..<10 {
                _ = securityService.decryptData(encrypted)
            }
        }
    }
    
    /// 测试加密解密往返性能
    func testEncryptDecryptRoundTripPerformance() {
        let testData = Data(repeating: 0x41, count: 1024)
        
        measure {
            if let encrypted = securityService.encryptData(testData) {
                _ = securityService.decryptData(encrypted)
            }
        }
    }
    
    /// 测试大文件加密性能
    func testLargeDataEncryptPerformance() {
        let largeData = Data(repeating: 0x41, count: 10 * 1024) // 10KB数据
        
        measure {
            _ = securityService.encryptData(largeData)
        }
    }
    
    /// 测试密码哈希性能
    func testPasswordHashingPerformance() {
        measure {
            for _ in 0..<5 {
                _ = securityService.setPassword("test1234")
                _ = securityService.verifyPassword("test1234")
            }
        }
    }
    
    // MARK: - 大数据量加载性能测试
    
    /// 测试大量训练记录的维度计算性能
    func testLargeDatasetDimensionCalculation() {
        // 插入大量训练记录
        let methodId = UUID()
        for i in 0..<100 {
            let record = TrainingRecord(
                methodId: methodId,
                date: Date().addingTimeInterval(Double(-i) * 86400),
                duration: Double.random(in: 300...1200),
                completionRate: Double.random(in: 0.3...1.0),
                selfRating: Int.random(in: 1...5),
                mode: .basic
            )
            trainingRepo.saveTrainingRecord(record)
        }
        
        let expectation = self.expectation(description: "Data saved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 3)
        
        measure {
            _ = analysisService.calculateAllDimensions()
            _ = analysisService.calculateOverallScore()
        }
    }
    
    /// 测试计划生成与调整综合性能
    func testPlanGenerationAndAdjustmentPerformance() {
        measure {
            let assessment = Assessment(
                age: 30,
                currentAbilityScore: 5,
                trainingExperience: .beginner,
                physicalCondition: .normal,
                trainingGoal: .comprehensive
            )
            let plan = planService.generatePlan(from: assessment)
            
            var records: [TrainingRecord] = []
            for item in plan.items.prefix(3) {
                let record = TrainingRecord(
                    methodId: item.methodId,
                    duration: item.duration,
                    completionRate: 0.8,
                    selfRating: 4,
                    mode: .basic
                )
                records.append(record)
            }
            _ = planService.adjustPlan(plan, basedOn: records)
        }
    }
}
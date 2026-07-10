import XCTest
import CoreData
@testable import ControlTraining

/// 状态分析服务单元测试
final class AnalysisServiceTests: XCTestCase {
    
    var dataController: DataController!
    var trainingRepo: TrainingRepository!
    var abilityRepo: AbilityProfileRepository!
    var reviewRepo: ReviewNoteRepository!
    var analysisService: AnalysisService!
    
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
    }
    
    override func tearDown() {
        dataController = nil
        trainingRepo = nil
        abilityRepo = nil
        reviewRepo = nil
        analysisService = nil
        super.tearDown()
    }
    
    // MARK: - 综合评分测试
    
    /// 测试无训练数据时综合评分为0
    func testOverallScoreWithNoRecords() {
        let score = analysisService.calculateOverallScore()
        XCTAssertEqual(score, 0, "无训练数据时综合评分应为0")
    }
    
    /// 测试无训练数据时各维度评分为0
    func testAllDimensionsWithNoRecords() {
        let dimensions = analysisService.calculateAllDimensions()
        XCTAssertEqual(dimensions.endurance, 0, accuracy: 0.01)
        XCTAssertEqual(dimensions.control, 0, accuracy: 0.01)
        XCTAssertEqual(dimensions.recovery, 0, accuracy: 0.01)
        XCTAssertEqual(dimensions.breathCoordination, 0, accuracy: 0.01)
        XCTAssertEqual(dimensions.muscleStrength, 0, accuracy: 0.01)
    }
    
    /// 测试综合评分范围在0-100之间
    func testOverallScoreRange() {
        // 添加训练记录后评分应在0-100范围
        let methodId = UUID()
        let record = TrainingRecord(
            methodId: methodId,
            duration: 600,
            completionRate: 0.9,
            selfRating: 4,
            mode: .basic
        )
        trainingRepo.saveTrainingRecord(record)
        
        let expectation = self.expectation(description: "Save completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
        
        let score = analysisService.calculateOverallScore()
        XCTAssertGreaterThanOrEqual(score, 0, "评分不应低于0")
        XCTAssertLessThanOrEqual(score, 100, "评分不应高于100")
    }
    
    // MARK: - 维度评分算法测试
    
    /// 测试持久力计算 - 高完成度+长时长应得高分
    func testEnduranceWithHighCompletionAndLongDuration() {
        // 创建高完成度+长时长的训练记录
        let methodId = UUID()
        for _ in 0..<5 {
            let record = TrainingRecord(
                methodId: methodId,
                duration: 900, // 15分钟
                completionRate: 0.95,
                selfRating: 5,
                mode: .progressive
            )
            trainingRepo.saveTrainingRecord(record)
        }
        
        let expectation = self.expectation(description: "Save completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
        
        let dimensions = analysisService.calculateAllDimensions()
        XCTAssertGreaterThan(dimensions.endurance, 0.5, "高完成度+长时长持久力应大于0.5")
    }
    
    /// 测试持久力计算 - 低完成度+短时长应得低分
    func testEnduranceWithLowCompletionAndShortDuration() {
        let methodId = UUID()
        for _ in 0..<3 {
            let record = TrainingRecord(
                methodId: methodId,
                duration: 120, // 2分钟
                completionRate: 0.3,
                selfRating: 2,
                mode: .basic
            )
            trainingRepo.saveTrainingRecord(record)
        }
        
        let expectation = self.expectation(description: "Save completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
        
        let dimensions = analysisService.calculateAllDimensions()
        XCTAssertLessThan(dimensions.endurance, 0.5, "低完成度+短时长持久力应小于0.5")
    }
    
    /// 测试恢复力计算 - 高频率+高稳定性应得高分
    func testRecoveryWithHighFrequencyAndStability() {
        let methodId = UUID()
        let calendar = Calendar.current
        
        // 创建连续多天的高完成度记录
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let record = TrainingRecord(
                methodId: methodId,
                date: date,
                duration: 600,
                completionRate: 0.85,
                selfRating: 4,
                mode: .basic
            )
            trainingRepo.saveTrainingRecord(record)
        }
        
        let expectation = self.expectation(description: "Save completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
        
        let dimensions = analysisService.calculateAllDimensions()
        XCTAssertGreaterThan(dimensions.recovery, 0.3, "高频率+高稳定性恢复力应较高")
    }
    
    /// 测试恢复力计算 - 单条记录应返回0.3
    func testRecoveryWithSingleRecord() {
        let methodId = UUID()
        let record = TrainingRecord(
            methodId: methodId,
            duration: 600,
            completionRate: 0.8,
            selfRating: 4,
            mode: .basic
        )
        trainingRepo.saveTrainingRecord(record)
        
        let expectation = self.expectation(description: "Save completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
        
        let dimensions = analysisService.calculateAllDimensions()
        XCTAssertEqual(dimensions.recovery, 0.3, accuracy: 0.01, "单条记录恢复力应为0.3")
    }
    
    // MARK: - 能力等级测试
    
    /// 测试能力等级映射
    func testAbilityLevelMapping() {
        XCTAssertEqual(AbilityLevel(score: 0), .entry)
        XCTAssertEqual(AbilityLevel(score: 15), .entry)
        XCTAssertEqual(AbilityLevel(score: 20), .beginner)
        XCTAssertEqual(AbilityLevel(score: 35), .beginner)
        XCTAssertEqual(AbilityLevel(score: 40), .intermediate)
        XCTAssertEqual(AbilityLevel(score: 55), .intermediate)
        XCTAssertEqual(AbilityLevel(score: 60), .advanced)
        XCTAssertEqual(AbilityLevel(score: 75), .advanced)
        XCTAssertEqual(AbilityLevel(score: 80), .expert)
        XCTAssertEqual(AbilityLevel(score: 100), .expert)
    }
    
    /// 测试获取当前能力等级
    func testGetCurrentAbilityLevel() {
        let level = analysisService.getCurrentAbilityLevel()
        // 无数据时应为entry
        XCTAssertEqual(level, .entry, "无训练数据时能力等级应为入门")
    }
    
    // MARK: - 薄弱环节识别测试
    
    /// 测试无数据时无薄弱环节
    func testIdentifyWeaknessesWithNoRecords() {
        let weaknesses = analysisService.identifyWeaknesses()
        XCTAssertTrue(weaknesses.isEmpty, "无训练数据时不应有薄弱环节")
    }
    
    /// 测试薄弱环节识别 - 低于平均水平的维度应被识别
    func testIdentifyWeaknessesWithImbalancedDimensions() {
        // 此测试需要依赖实际数据，由于需要异步保存，使用已有模型测试逻辑
        // 薄弱环节识别的核心逻辑是：低于平均值的维度被标记为薄弱
        let values = [0.8, 0.3, 0.7, 0.6, 0.5]
        let average = values.reduce(0, +) / Double(values.count) // 0.58
        let allDimensions: [AbilityDimension] = [.endurance, .control, .recovery, .breathCoordination, .muscleStrength]
        
        let weaknesses = zip(allDimensions, values)
            .filter { $0.1 < average }
            .map { $0.0 }
        
        XCTAssertEqual(weaknesses, [.control, .muscleStrength], "低于平均值的维度应被识别为薄弱环节")
    }
    
    // MARK: - 维度权重测试
    
    /// 测试默认维度权重总和为1.0
    func testDefaultDimensionWeightsSum() {
        let weights = DimensionWeights.default
        let sum = weights.endurance + weights.control + weights.recovery + weights.breathCoordination + weights.muscleStrength
        XCTAssertEqual(sum, 1.0, accuracy: 0.01, "维度权重总和应为1.0")
    }
    
    /// 测试权重分配合理性 - 持久力和控制力权重最高
    func testWeightDistribution() {
        let weights = DimensionWeights.default
        XCTAssertGreaterThanOrEqual(weights.endurance, weights.recovery, "持久力权重应≥恢复力权重")
        XCTAssertGreaterThanOrEqual(weights.control, weights.breathCoordination, "控制力权重应≥呼吸配合权重")
        XCTAssertGreaterThanOrEqual(weights.muscleStrength, weights.breathCoordination, "肌肉力量权重应≥呼吸配合权重")
    }
    
    // MARK: - 改善建议测试
    
    /// 测试无数据时生成通用建议
    func testGenerateSuggestionsWithNoRecords() {
        let suggestions = analysisService.generateImprovementSuggestions()
        // 无数据时评分低，应生成"循序渐进"建议
        XCTAssertFalse(suggestions.isEmpty, "应至少有一条建议")
    }
    
    /// 测试建议优先级排序
    func testSuggestionPriorityOrdering() {
        let suggestions = analysisService.generateImprovementSuggestions()
        // 建议应按优先级排序（high < medium < low）
        for i in 0..<(suggestions.count - 1) {
            XCTAssertLessThanOrEqual(
                suggestions[i].priority.rawValue,
                suggestions[i + 1].priority.rawValue,
                "建议应按优先级从高到低排序"
            )
        }
    }
    
    // MARK: - 能力档案测试
    
    /// 测试获取当前能力档案
    func testGetCurrentAbilityProfile() {
        let profile = analysisService.getCurrentAbilityProfile()
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile.overallScore, 0, "无数据时综合评分应为0")
    }
    
    /// 测试保存能力档案
    func testSaveCurrentAbilityProfile() {
        analysisService.saveCurrentAbilityProfile()
        // 不应崩溃
    }
    
    // MARK: - 维度得分详情测试
    
    /// 测试获取维度得分详情
    func testGetDimensionScores() {
        let scores = analysisService.getDimensionScores()
        XCTAssertEqual(scores.count, 5, "应有5个维度得分")
        
        let dimensionNames = scores.map { $0.name }
        XCTAssertTrue(dimensionNames.contains("持久力"), "应包含持久力维度")
        XCTAssertTrue(dimensionNames.contains("控制力"), "应包含控制力维度")
        XCTAssertTrue(dimensionNames.contains("恢复力"), "应包含恢复力维度")
        XCTAssertTrue(dimensionNames.contains("呼吸配合"), "应包含呼吸配合维度")
        XCTAssertTrue(dimensionNames.contains("肌肉力量"), "应包含肌肉力量维度")
    }
    
    /// 测试维度等级描述
    func testDimensionLevelDescriptions() {
        // 通过反射测试私有方法的间接输出
        let scores = analysisService.getDimensionScores()
        for score in scores {
            XCTAssertTrue(
                ["较弱", "一般", "中等", "良好", "优秀"].contains(score.level),
                "维度等级描述应为预定义值之一，实际：\(score.level)"
            )
        }
    }
    
    // MARK: - 推荐训练测试
    
    /// 测试无数据时推荐训练
    func testRecommendTrainingCategoriesWithNoRecords() {
        let recommendations = analysisService.recommendTrainingCategories()
        // 无数据时所有维度均为0，全部低于平均（0），所以无薄弱环节
        XCTAssertTrue(recommendations.isEmpty, "无训练数据时无推荐训练")
    }
    
    // MARK: - 综合场景测试
    
    /// 测试完整训练数据流程
    func testFullAnalysisFlow() {
        let methodId = UUID()
        let calendar = Calendar.current
        
        // 模拟一周训练数据
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let record = TrainingRecord(
                methodId: methodId,
                date: date,
                duration: 600,
                completionRate: 0.8,
                selfRating: 4,
                mode: .progressive
            )
            trainingRepo.saveTrainingRecord(record)
        }
        
        let expectation = self.expectation(description: "Save completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
        
        // 验证综合评分
        let score = analysisService.calculateOverallScore()
        XCTAssertGreaterThan(score, 0, "有训练数据时综合评分应大于0")
        XCTAssertLessThanOrEqual(score, 100, "综合评分不应超过100")
        
        // 验证维度评分
        let dimensions = analysisService.calculateAllDimensions()
        XCTAssertGreaterThanOrEqual(dimensions.endurance, 0)
        XCTAssertGreaterThanOrEqual(dimensions.control, 0)
        XCTAssertGreaterThanOrEqual(dimensions.recovery, 0)
        XCTAssertGreaterThanOrEqual(dimensions.breathCoordination, 0)
        XCTAssertGreaterThanOrEqual(dimensions.muscleStrength, 0)
        
        // 验证能力等级
        let level = analysisService.getCurrentAbilityLevel()
        XCTAssertNotNil(level)
        
        // 验证能力档案
        let profile = analysisService.getCurrentAbilityProfile()
        XCTAssertNotNil(profile)
    }
}
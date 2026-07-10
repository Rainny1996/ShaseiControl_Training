import XCTest
@testable import ControlTraining

/// 计划生成服务单元测试
final class PlanServiceTests: XCTestCase {
    
    var planService: PlanService!
    
    override func setUp() {
        super.setUp()
        planService = PlanService.shared
    }
    
    override func tearDown() {
        planService = nil
        super.tearDown()
    }
    
    // MARK: - 计划生成测试
    
    /// 测试生成入门级训练计划
    func testGeneratePlanForBeginner() {
        let assessment = Assessment(
            age: 25,
            currentAbilityScore: 3,
            trainingExperience: .none,
            physicalCondition: .normal,
            trainingGoal: .endurance
        )
        
        let plan = planService.generatePlan(from: assessment)
        
        XCTAssertFalse(plan.items.isEmpty, "入门级计划应包含训练项目")
        XCTAssertNotNil(plan.startDate)
        XCTAssertNotNil(plan.endDate)
        XCTAssertNotNil(plan.goal)
        XCTAssertGreaterThan(plan.items.count, 0, "计划应至少有1个训练项目")
    }
    
    /// 测试生成进阶级训练计划
    func testGeneratePlanForIntermediate() {
        let assessment = Assessment(
            age: 30,
            currentAbilityScore: 6,
            trainingExperience: .intermediate,
            physicalCondition: .good,
            trainingGoal: .control
        )
        
        let plan = planService.generatePlan(from: assessment)
        
        XCTAssertFalse(plan.items.isEmpty, "进阶级计划应包含训练项目")
        // 进阶级应有更多训练项目
        XCTAssertGreaterThan(plan.items.count, 2, "进阶级计划应有更多训练项目")
    }
    
    /// 测试生成高级训练计划
    func testGeneratePlanForAdvanced() {
        let assessment = Assessment(
            age: 28,
            currentAbilityScore: 9,
            trainingExperience: .advanced,
            physicalCondition: .excellent,
            trainingGoal: .comprehensive
        )
        
        let plan = planService.generatePlan(from: assessment)
        
        XCTAssertFalse(plan.items.isEmpty, "高级计划应包含训练项目")
        // 高级计划应有更多训练项目
        XCTAssertGreaterThan(plan.items.count, 3, "高级计划应有更多训练项目")
    }
    
    /// 测试不同训练目标生成不同计划
    func testGeneratePlanWithDifferentGoals() {
        let goals: [TrainingGoal] = [.endurance, .control, .recovery, .comprehensive]
        var plans: [TrainingPlan] = []
        
        for goal in goals {
            let assessment = Assessment(
                age: 30,
                currentAbilityScore: 5,
                trainingExperience: .beginner,
                physicalCondition: .normal,
                trainingGoal: goal
            )
            let plan = planService.generatePlan(from: assessment)
            plans.append(plan)
        }
        
        // 不同目标应生成不同计划
        let goalDescriptions = plans.map { $0.goal }
        XCTAssertTrue(goalDescriptions.contains("提升持久力"), "应包含持久力目标")
        XCTAssertTrue(goalDescriptions.contains("增强控制力"), "应包含控制力目标")
        XCTAssertTrue(goalDescriptions.contains("加快恢复"), "应包含恢复目标")
        XCTAssertTrue(goalDescriptions.contains("全面提升"), "应包含全面目标")
    }
    
    /// 测试计划日期范围正确
    func testPlanDateRange() {
        let assessment = Assessment(
            age: 30,
            currentAbilityScore: 5,
            trainingExperience: .beginner,
            physicalCondition: .normal,
            trainingGoal: .endurance
        )
        
        let plan = planService.generatePlan(from: assessment)
        
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: plan.startDate, to: plan.endDate).day ?? 0
        XCTAssertEqual(daysDifference, 7, "计划周期应为7天")
    }
    
    // MARK: - 计划调整测试
    
    /// 测试高完成率+高评分时增加难度
    func testAdjustPlanIncreaseDifficulty() {
        let assessment = Assessment(
            age: 30,
            currentAbilityScore: 5,
            trainingExperience: .beginner,
            physicalCondition: .normal,
            trainingGoal: .endurance
        )
        let originalPlan = planService.generatePlan(from: assessment)
        
        // 创建高完成率+高评分的记录
        var records: [TrainingRecord] = []
        let methodId = originalPlan.items.first?.methodId ?? UUID()
        for _ in 0..<5 {
            let record = TrainingRecord(
                methodId: methodId,
                duration: 600,
                completionRate: 0.9, // 高完成率
                selfRating: 5, // 高评分
                mode: .basic
            )
            records.append(record)
        }
        
        let adjustedPlan = planService.adjustPlan(originalPlan, basedOn: records)
        
        // 验证时长增加（约10%）
        if let originalDuration = originalPlan.items.first?.duration,
           let adjustedDuration = adjustedPlan.items.first?.duration {
            XCTAssertGreaterThan(adjustedDuration, originalDuration, "高完成率+高评分应增加训练时长")
            // 验证增加约10%
            let ratio = adjustedDuration / originalDuration
            XCTAssertEqual(ratio, 1.1, accuracy: 0.05, "难度增加应约10%")
        }
    }
    
    /// 测试低完成率+低评分时降低难度
    func testAdjustPlanDecreaseDifficulty() {
        let assessment = Assessment(
            age: 30,
            currentAbilityScore: 5,
            trainingExperience: .beginner,
            physicalCondition: .normal,
            trainingGoal: .endurance
        )
        let originalPlan = planService.generatePlan(from: assessment)
        
        // 创建低完成率+低评分的记录
        var records: [TrainingRecord] = []
        let methodId = originalPlan.items.first?.methodId ?? UUID()
        for _ in 0..<5 {
            let record = TrainingRecord(
                methodId: methodId,
                duration: 300,
                completionRate: 0.3, // 低完成率
                selfRating: 1, // 低评分
                mode: .basic
            )
            records.append(record)
        }
        
        let adjustedPlan = planService.adjustPlan(originalPlan, basedOn: records)
        
        // 验证时长减少（约15%）
        if let originalDuration = originalPlan.items.first?.duration,
           let adjustedDuration = adjustedPlan.items.first?.duration {
            XCTAssertLessThan(adjustedDuration, originalDuration, "低完成率+低评分应减少训练时长")
            // 验证减少约15%
            let ratio = adjustedDuration / originalDuration
            XCTAssertEqual(ratio, 0.85, accuracy: 0.05, "难度降低应约15%")
        }
    }
    
    /// 测试中等表现时不调整难度
    func testAdjustPlanNoChangeForModeratePerformance() {
        let assessment = Assessment(
            age: 30,
            currentAbilityScore: 5,
            trainingExperience: .beginner,
            physicalCondition: .normal,
            trainingGoal: .endurance
        )
        let originalPlan = planService.generatePlan(from: assessment)
        
        // 创建中等表现的记录
        var records: [TrainingRecord] = []
        let methodId = originalPlan.items.first?.methodId ?? UUID()
        for _ in 0..<5 {
            let record = TrainingRecord(
                methodId: methodId,
                duration: 600,
                completionRate: 0.65, // 中等完成率
                selfRating: 3, // 中等评分
                mode: .basic
            )
            records.append(record)
        }
        
        let adjustedPlan = planService.adjustPlan(originalPlan, basedOn: records)
        
        // 验证时长不变
        if let originalDuration = originalPlan.items.first?.duration,
           let adjustedDuration = adjustedPlan.items.first?.duration {
            XCTAssertEqual(originalDuration, adjustedDuration, accuracy: 1.0, "中等表现不应调整难度")
        }
    }
    
    /// 测试空记录时不调整计划
    func testAdjustPlanWithEmptyRecords() {
        let assessment = Assessment(
            age: 30,
            currentAbilityScore: 5,
            trainingExperience: .beginner,
            physicalCondition: .normal,
            trainingGoal: .endurance
        )
        let originalPlan = planService.generatePlan(from: assessment)
        
        let adjustedPlan = planService.adjustPlan(originalPlan, basedOn: [])
        
        // 空记录应返回原计划
        XCTAssertEqual(originalPlan.items.count, adjustedPlan.items.count, "空记录不应改变计划")
    }
    
    /// 测试高完成率但低评分时不增加难度
    func testAdjustPlanHighCompletionLowRating() {
        let assessment = Assessment(
            age: 30,
            currentAbilityScore: 5,
            trainingExperience: .beginner,
            physicalCondition: .normal,
            trainingGoal: .endurance
        )
        let originalPlan = planService.generatePlan(from: assessment)
        
        // 高完成率但低评分
        var records: [TrainingRecord] = []
        let methodId = originalPlan.items.first?.methodId ?? UUID()
        for _ in 0..<5 {
            let record = TrainingRecord(
                methodId: methodId,
                duration: 600,
                completionRate: 0.9,
                selfRating: 2, // 低评分
                mode: .basic
            )
            records.append(record)
        }
        
        let adjustedPlan = planService.adjustPlan(originalPlan, basedOn: records)
        
        // 不应增加难度（需要完成率>0.8且评分>=4才增加）
        if let originalDuration = originalPlan.items.first?.duration,
           let adjustedDuration = adjustedPlan.items.first?.duration {
            // 评分2<4，不应增加难度
            XCTAssertLessThanOrEqual(adjustedDuration, originalDuration * 1.05, "低评分时不应增加难度")
        }
    }
    
    // MARK: - 计划模板测试
    
    /// 测试获取计划模板
    func testGetPlanTemplates() {
        let templates = PlanService.planTemplates()
        XCTAssertGreaterThanOrEqual(templates.count, 3, "应至少有3个计划模板")
    }
    
    /// 测试模板包含必要信息
    func testTemplateContainsRequiredInfo() {
        let templates = PlanService.planTemplates()
        for template in templates {
            XCTAssertFalse(template.name.isEmpty, "模板名称不应为空")
            XCTAssertFalse(template.description.isEmpty, "模板描述不应为空")
            XCTAssertNotNil(template.difficulty, "模板难度应存在")
            XCTAssertGreaterThan(template.frequency, 0, "模板频率应大于0")
        }
    }
    
    // MARK: - 综合场景测试
    
    /// 测试完整计划生成和调整流程
    func testFullPlanGenerationAndAdjustmentFlow() {
        // 1. 初始评估生成计划
        let assessment = Assessment(
            age: 30,
            currentAbilityScore: 5,
            trainingExperience: .beginner,
            physicalCondition: .good,
            trainingGoal: .endurance
        )
        let initialPlan = planService.generatePlan(from: assessment)
        XCTAssertFalse(initialPlan.items.isEmpty)
        
        // 2. 模拟良好训练记录
        var goodRecords: [TrainingRecord] = []
        for item in initialPlan.items.prefix(3) {
            let record = TrainingRecord(
                methodId: item.methodId,
                duration: item.duration,
                completionRate: 0.9,
                selfRating: 5,
                mode: .basic
            )
            goodRecords.append(record)
        }
        
        // 3. 调整计划
        let adjustedPlan = planService.adjustPlan(initialPlan, basedOn: goodRecords)
        XCTAssertFalse(adjustedPlan.items.isEmpty)
        
        // 4. 验证调整后计划结构完整
        XCTAssertNotNil(adjustedPlan.startDate)
        XCTAssertNotNil(adjustedPlan.endDate)
        XCTAssertNotNil(adjustedPlan.goal)
    }
    
    /// 测试不同年龄段计划生成
    func testPlanGenerationForDifferentAges() {
        let ages = [20, 30, 40, 50, 60]
        
        for age in ages {
            let assessment = Assessment(
                age: age,
                currentAbilityScore: 5,
                trainingExperience: .beginner,
                physicalCondition: .normal,
                trainingGoal: .endurance
            )
            let plan = planService.generatePlan(from: assessment)
            XCTAssertFalse(plan.items.isEmpty, "年龄\(age)应能生成计划")
        }
    }
    
    /// 测试不同身体状况计划生成
    func testPlanGenerationForDifferentConditions() {
        let conditions: [PhysicalCondition] = [.excellent, .good, .normal, .poor]
        
        for condition in conditions {
            let assessment = Assessment(
                age: 30,
                currentAbilityScore: 5,
                trainingExperience: .beginner,
                physicalCondition: condition,
                trainingGoal: .endurance
            )
            let plan = planService.generatePlan(from: assessment)
            XCTAssertFalse(plan.items.isEmpty, "身体状况\(condition.rawValue)应能生成计划")
        }
    }
    
    /// 测试身体状况较差时强度上限
    func testPoorConditionLimitsIntensity() {
        // 身体状况较差+高能力评分
        let assessment = Assessment(
            age: 25,
            currentAbilityScore: 9,
            trainingExperience: .advanced,
            physicalCondition: .poor,
            trainingGoal: .endurance
        )
        let plan = planService.generatePlan(from: assessment)
        
        // 即使能力评分高，身体状况差应限制训练量
        XCTAssertFalse(plan.items.isEmpty, "身体状况差也应能生成计划")
        // 训练项目时长应受限
        for item in plan.items {
            XCTAssertLessThanOrEqual(item.duration, 1200, "身体状况差时训练时长应受限")
        }
    }
    
    /// 测试训练经验影响训练频率
    func testTrainingExperienceAffectsFrequency() {
        // 无经验
        let noExpAssessment = Assessment(
            age: 30,
            currentAbilityScore: 5,
            trainingExperience: .none,
            physicalCondition: .normal,
            trainingGoal: .endurance
        )
        let noExpPlan = planService.generatePlan(from: noExpAssessment)
        
        // 高级经验
        let advExpAssessment = Assessment(
            age: 30,
            currentAbilityScore: 5,
            trainingExperience: .advanced,
            physicalCondition: .normal,
            trainingGoal: .endurance
        )
        let advExpPlan = planService.generatePlan(from: advExpAssessment)
        
        // 高级经验应有更多训练项目（频率更高）
        XCTAssertGreaterThanOrEqual(
            advExpPlan.items.count,
            noExpPlan.items.count,
            "高级经验应有更多训练项目"
        )
    }
    
    /// 测试计划项目包含必要信息
    func testPlanItemsContainRequiredInfo() {
        let assessment = Assessment(
            age: 30,
            currentAbilityScore: 5,
            trainingExperience: .beginner,
            physicalCondition: .normal,
            trainingGoal: .endurance
        )
        let plan = planService.generatePlan(from: assessment)
        
        for item in plan.items {
            XCTAssertNotNil(item.id, "计划项目应有ID")
            XCTAssertNotNil(item.date, "计划项目应有日期")
            XCTAssertNotNil(item.methodId, "计划项目应有方法ID")
            XCTAssertFalse(item.methodName.isEmpty, "计划项目应有方法名称")
            XCTAssertGreaterThan(item.duration, 0, "计划项目时长应大于0")
        }
    }
}
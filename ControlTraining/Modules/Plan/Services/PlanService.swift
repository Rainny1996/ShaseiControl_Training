import Foundation

/// 计划服务 - 负责训练计划的生成、模板管理和动态调整
class PlanService {
    
    static let shared = PlanService()
    
    private init() {}
    
    // MARK: - 计划生成算法
    
    /// 根据评估结果生成训练计划
    /// - Parameter assessment: 用户评估数据
    /// - Returns: 生成的训练计划
    func generatePlan(from assessment: Assessment) -> TrainingPlan {
        // 1. 计算能力等级得分
        let abilityScore = calculateAbilityScore(from: assessment)
        
        // 2. 确定训练强度和频率
        let intensity = determineTrainingIntensity(abilityScore: abilityScore, condition: assessment.physicalCondition)
        let frequency = determineTrainingFrequency(experience: assessment.trainingExperience, abilityScore: abilityScore)
        
        // 3. 选择训练方法组合
        let methods = selectTrainingMethods(goal: assessment.trainingGoal, abilityScore: abilityScore)
        
        // 4. 生成周期计划
        let plan = generateWeeklyPlan(methods: methods, intensity: intensity, frequency: frequency, goal: assessment.trainingGoal)
        
        return plan
    }
    
    /// 根据训练数据动态调整计划
    /// - Parameters:
    ///   - plan: 当前计划
    ///   - records: 近期训练记录
    /// - Returns: 调整后的计划
    func adjustPlan(_ plan: TrainingPlan, basedOn records: [TrainingRecord]) -> TrainingPlan {
        guard !records.isEmpty else { return plan }
        
        var adjustedPlan = plan
        
        // 计算近期完成率
        let avgCompletionRate = records.map { $0.completionRate }.reduce(0, +) / Double(records.count)
        let avgRating = Double(records.map { $0.selfRating }.reduce(0, +)) / Double(records.count)
        
        // 根据完成率和评分调整
        if avgCompletionRate > 0.8 && avgRating >= 4 {
            // 表现良好，增加难度
            adjustedPlan = increaseDifficulty(adjustedPlan)
        } else if avgCompletionRate < 0.5 || avgRating < 2 {
            // 表现不佳，降低难度
            adjustedPlan = decreaseDifficulty(adjustedPlan)
        }
        
        // 更新进度
        adjustedPlan.updateProgress()
        
        return adjustedPlan
    }
    
    // MARK: - 能力评分计算
    
    /// 计算综合能力得分
    private func calculateAbilityScore(from assessment: Assessment) -> Int {
        var score = 0
        
        // 基础能力自评（权重40%）
        score += assessment.currentAbilityScore * 4
        
        // 训练经验加分（权重30%）
        let experienceScore: Int
        switch assessment.trainingExperience {
        case .none: experienceScore = 0
        case .beginner: experienceScore = 5
        case .intermediate: experienceScore = 10
        case .advanced: experienceScore = 15
        }
        score += experienceScore * 2
        
        // 身体状况加分（权重20%）
        let conditionScore: Int
        switch assessment.physicalCondition {
        case .excellent: conditionScore = 10
        case .good: conditionScore = 7
        case .normal: conditionScore = 4
        case .poor: conditionScore = 1
        }
        score += conditionScore * 2
        
        // 年龄调整（权重10%）
        let ageFactor: Int
        switch assessment.age {
        case 18...30: ageFactor = 10
        case 31...40: ageFactor = 8
        case 41...50: ageFactor = 6
        case 51...60: ageFactor = 4
        default: ageFactor = 3
        }
        score += ageFactor
        
        return min(score, 100)
    }
    
    // MARK: - 训练强度确定
    
    /// 确定训练强度
    private func determineTrainingIntensity(abilityScore: Int, condition: PhysicalCondition) -> TrainingIntensity {
        // 基于能力得分确定基础强度
        var intensity: TrainingIntensity
        switch abilityScore {
        case 0...20: intensity = .light
        case 21...40: intensity = .moderate
        case 41...60: intensity = .standard
        case 61...80: intensity = .challenging
        default: intensity = .intensive
        }
        
        // 根据身体状况调整
        if condition == .poor && intensity.rawValue > TrainingIntensity.moderate.rawValue {
            intensity = .moderate
        } else if condition == .excellent && intensity.rawValue < TrainingIntensity.standard.rawValue {
            intensity = .standard
        }
        
        return intensity
    }
    
    /// 确定训练频率（每周训练天数）
    private func determineTrainingFrequency(experience: TrainingExperience, abilityScore: Int) -> Int {
        var frequency: Int
        
        switch experience {
        case .none: frequency = 3
        case .beginner: frequency = 4
        case .intermediate: frequency = 5
        case .advanced: frequency = 6
        }
        
        // 能力得分高可以适当增加频率
        if abilityScore > 60 && frequency < 6 {
            frequency += 1
        }
        
        return min(frequency, 6) // 最多6天，保证至少1天休息
    }
    
    // MARK: - 训练方法选择
    
    /// 根据目标和方法选择训练方法
    private func selectTrainingMethods(goal: TrainingGoal, abilityScore: Int) -> [TrainingMethod] {
        let allMethods = TrainingContentData.allTrainingMethods()
        
        // 根据目标确定方法优先级
        let prioritizedCategories: [TrainingCategory]
        switch goal {
        case .endurance:
            // 持久力优先：凯格尔+呼吸+停-动
            prioritizedCategories = [.kegel, .breathing, .stopStart, .pelvicFloor, .squeeze]
        case .control:
            // 控制力优先：停-动+挤压+凯格尔
            prioritizedCategories = [.stopStart, .squeeze, .kegel, .breathing, .pelvicFloor]
        case .recovery:
            // 恢复优先：呼吸+骨盆底肌+凯格尔
            prioritizedCategories = [.breathing, .pelvicFloor, .kegel, .stopStart, .squeeze]
        case .comprehensive:
            // 全面提升：均衡分配
            prioritizedCategories = [.kegel, .stopStart, .breathing, .pelvicFloor, .squeeze]
        }
        
        // 根据能力等级筛选难度
        let maxDifficulty: DifficultyLevel
        switch abilityScore {
        case 0...20: maxDifficulty = .beginner
        case 21...50: maxDifficulty = .intermediate
        default: maxDifficulty = .advanced
        }
        
        // 按优先级和难度选择方法
        var selectedMethods: [TrainingMethod] = []
        for category in prioritizedCategories {
            if let method = allMethods.first(where: { $0.category == category && $0.difficulty.rawValue <= maxDifficulty.rawValue }) {
                selectedMethods.append(method)
            } else if let method = allMethods.first(where: { $0.category == category }) {
                selectedMethods.append(method)
            }
        }
        
        // 确保至少选择3种方法
        if selectedMethods.count < 3 {
            for method in allMethods where !selectedMethods.contains(where: { $0.id == method.id }) {
                selectedMethods.append(method)
                if selectedMethods.count >= 3 { break }
            }
        }
        
        return Array(selectedMethods.prefix(4)) // 最多4种方法
    }
    
    // MARK: - 周计划生成
    
    /// 生成一周训练计划
    private func generateWeeklyPlan(methods: [TrainingMethod], intensity: TrainingIntensity, frequency: Int, goal: TrainingGoal) -> TrainingPlan {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
        
        var items: [PlanItem] = []
        let trainingDays = selectTrainingDays(frequency: frequency)
        
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!
            
            if trainingDays.contains(dayOffset) {
                // 训练日：分配训练方法
                let dayMethods = assignMethodsForDay(dayOffset: dayOffset, methods: methods, intensity: intensity)
                
                for method in dayMethods {
                    let duration = calculateTrainingDuration(method: method, intensity: intensity)
                    let item = PlanItem(
                        date: date,
                        methodId: method.id,
                        methodName: method.name,
                        duration: duration
                    )
                    items.append(item)
                }
            }
            // 休息日不添加计划项
        }
        
        let goalDescription: String
        switch goal {
        case .endurance: goalDescription = "提升持久力"
        case .control: goalDescription = "增强控制力"
        case .recovery: goalDescription = "加快恢复"
        case .comprehensive: goalDescription = "全面提升"
        }
        
        return TrainingPlan(
            startDate: startDate,
            endDate: endDate,
            items: items,
            goal: goalDescription
        )
    }
    
    /// 选择训练日（返回0-6的偏移量集合）
    private func selectTrainingDays(frequency: Int) -> Set<Int> {
        // 确保均匀分布训练日，避免连续训练
        switch frequency {
        case 3: return [0, 2, 4]       // 周一、周三、周五
        case 4: return [0, 2, 4, 5]    // 周一、周三、周五、周六
        case 5: return [0, 1, 2, 4, 5] // 周一、周二、周三、周五、周六
        case 6: return [0, 1, 2, 3, 4, 5] // 周一到周六
        default: return [0, 2, 4]
        }
    }
    
    /// 为某天分配训练方法
    private func assignMethodsForDay(dayOffset: Int, methods: [TrainingMethod], intensity: TrainingIntensity) -> [TrainingMethod] {
        guard !methods.isEmpty else { return [] }
        
        // 根据强度决定每天训练的方法数量
        let methodsPerDay: Int
        switch intensity {
        case .light: methodsPerDay = 1
        case .moderate: methodsPerDay = 1
        case .standard: methodsPerDay = 2
        case .challenging: methodsPerDay = 2
        case .intensive: methodsPerDay = 3
        }
        
        // 轮换方法，避免每天都做同样的训练
        let startIndex = dayOffset % methods.count
        var dayMethods: [TrainingMethod] = []
        
        for i in 0..<min(methodsPerDay, methods.count) {
            let index = (startIndex + i) % methods.count
            dayMethods.append(methods[index])
        }
        
        return dayMethods
    }
    
    /// 计算训练时长
    private func calculateTrainingDuration(method: TrainingMethod, intensity: TrainingIntensity) -> TimeInterval {
        let baseDuration = method.defaultDuration
        
        let multiplier: Double
        switch intensity {
        case .light: multiplier = 0.6
        case .moderate: multiplier = 0.8
        case .standard: multiplier = 1.0
        case .challenging: multiplier = 1.2
        case .intensive: multiplier = 1.4
        }
        
        return baseDuration * multiplier
    }
    
    // MARK: - 难度调整
    
    /// 增加训练难度
    private func increaseDifficulty(_ plan: TrainingPlan) -> TrainingPlan {
        var adjustedPlan = plan
        var adjustedItems = plan.items
        
        // 增加训练时长10%
        for i in adjustedItems.indices {
            adjustedItems[i] = PlanItem(
                id: adjustedItems[i].id,
                date: adjustedItems[i].date,
                methodId: adjustedItems[i].methodId,
                methodName: adjustedItems[i].methodName,
                duration: adjustedItems[i].duration * 1.1,
                isCompleted: adjustedItems[i].isCompleted,
                completedAt: adjustedItems[i].completedAt
            )
        }
        
        adjustedPlan = TrainingPlan(
            id: plan.id,
            startDate: plan.startDate,
            endDate: plan.endDate,
            items: adjustedItems,
            progress: plan.progress,
            goal: plan.goal
        )
        
        return adjustedPlan
    }
    
    /// 降低训练难度
    private func decreaseDifficulty(_ plan: TrainingPlan) -> TrainingPlan {
        var adjustedItems = plan.items
        
        // 减少训练时长15%
        for i in adjustedItems.indices {
            adjustedItems[i] = PlanItem(
                id: adjustedItems[i].id,
                date: adjustedItems[i].date,
                methodId: adjustedItems[i].methodId,
                methodName: adjustedItems[i].methodName,
                duration: adjustedItems[i].duration * 0.85,
                isCompleted: adjustedItems[i].isCompleted,
                completedAt: adjustedItems[i].completedAt
            )
        }
        
        return TrainingPlan(
            id: plan.id,
            startDate: plan.startDate,
            endDate: plan.endDate,
            items: adjustedItems,
            progress: plan.progress,
            goal: plan.goal
        )
    }
    
    // MARK: - 计划模板
    
    /// 获取预设计划模板
    static func planTemplates() -> [PlanTemplate] {
        return [
            PlanTemplate(
                name: "入门基础计划",
                description: "适合初学者的基础训练计划，从简单动作开始，循序渐进",
                difficulty: .beginner,
                frequency: 3,
                goal: .endurance,
                icon: "leaf.fill"
            ),
            PlanTemplate(
                name: "控制力提升计划",
                description: "专注于提升控制能力的训练计划，重点练习停-动和挤压技术",
                difficulty: .intermediate,
                frequency: 4,
                goal: .control,
                icon: "hand.raised.fill"
            ),
            PlanTemplate(
                name: "持久力进阶计划",
                description: "适合有一定基础的训练者，系统性提升持久力",
                difficulty: .intermediate,
                frequency: 5,
                goal: .endurance,
                icon: "flame.fill"
            ),
            PlanTemplate(
                name: "全面均衡计划",
                description: "均衡训练各方面能力，适合追求全面提升的训练者",
                difficulty: .advanced,
                frequency: 5,
                goal: .comprehensive,
                icon: "star.fill"
            ),
            PlanTemplate(
                name: "高强度突破计划",
                description: "高强度训练计划，适合有丰富经验的训练者突破瓶颈",
                difficulty: .advanced,
                frequency: 6,
                goal: .comprehensive,
                icon: "bolt.fill"
            )
        ]
    }
    
    /// 根据模板生成计划
    func generatePlanFromTemplate(_ template: PlanTemplate) -> TrainingPlan {
        let assessment = Assessment(
            age: 40,
            currentAbilityScore: template.difficulty == .beginner ? 3 : (template.difficulty == .intermediate ? 5 : 8),
            trainingExperience: template.difficulty == .beginner ? .none : (template.difficulty == .intermediate ? .beginner : .intermediate),
            physicalCondition: .normal,
            trainingGoal: template.goal
        )
        return generatePlan(from: assessment)
    }
}

// MARK: - 训练强度枚举

enum TrainingIntensity: Int {
    case light = 1       // 轻度
    case moderate = 2    // 适中
    case standard = 3    // 标准
    case challenging = 4 // 挑战
    case intensive = 5   // 强化
    
    var displayName: String {
        switch self {
        case .light: return "轻度"
        case .moderate: return "适中"
        case .standard: return "标准"
        case .challenging: return "挑战"
        case .intensive: return "强化"
        }
    }
}

// MARK: - 计划模板

struct PlanTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let difficulty: DifficultyLevel
    let frequency: Int
    let goal: TrainingGoal
    let icon: String
}
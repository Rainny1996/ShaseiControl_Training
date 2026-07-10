import Foundation

/// 状态分析服务 - 负责能力评分计算、薄弱环节识别、改善建议生成
class AnalysisService {
    
    static let shared = AnalysisService()
    
    private let abilityProfileRepository: AbilityProfileRepository
    private let trainingRepository: TrainingRepository
    private let reviewNoteRepository: ReviewNoteRepository
    
    init(abilityProfileRepository: AbilityProfileRepository = AbilityProfileRepository(),
         trainingRepository: TrainingRepository = TrainingRepository(),
         reviewNoteRepository: ReviewNoteRepository = ReviewNoteRepository()) {
        self.abilityProfileRepository = abilityProfileRepository
        self.trainingRepository = trainingRepository
        self.reviewNoteRepository = reviewNoteRepository
    }
    
    // MARK: - 综合评分计算
    
    /// 计算当前综合能力评分
    /// - Returns: 综合评分（0-100）
    func calculateOverallScore() -> Int {
        let dimensions = calculateAllDimensions()
        let weights = DimensionWeights.default
        
        let weightedScore = dimensions.endurance * weights.endurance
            + dimensions.control * weights.control
            + dimensions.recovery * weights.recovery
            + dimensions.breathCoordination * weights.breathCoordination
            + dimensions.muscleStrength * weights.muscleStrength
        
        return Int(min(max(weightedScore * 100, 0), 100))
    }
    
    /// 计算所有维度得分
    /// - Returns: 各维度得分（0-1范围）
    func calculateAllDimensions() -> (endurance: Double, control: Double, recovery: Double, breathCoordination: Double, muscleStrength: Double) {
        let calendar = Calendar.current
        let now = Date()
        let recentPeriod = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        
        let records = trainingRepository.fetchTrainingRecords(from: recentPeriod, to: now)
        let reviewStats = reviewNoteRepository.fetchReviewStatistics(from: recentPeriod, to: now)
        
        guard !records.isEmpty else {
            return (0, 0, 0, 0, 0)
        }
        
        // 计算各维度
        let endurance = calculateEndurance(records: records)
        let control = calculateControl(records: records, reviewStats: reviewStats)
        let recovery = calculateRecovery(records: records)
        let breathCoordination = calculateBreathCoordination(records: records, reviewStats: reviewStats)
        let muscleStrength = calculateMuscleStrength(records: records)
        
        return (endurance, control, recovery, breathCoordination, muscleStrength)
    }
    
    // MARK: - 维度评分算法
    
    /// 持久力 - 基于训练时长和完成度
    private func calculateEndurance(records: [TrainingRecord]) -> Double {
        guard !records.isEmpty else { return 0 }
        
        let avgCompletion = records.map { $0.completionRate }.reduce(0, +) / Double(records.count)
        let avgDuration = records.map { $0.duration }.reduce(0, +) / Double(records.count)
        
        // 时长因子：10分钟以上得满分，5分钟以下得低分
        let durationFactor = min(avgDuration / 600.0, 1.0)
        
        // 完成度权重60%，时长权重40%
        return min(avgCompletion * 0.6 + durationFactor * 0.4, 1.0)
    }
    
    /// 控制力 - 基于自评和难度评分
    private func calculateControl(records: [TrainingRecord], reviewStats: ReviewStatistics) -> Double {
        guard !records.isEmpty else { return 0 }
        
        let avgRating = Double(records.map { $0.selfRating }.reduce(0, +)) / Double(records.count) / 5.0
        let avgCompletion = records.map { $0.completionRate }.reduce(0, +) / Double(records.count)
        
        // 难度评分反推控制力：难度高但完成好=控制力强
        let difficultyFactor = reviewStats.averageDifficultyScore / 5.0
        let controlFromDifficulty = difficultyFactor > 0 ? avgCompletion * difficultyFactor : 0
        
        // 自评权重40%，完成度权重30%，难度控制权重30%
        return min(avgRating * 0.4 + avgCompletion * 0.3 + controlFromDifficulty * 0.3, 1.0)
    }
    
    /// 恢复力 - 基于训练频率和完成度稳定性
    private func calculateRecovery(records: [TrainingRecord]) -> Double {
        guard records.count >= 2 else { return records.count == 1 ? 0.3 : 0 }
        
        let calendar = Calendar.current
        
        // 计算训练频率（每周训练天数）
        let dates = Set(records.map { calendar.startOfDay(for: $0.date) })
        let daySpan = max(calendar.dateComponents([.day], from: calendar.startOfDay(for: records.last!.date), to: calendar.startOfDay(for: records.first!.date)).day ?? 1, 1)
        let weeklyFrequency = Double(dates.count) / Double(daySpan) * 7.0
        
        // 频率因子：每周3次以上得满分
        let frequencyFactor = min(weeklyFrequency / 3.0, 1.0)
        
        // 完成度稳定性（标准差越小越好）
        let completions = records.map { $0.completionRate }
        let avgCompletion = completions.reduce(0, +) / Double(completions.count)
        let variance = completions.map { pow($0 - avgCompletion, 2) }.reduce(0, +) / Double(completions.count)
        let stdDev = sqrt(variance)
        let stabilityFactor = max(1.0 - stdDev * 2, 0) // 标准差越小越稳定
        
        // 频率权重50%，稳定性权重50%
        return min(frequencyFactor * 0.5 + stabilityFactor * 0.5, 1.0)
    }
    
    /// 呼吸配合 - 基于呼吸训练完成度和感受评分
    private func calculateBreathCoordination(records: [TrainingRecord], reviewStats: ReviewStatistics) -> Double {
        guard !records.isEmpty else { return 0 }
        
        // ARC-04 修复：移除无效 UUID() 过滤（每次随机生成永不等同于真实 ID）
        // 呼吸配合维度基于全体训练记录的完成率与感受评分加权的通用统计
        let breathCompletion = records.map { $0.completionRate }.reduce(0, +) / Double(records.count)
        
        // 感受评分（呼吸训练与感受强相关）
        let feelingFactor = reviewStats.averageFeelingScore / 5.0
        
        // 呼吸训练完成度权重50%，感受评分权重50%
        return min(breathCompletion * 0.5 + feelingFactor * 0.5, 1.0)
    }
    
    /// 肌肉力量 - 基于凯格尔/骨盆底肌训练完成度和频率
    private func calculateMuscleStrength(records: [TrainingRecord]) -> Double {
        guard !records.isEmpty else { return 0 }
        
        // 所有训练的完成度作为基础
        let avgCompletion = records.map { $0.completionRate }.reduce(0, +) / Double(records.count)
        
        // 训练次数因子：10次以上得满分
        let countFactor = min(Double(records.count) / 10.0, 1.0)
        
        // 完成度权重60%，训练次数权重40%
        return min(avgCompletion * 0.6 + countFactor * 0.4, 1.0)
    }
    
    // MARK: - 能力等级
    
    /// 获取当前能力等级
    func getCurrentAbilityLevel() -> AbilityLevel {
        let score = calculateOverallScore()
        return AbilityLevel(score: score)
    }
    
    /// 获取当前能力档案（计算并更新）
    func getCurrentAbilityProfile() -> AbilityProfile {
        let dimensions = calculateAllDimensions()
        let overallScore = calculateOverallScore()
        
        return AbilityProfile(
            overallScore: overallScore,
            endurance: dimensions.endurance,
            control: dimensions.control,
            recovery: dimensions.recovery,
            breathCoordination: dimensions.breathCoordination,
            muscleStrength: dimensions.muscleStrength
        )
    }
    
    /// 保存当前能力档案
    func saveCurrentAbilityProfile() {
        let profile = getCurrentAbilityProfile()
        abilityProfileRepository.saveAbilityProfile(profile)
    }
    
    // MARK: - 薄弱环节识别
    
    /// 识别薄弱环节
    /// - Returns: 低于平均水平的维度列表
    func identifyWeaknesses() -> [AbilityDimension] {
        let dimensions = calculateAllDimensions()
        let values: [Double] = [
            dimensions.endurance,
            dimensions.control,
            dimensions.recovery,
            dimensions.breathCoordination,
            dimensions.muscleStrength
        ]
        
        let average = values.reduce(0, +) / Double(values.count)
        let allDimensions: [AbilityDimension] = [.endurance, .control, .recovery, .breathCoordination, .muscleStrength]
        
        return zip(allDimensions, values)
            .filter { $0.1 < average }
            .map { $0.0 }
    }
    
    /// 获取各维度得分详情
    /// - Returns: 维度名称和得分数组
    func getDimensionScores() -> [(dimension: AbilityDimension, name: String, score: Double, level: String)] {
        let dimensions = calculateAllDimensions()
        let values: [Double] = [
            dimensions.endurance,
            dimensions.control,
            dimensions.recovery,
            dimensions.breathCoordination,
            dimensions.muscleStrength
        ]
        let allDimensions: [AbilityDimension] = [.endurance, .control, .recovery, .breathCoordination, .muscleStrength]
        
        return zip(allDimensions, values).map { dim, score in
            (dim, dim.rawValue, score, dimensionLevel(score))
        }
    }
    
    /// 维度等级描述
    private func dimensionLevel(_ score: Double) -> String {
        switch score {
        case 0..<0.2: return "较弱"
        case 0.2..<0.4: return "一般"
        case 0.4..<0.6: return "中等"
        case 0.6..<0.8: return "良好"
        default: return "优秀"
        }
    }
    
    // MARK: - 改善建议生成
    
    /// 生成个性化改善建议
    /// - Returns: 改善建议列表
    func generateImprovementSuggestions() -> [ImprovementSuggestion] {
        var suggestions: [ImprovementSuggestion] = []
        let weaknesses = identifyWeaknesses()
        let dimensions = calculateAllDimensions()
        let overallScore = calculateOverallScore()
        
        // 基于薄弱维度生成建议
        for weakness in weaknesses {
            if let suggestion = suggestionForWeakness(weakness, score: dimensionScore(weakness, dimensions: dimensions)) {
                suggestions.append(suggestion)
            }
        }
        
        // 基于综合评分生成通用建议
        if overallScore < 30 {
            suggestions.append(ImprovementSuggestion(
                category: .general,
                title: "循序渐进",
                description: "建议从基础训练开始，每天坚持5-10分钟的简单练习，逐步建立基础能力。",
                priority: .high,
                relatedDimension: nil
            ))
        } else if overallScore >= 80 {
            suggestions.append(ImprovementSuggestion(
                category: .general,
                title: "保持与突破",
                description: "你已达到较高水平，建议尝试更高难度的训练模式，挑战自我极限。",
                priority: .low,
                relatedDimension: nil
            ))
        }
        
        // 如果没有薄弱环节，给鼓励
        if weaknesses.isEmpty && overallScore >= 40 {
            suggestions.append(ImprovementSuggestion(
                category: .general,
                title: "均衡发展",
                description: "各维度发展均衡，继续保持当前训练节奏，稳步提升整体能力。",
                priority: .low,
                relatedDimension: nil
            ))
        }
        
        return suggestions.sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
    
    /// 根据薄弱维度生成建议
    private func suggestionForWeakness(_ dimension: AbilityDimension, score: Double) -> ImprovementSuggestion? {
        switch dimension {
        case .endurance:
            return ImprovementSuggestion(
                category: .training,
                title: "提升持久力",
                description: "增加训练时长和频率，建议每次训练保持10分钟以上，每周至少3次。",
                priority: score < 0.3 ? .high : .medium,
                relatedDimension: dimension
            )
        case .control:
            return ImprovementSuggestion(
                category: .training,
                title: "增强控制力",
                description: "重点练习停-动技术和挤压技术，提升主动控制能力。训练中注意感受临界点。",
                priority: score < 0.3 ? .high : .medium,
                relatedDimension: dimension
            )
        case .recovery:
            return ImprovementSuggestion(
                category: .lifestyle,
                title: "改善恢复力",
                description: "保持规律训练节奏，避免过度训练。确保充足休息，训练间隔至少休息一天。",
                priority: score < 0.3 ? .high : .medium,
                relatedDimension: dimension
            )
        case .breathCoordination:
            return ImprovementSuggestion(
                category: .training,
                title: "加强呼吸配合",
                description: "增加呼吸训练比例，练习腹式呼吸法。训练中注意呼吸节奏与动作配合。",
                priority: score < 0.3 ? .high : .medium,
                relatedDimension: dimension
            )
        case .muscleStrength:
            return ImprovementSuggestion(
                category: .training,
                title: "增强肌肉力量",
                description: "坚持凯格尔运动和骨盆底肌训练，逐步增加收缩强度和持续时间。",
                priority: score < 0.3 ? .high : .medium,
                relatedDimension: dimension
            )
        }
    }
    
    /// 获取维度得分
    private func dimensionScore(_ dimension: AbilityDimension, dimensions: (endurance: Double, control: Double, recovery: Double, breathCoordination: Double, muscleStrength: Double)) -> Double {
        switch dimension {
        case .endurance: return dimensions.endurance
        case .control: return dimensions.control
        case .recovery: return dimensions.recovery
        case .breathCoordination: return dimensions.breathCoordination
        case .muscleStrength: return dimensions.muscleStrength
        }
    }
    
    // MARK: - 推荐训练
    
    /// 根据薄弱环节推荐针对性训练
    /// - Returns: 推荐训练类别列表
    func recommendTrainingCategories() -> [(category: TrainingCategory, reason: String)] {
        let weaknesses = identifyWeaknesses()
        var recommendations: [(TrainingCategory, String)] = []
        
        for weakness in weaknesses {
            switch weakness {
            case .endurance:
                recommendations.append((.breathing, "呼吸训练有助于提升持久力和耐力"))
            case .control:
                recommendations.append((.stopStart, "停-动技术是提升控制力的核心方法"))
                recommendations.append((.squeeze, "挤压技术可以增强主动控制能力"))
            case .recovery:
                recommendations.append((.kegel, "凯格尔运动促进肌肉恢复和血液循环"))
            case .breathCoordination:
                recommendations.append((.breathing, "专项呼吸训练提升呼吸与动作的协调性"))
            case .muscleStrength:
                recommendations.append((.kegel, "凯格尔运动是增强骨盆底肌力量的基础"))
                recommendations.append((.pelvicFloor, "骨盆底肌训练直接强化目标肌群"))
            }
        }
        
        // 去重
        var seen = Set<TrainingCategory>()
        return recommendations.filter { seen.insert($0.0).inserted }
    }
    
    // MARK: - 历史评分趋势
    
    /// 获取历史评分趋势数据
    /// - Parameter days: 天数
    /// - Returns: 每日评分数据
    func fetchScoreTrend(days: Int = 30) -> [DailyScore] {
        abilityProfileRepository.fetchAbilityHistory(days: days).map { profile in
            DailyScore(date: profile.lastUpdated, score: Double(profile.overallScore))
        }
    }
    
    /// 获取维度历史趋势
    /// - Parameter dimension: 维度
    /// - Parameter days: 天数
    /// - Returns: 每日维度评分
    func fetchDimensionTrend(dimension: AbilityDimension, days: Int = 30) -> [DailyScore] {
        let profiles = abilityProfileRepository.fetchAbilityHistory(days: days)
        return profiles.map { profile in
            let score: Double
            switch dimension {
            case .endurance: score = profile.endurance * 100
            case .control: score = profile.control * 100
            case .recovery: score = profile.recovery * 100
            case .breathCoordination: score = profile.breathCoordination * 100
            case .muscleStrength: score = profile.muscleStrength * 100
            }
            return DailyScore(date: profile.lastUpdated, score: score)
        }
    }
}

// MARK: - 维度权重

/// 维度权重配置
struct DimensionWeights {
    let endurance: Double
    let control: Double
    let recovery: Double
    let breathCoordination: Double
    let muscleStrength: Double
    
    static let `default` = DimensionWeights(
        endurance: 0.25,
        control: 0.25,
        recovery: 0.15,
        breathCoordination: 0.15,
        muscleStrength: 0.20
    )
}

// MARK: - 改善建议模型

/// 改善建议
struct ImprovementSuggestion: Identifiable {
    let id = UUID()
    let category: SuggestionCategory
    let title: String
    let description: String
    let priority: SuggestionPriority
    let relatedDimension: AbilityDimension?
}

/// 建议类别
enum SuggestionCategory: String, CaseIterable {
    case training = "训练建议"
    case lifestyle = "生活建议"
    case general = "综合建议"
    
    var icon: String {
        switch self {
        case .training: return "figure.core.training"
        case .lifestyle: return "heart.circle.fill"
        case .general: return "lightbulb.fill"
        }
    }
    
    var color: String {
        switch self {
        case .training: return "blue"
        case .lifestyle: return "green"
        case .general: return "orange"
        }
    }
}

/// 建议优先级
enum SuggestionPriority: Int, Comparable {
    case high = 0
    case medium = 1
    case low = 2
    
    static func < (lhs: SuggestionPriority, rhs: SuggestionPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var label: String {
        switch self {
        case .high: return "重要"
        case .medium: return "建议"
        case .low: return "参考"
        }
    }
}
import Foundation

// MARK: - Training Plan Model

/// 训练计划数据模型
struct TrainingPlan: Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    var items: [PlanItem]
    var progress: Double
    let goal: String
    
    init(id: UUID = UUID(),
         startDate: Date = Date(),
         endDate: Date,
         items: [PlanItem] = [],
         progress: Double = 0,
         goal: String = "") {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.items = items
        self.progress = progress
        self.goal = goal
    }
    
    /// 计划周期类型
    var periodType: PlanPeriod {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        switch days {
        case 1...7: return .week
        case 8...31: return .month
        default: return .quarter
        }
    }
    
    /// 计算完成进度
    mutating func updateProgress() {
        guard !items.isEmpty else {
            progress = 0
            return
        }
        let completedCount = items.filter { $0.isCompleted }.count
        progress = Double(completedCount) / Double(items.count)
    }
}

/// 计划周期
enum PlanPeriod: String, CaseIterable {
    case week = "短期（1周）"
    case month = "中期（1月）"
    case quarter = "长期（3月）"
}

/// 计划项
struct PlanItem: Identifiable {
    let id: UUID
    let date: Date
    let methodId: UUID
    let methodName: String
    let duration: TimeInterval
    var isCompleted: Bool
    var completedAt: Date?
    
    init(id: UUID = UUID(),
         date: Date,
         methodId: UUID,
         methodName: String,
         duration: TimeInterval,
         isCompleted: Bool = false,
         completedAt: Date? = nil) {
        self.id = id
        self.date = date
        self.methodId = methodId
        self.methodName = methodName
        self.duration = duration
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}

// MARK: - Assessment Model

/// 初始评估问卷数据模型
struct Assessment: Codable {
    var age: Int
    var currentAbilityScore: Int // 1-10
    var trainingExperience: TrainingExperience
    var physicalCondition: PhysicalCondition
    var trainingGoal: TrainingGoal
    
    init(age: Int = 40,
         currentAbilityScore: Int = 5,
         trainingExperience: TrainingExperience = .none,
         physicalCondition: PhysicalCondition = .normal,
         trainingGoal: TrainingGoal = .endurance) {
        self.age = age
        self.currentAbilityScore = currentAbilityScore
        self.trainingExperience = trainingExperience
        self.physicalCondition = physicalCondition
        self.trainingGoal = trainingGoal
    }
}

/// 训练经验
enum TrainingExperience: String, Codable, CaseIterable {
    case none = "无经验"
    case beginner = "少量经验"
    case intermediate = "有一定经验"
    case advanced = "丰富经验"
}

/// 身体状况
enum PhysicalCondition: String, Codable, CaseIterable {
    case excellent = "优秀"
    case good = "良好"
    case normal = "一般"
    case poor = "较差"
}

/// 训练目标
enum TrainingGoal: String, Codable, CaseIterable {
    case endurance = "提升持久力"
    case control = "增强控制力"
    case recovery = "加快恢复"
    case comprehensive = "全面提升"
}

// MARK: - Review Note Model

/// 复盘笔记数据模型
struct ReviewNote: Identifiable {
    let id: UUID
    let trainingRecordId: UUID
    let date: Date
    var feelingScore: Int // 1-5
    var difficultyScore: Int // 1-5
    var bodyReaction: String
    var notes: String
    
    init(id: UUID = UUID(),
         trainingRecordId: UUID,
         date: Date = Date(),
         feelingScore: Int = 3,
         difficultyScore: Int = 3,
         bodyReaction: String = "",
         notes: String = "") {
        self.id = id
        self.trainingRecordId = trainingRecordId
        self.date = date
        self.feelingScore = feelingScore
        self.difficultyScore = difficultyScore
        self.bodyReaction = bodyReaction
        self.notes = notes
    }
}
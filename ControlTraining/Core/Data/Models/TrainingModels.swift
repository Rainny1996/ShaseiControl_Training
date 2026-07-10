import Foundation
import CoreData

// MARK: - Enums

/// 训练类别
enum TrainingCategory: String, Codable, CaseIterable {
    case kegel = "凯格尔运动"
    case stopStart = "停-动技术"
    case squeeze = "挤压技术"
    case breathing = "呼吸训练"
    case pelvicFloor = "骨盆底肌训练"
    
    var icon: String {
        switch self {
        case .kegel: return "figure.core.training"
        case .stopStart: return "pause.fill"
        case .squeeze: return "hand.press.fill"
        case .breathing: return "wind"
        case .pelvicFloor: return "figure.stand"
        }
    }
}

/// 难度等级
enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner = "初级"
    case intermediate = "中级"
    case advanced = "高级"
    
    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "orange"
        case .advanced: return "red"
        }
    }
}

/// 训练节奏模式
enum TrainingMode: String, Codable, CaseIterable {
    case basic = "基础模式"
    case progressive = "渐进模式"
    case interval = "间歇模式"
    
    var description: String {
        switch self {
        case .basic: return "等长收缩，保持稳定节奏"
        case .progressive: return "递增收缩，逐步增加强度"
        case .interval: return "收缩-放松交替，间歇训练"
        }
    }
}

/// 能力等级
enum AbilityLevel: String, Codable {
    case entry = "入门级"
    case beginner = "初级"
    case intermediate = "中级"
    case advanced = "高级"
    case expert = "专家级"
    
    init(score: Int) {
        switch score {
        case 0..<20: self = .entry
        case 20..<40: self = .beginner
        case 40..<60: self = .intermediate
        case 60..<80: self = .advanced
        default: self = .expert
        }
    }
}

// MARK: - Training Method Model

/// 训练方法数据模型
struct TrainingMethod: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: TrainingCategory
    let difficulty: DifficultyLevel
    let description: String
    let principle: String
    let steps: [TrainingStep]
    let precautions: [String]
    let expectedEffect: String
    let targetAudience: String
    let defaultDuration: TimeInterval
    var isFavorite: Bool
    let source: String?            // AC-C.2 来源标注
    let contraindication: String?  // AC-C.5 禁忌人群
    
    init(id: UUID = UUID(),
         name: String,
         category: TrainingCategory,
         difficulty: DifficultyLevel,
         description: String,
         principle: String,
         steps: [TrainingStep],
         precautions: [String],
         expectedEffect: String,
         targetAudience: String,
         defaultDuration: TimeInterval,
         isFavorite: Bool = false,
         source: String? = nil,
         contraindication: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.difficulty = difficulty
        self.description = description
        self.principle = principle
        self.steps = steps
        self.precautions = precautions
        self.expectedEffect = expectedEffect
        self.targetAudience = targetAudience
        self.defaultDuration = defaultDuration
        self.isFavorite = isFavorite
        self.source = source
        self.contraindication = contraindication
    }
}

/// 训练步骤
struct TrainingStep: Identifiable, Codable {
    let id: UUID
    let order: Int
    let title: String
    let instruction: String
    let duration: TimeInterval?
    
    init(id: UUID = UUID(),
         order: Int,
         title: String,
         instruction: String,
         duration: TimeInterval? = nil) {
        self.id = id
        self.order = order
        self.title = title
        self.instruction = instruction
        self.duration = duration
    }
}

// MARK: - Training Record Model

/// 训练记录数据模型
struct TrainingRecord: Identifiable {
    let id: UUID
    let methodId: UUID
    let date: Date
    let duration: TimeInterval
    let completionRate: Double
    let selfRating: Int
    let notes: String
    let mode: TrainingMode
    let isPartial: Bool     // AC-2.10: 强制退出生成的部分记录
    
    init(id: UUID = UUID(),
         methodId: UUID,
         date: Date = Date(),
         duration: TimeInterval,
         completionRate: Double,
         selfRating: Int = 3,
         notes: String = "",
         mode: TrainingMode = .basic,
         isPartial: Bool = false) {
        self.id = id
        self.methodId = methodId
        self.date = date
        self.duration = duration
        self.completionRate = completionRate
        self.selfRating = max(1, min(5, selfRating))
        self.notes = notes
        self.mode = mode
        self.isPartial = isPartial
    }
}

// MARK: - Check-in Record Model

/// 打卡记录数据模型
struct CheckInRecord: Identifiable {
    let id: UUID
    let date: Date
    let checkInTime: Date
    let trainingRecordId: UUID?
    
    init(id: UUID = UUID(),
         date: Date = Date(),
         checkInTime: Date = Date(),
         trainingRecordId: UUID? = nil) {
        self.id = id
        self.date = date
        self.checkInTime = checkInTime
        self.trainingRecordId = trainingRecordId
    }
}

// MARK: - Ability Profile Model

/// 能力档案数据模型
struct AbilityProfile: Identifiable {
    let id: UUID
    var overallScore: Int
    var endurance: Double
    var control: Double
    var recovery: Double
    var breathCoordination: Double
    var muscleStrength: Double
    var level: AbilityLevel
    var lastUpdated: Date
    
    init(id: UUID = UUID(),
         overallScore: Int = 0,
         endurance: Double = 0,
         control: Double = 0,
         recovery: Double = 0,
         breathCoordination: Double = 0,
         muscleStrength: Double = 0,
         lastUpdated: Date = Date()) {
        self.id = id
        self.overallScore = overallScore
        self.endurance = endurance
        self.control = control
        self.recovery = recovery
        self.breathCoordination = breathCoordination
        self.muscleStrength = muscleStrength
        self.level = AbilityLevel(score: overallScore)
        self.lastUpdated = lastUpdated
    }
    
    /// 能力维度数组（用于雷达图）
    var dimensions: [Double] {
        [endurance, control, recovery, breathCoordination, muscleStrength]
    }
    
    /// 维度名称
    static let dimensionNames = ["持久力", "控制力", "恢复力", "呼吸配合", "肌肉力量"]
}
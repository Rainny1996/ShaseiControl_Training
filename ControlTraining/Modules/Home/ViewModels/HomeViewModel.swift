import Foundation
import SwiftUI

/// 首页视图模型
class HomeViewModel: ObservableObject {
    @Published var todayPlanItems: [PlanItem] = []
    @Published var consecutiveCheckInDays: Int = 0
    @Published var todayCheckedIn: Bool = false
    @Published var abilityScore: Int = 0
    @Published var abilityLevel: AbilityLevel = .entry
    
    // 今日概览
    @Published var todayTrainingCount: Int = 0
    @Published var todayTrainingDuration: TimeInterval = 0
    @Published var weekTrainingCount: Int = 0
    @Published var totalTrainingCount: Int = 0
    
    // 能力维度
    @Published var dimensionScores: (endurance: Double, control: Double, recovery: Double, breathCoordination: Double, muscleStrength: Double) = (0, 0, 0, 0, 0)
    
    // 薄弱环节
    @Published var weakDimensions: [AbilityDimension] = []
    
    // 加载状态
    @Published var isLoading: Bool = false
    
    private let trainingRepository: TrainingRepository
    private let checkInRepository: CheckInRepository
    private let checkInService: CheckInService
    private let planRepository: PlanRepository
    private let analysisService: AnalysisService
    
    init(trainingRepository: TrainingRepository = TrainingRepository(),
         checkInRepository: CheckInRepository = CheckInRepository(),
         checkInService: CheckInService = .shared,
         planRepository: PlanRepository = PlanRepository(),
         analysisService: AnalysisService = .shared) {
        self.trainingRepository = trainingRepository
        self.checkInRepository = checkInRepository
        self.checkInService = checkInService
        self.planRepository = planRepository
        self.analysisService = analysisService
        loadData()
    }
    
    /// 加载首页数据
    func loadData() {
        isLoading = true
        loadTodayPlan()
        loadCheckInData()
        loadAbilityData()
        loadTrainingStatistics()
        isLoading = false
    }
    
    /// 刷新数据
    func refresh() {
        loadData()
    }
    
    /// 执行打卡
    func performCheckIn() {
        guard !todayCheckedIn else { return }
        
        let success = checkInService.checkIn()
        if success {
            todayCheckedIn = true
            consecutiveCheckInDays = checkInRepository.fetchConsecutiveCheckInDays()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadTodayPlan() {
        todayPlanItems = planRepository.fetchTodayPlanItems()
    }
    
    private func loadCheckInData() {
        consecutiveCheckInDays = checkInRepository.fetchConsecutiveCheckInDays()
        todayCheckedIn = checkInRepository.hasCheckedInToday()
    }
    
    private func loadAbilityData() {
        abilityScore = analysisService.calculateOverallScore()
        dimensionScores = analysisService.calculateAllDimensions()
        weakDimensions = analysisService.identifyWeaknesses()
        
        // 根据评分确定等级
        abilityLevel = AbilityLevel(score: abilityScore)
    }
    
    private func loadTrainingStatistics() {
        let calendar = Calendar.current
        let now = Date()
        
        // 今日训练统计
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let todayRecords = trainingRepository.fetchTrainingRecords(from: startOfDay, to: endOfDay)
        todayTrainingCount = todayRecords.count
        todayTrainingDuration = todayRecords.reduce(0) { $0 + $1.duration }
        
        // 本周训练统计
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let weekRecords = trainingRepository.fetchTrainingRecords(from: startOfWeek, to: now)
        weekTrainingCount = weekRecords.count
        
        // 总训练次数
        totalTrainingCount = trainingRepository.fetchTotalRecordCount()
    }
    
    // MARK: - Computed Properties
    
    /// 今日训练时长格式化
    var todayDurationText: String {
        let minutes = Int(todayTrainingDuration) / 60
        if minutes > 0 {
            return "\(minutes)分钟"
        }
        return "0分钟"
    }
    
    /// 今日完成率
    var todayCompletionRate: Double {
        guard !todayPlanItems.isEmpty else { return 0 }
        let completedCount = todayPlanItems.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(todayPlanItems.count)
    }
    
    /// 能力评分颜色
    var scoreColor: Color {
        switch abilityScore {
        case 0..<30: return .red
        case 30..<50: return .orange
        case 50..<70: return .yellow
        case 70..<85: return .green
        default: return .blue
        }
    }
    
    /// 问候语
    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "早上好"
        case 12..<14: return "中午好"
        case 14..<18: return "下午好"
        case 18..<22: return "晚上好"
        default: return "夜深了"
        }
    }
    
    /// 鼓励语
    var encouragementText: String {
        if todayCheckedIn && todayTrainingCount > 0 {
            return "今天已完成训练，继续保持！"
        } else if todayCheckedIn {
            return "已打卡，别忘了完成今日训练哦！"
        } else if todayTrainingCount > 0 {
            return "训练已完成，记得打卡记录！"
        } else if !todayPlanItems.isEmpty {
            return "今天有\(todayPlanItems.count)项训练任务等你完成"
        } else {
            return "开始今天的训练吧！"
        }
    }
}
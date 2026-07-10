import Foundation
import SwiftUI

/// 复盘视图模型 - 管理复盘数据和状态
class ReviewViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 历史训练记录列表
    @Published var trainingRecords: [TrainingRecord] = []
    /// 复盘笔记列表
    @Published var reviewNotes: [ReviewNote] = []
    /// 训练频率趋势
    @Published var weeklyFrequency: [WeeklyFrequency] = []
    /// 能力变化趋势
    @Published var abilityTrend: [WeeklyScore] = []
    /// 周复盘报告
    @Published var weeklyReport: ReviewReport?
    /// 月复盘报告
    @Published var monthlyReport: ReviewReport?
    /// 是否正在加载
    @Published var isLoading: Bool = false
    /// 选中的报告周期
    @Published var selectedReportPeriod: ReportPeriod = .weekly
    /// 当前显示的报告
    @Published var currentReport: ReviewReport?
    
    // MARK: - Dependencies
    
    private let reviewService: ReviewService
    private let reviewNoteRepository: ReviewNoteRepository
    private let trainingRepository: TrainingRepository
    
    init(reviewService: ReviewService = .shared,
         reviewNoteRepository: ReviewNoteRepository = ReviewNoteRepository(),
         trainingRepository: TrainingRepository = TrainingRepository()) {
        self.reviewService = reviewService
        self.reviewNoteRepository = reviewNoteRepository
        self.trainingRepository = trainingRepository
    }
    
    // MARK: - 数据加载
    
    /// 加载全部复盘数据
    func loadData() {
        isLoading = true
        
        // 加载训练记录
        loadTrainingRecords()
        
        // 加载复盘笔记
        loadReviewNotes()
        
        // 加载趋势数据
        loadTrendData()
        
        // 加载报告
        loadReports()
        
        isLoading = false
    }
    
    /// 加载训练记录
    func loadTrainingRecords() {
        trainingRecords = reviewService.fetchAllTrainingRecords()
    }
    
    /// 加载复盘笔记
    func loadReviewNotes() {
        reviewNotes = reviewNoteRepository.fetchAllReviewNotes()
    }
    
    /// 加载趋势数据
    func loadTrendData() {
        weeklyFrequency = reviewService.fetchWeeklyFrequencyTrend(weeks: 12)
        abilityTrend = reviewService.fetchAbilityTrend(weeks: 12)
    }
    
    /// 加载报告
    func loadReports() {
        weeklyReport = reviewService.generateWeeklyReport()
        monthlyReport = reviewService.generateMonthlyReport()
        updateCurrentReport()
    }
    
    /// 切换报告周期
    func switchReportPeriod(_ period: ReportPeriod) {
        selectedReportPeriod = period
        updateCurrentReport()
    }
    
    /// 更新当前显示的报告
    private func updateCurrentReport() {
        switch selectedReportPeriod {
        case .weekly: currentReport = weeklyReport
        case .monthly: currentReport = monthlyReport
        }
    }
    
    // MARK: - 复盘笔记操作
    
    /// 保存复盘笔记
    /// - Parameter note: 复盘笔记
    func saveReviewNote(_ note: ReviewNote) {
        reviewService.saveReviewNote(note)
        loadReviewNotes()
    }
    
    /// 更新复盘笔记
    /// - Parameter note: 复盘笔记
    func updateReviewNote(_ note: ReviewNote) {
        reviewService.updateReviewNote(note)
        loadReviewNotes()
    }
    
    /// 获取指定训练记录的复盘笔记
    /// - Parameter trainingRecordId: 训练记录ID
    /// - Returns: 复盘笔记
    func getReviewNote(for trainingRecordId: UUID) -> ReviewNote? {
        reviewService.fetchReviewNote(for: trainingRecordId)
    }
    
    // MARK: - 数据格式化
    
    /// 格式化训练时长
    /// - Parameter duration: 时长（秒）
    /// - Returns: 格式化字符串
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        }
        return "\(seconds)秒"
    }
    
    /// 格式化日期
    /// - Parameter date: 日期
    /// - Returns: 格式化字符串
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
    
    /// 格式化完成度
    /// - Parameter rate: 完成率（0-1）
    /// - Returns: 格式化字符串
    func formatCompletionRate(_ rate: Double) -> String {
        "\(Int(rate * 100))%"
    }
    
    /// 获取训练方法名称
    /// - Parameter methodId: 方法ID
    /// - Returns: 方法名称
    func getMethodName(for methodId: UUID) -> String {
        let methods = trainingRepository.fetchAllTrainingMethods()
        return methods.first { $0.id == methodId }?.name ?? "未知训练"
    }
    
    /// 获取训练方法分类
    /// - Parameter methodId: 方法ID
    /// - Returns: 分类名称
    func getMethodCategory(for methodId: UUID) -> String {
        let methods = trainingRepository.fetchAllTrainingMethods()
        return methods.first { $0.id == methodId }?.category.rawValue ?? ""
    }
    
    // MARK: - 统计数据
    
    /// 总训练次数
    var totalTrainingCount: Int {
        trainingRecords.count
    }
    
    /// 总训练时长
    var totalTrainingDuration: TimeInterval {
        trainingRecords.map { $0.duration }.reduce(0, +)
    }
    
    /// 平均完成度
    var averageCompletion: Double {
        guard !trainingRecords.isEmpty else { return 0 }
        return trainingRecords.map { $0.completionRate }.reduce(0, +) / Double(trainingRecords.count)
    }
    
    /// 平均自评
    var averageRating: Double {
        guard !trainingRecords.isEmpty else { return 0 }
        return Double(trainingRecords.map { $0.selfRating }.reduce(0, +)) / Double(trainingRecords.count)
    }
}
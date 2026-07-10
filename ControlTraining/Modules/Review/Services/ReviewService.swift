import Foundation

/// 复盘服务 - 负责复盘业务逻辑、报告生成和数据分析
class ReviewService {
    
    static let shared = ReviewService()
    
    private let reviewNoteRepository: ReviewNoteRepository
    private let trainingRepository: TrainingRepository
    
    init(reviewNoteRepository: ReviewNoteRepository = ReviewNoteRepository(),
         trainingRepository: TrainingRepository = TrainingRepository()) {
        self.reviewNoteRepository = reviewNoteRepository
        self.trainingRepository = trainingRepository
    }
    
    // MARK: - 复盘笔记操作
    
    /// 保存复盘笔记
    /// - Parameter note: 复盘笔记
    func saveReviewNote(_ note: ReviewNote) {
        reviewNoteRepository.saveReviewNote(note)
    }
    
    /// 更新复盘笔记
    /// - Parameter note: 复盘笔记
    func updateReviewNote(_ note: ReviewNote) {
        reviewNoteRepository.updateReviewNote(note)
    }
    
    /// 获取指定训练记录的复盘笔记
    /// - Parameter trainingRecordId: 训练记录ID
    /// - Returns: 复盘笔记
    func fetchReviewNote(for trainingRecordId: UUID) -> ReviewNote? {
        reviewNoteRepository.fetchReviewNote(for: trainingRecordId)
    }
    
    /// 获取指定日期范围的复盘笔记
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 复盘笔记列表
    func fetchReviewNotes(from startDate: Date, to endDate: Date) -> [ReviewNote] {
        reviewNoteRepository.fetchReviewNotes(from: startDate, to: endDate)
    }
    
    // MARK: - 训练记录查询
    
    /// 获取指定日期范围的训练记录
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 训练记录列表
    func fetchTrainingRecords(from startDate: Date, to endDate: Date) -> [TrainingRecord] {
        trainingRepository.fetchTrainingRecords(from: startDate, to: endDate)
    }
    
    /// 获取所有训练记录
    /// - Returns: 训练记录列表
    func fetchAllTrainingRecords() -> [TrainingRecord] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        return trainingRepository.fetchTrainingRecords(from: startDate, to: Date())
    }
    
    // MARK: - 趋势数据计算
    
    /// 获取训练频率趋势数据（按周统计）
    /// - Parameter weeks: 周数
    /// - Returns: 每周训练次数数据
    func fetchWeeklyFrequencyTrend(weeks: Int = 12) -> [WeeklyFrequency] {
        let calendar = Calendar.current
        var trend: [WeeklyFrequency] = []
        
        for weekOffset in (0..<weeks).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: Date()) else { continue }
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? Date()
            
            let records = trainingRepository.fetchTrainingRecords(from: weekStart, to: weekEnd)
            let weekLabel = formatWeekLabel(weekStart)
            
            trend.append(WeeklyFrequency(
                weekStart: weekStart,
                weekEnd: weekEnd,
                label: weekLabel,
                count: records.count,
                totalDuration: records.map { $0.duration }.reduce(0, +)
            ))
        }
        
        return trend
    }
    
    /// 获取能力变化趋势数据（按周统计自评分数）
    /// - Parameter weeks: 周数
    /// - Returns: 每周平均评分数据
    func fetchAbilityTrend(weeks: Int = 12) -> [WeeklyScore] {
        let calendar = Calendar.current
        var trend: [WeeklyScore] = []
        
        for weekOffset in (0..<weeks).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: Date()) else { continue }
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? Date()
            
            let records = trainingRepository.fetchTrainingRecords(from: weekStart, to: weekEnd)
            let weekLabel = formatWeekLabel(weekStart)
            
            let avgRating = records.isEmpty ? 0 :
                Double(records.map { $0.selfRating }.reduce(0, +)) / Double(records.count)
            let avgCompletion = records.isEmpty ? 0 :
                records.map { $0.completionRate }.reduce(0, +) / Double(records.count)
            
            trend.append(WeeklyScore(
                weekStart: weekStart,
                label: weekLabel,
                averageRating: avgRating,
                averageCompletion: avgCompletion,
                trainingCount: records.count
            ))
        }
        
        return trend
    }
    
    // MARK: - 报告生成
    
    /// 生成周复盘报告
    /// - Parameter date: 报告日期（默认本周）
    /// - Returns: 周复盘报告
    func generateWeeklyReport(for date: Date = Date()) -> ReviewReport {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        
        let records = trainingRepository.fetchTrainingRecords(from: weekStart, to: weekEnd)
        let reviewStats = reviewNoteRepository.fetchReviewStatistics(from: weekStart, to: weekEnd)
        
        return generateReport(
            startDate: weekStart,
            endDate: weekEnd,
            period: .weekly,
            records: records,
            reviewStats: reviewStats
        )
    }
    
    /// 生成月复盘报告
    /// - Parameter date: 报告日期（默认本月）
    /// - Returns: 月复盘报告
    func generateMonthlyReport(for date: Date = Date()) -> ReviewReport {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        let monthStart = calendar.date(from: components)!
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
        
        let records = trainingRepository.fetchTrainingRecords(from: monthStart, to: monthEnd)
        let reviewStats = reviewNoteRepository.fetchReviewStatistics(from: monthStart, to: monthEnd)
        
        return generateReport(
            startDate: monthStart,
            endDate: monthEnd,
            period: .monthly,
            records: records,
            reviewStats: reviewStats
        )
    }
    
    /// 生成复盘报告（核心方法）
    private func generateReport(
        startDate: Date,
        endDate: Date,
        period: ReportPeriod,
        records: [TrainingRecord],
        reviewStats: ReviewStatistics
    ) -> ReviewReport {
        // 训练总结
        let totalSessions = records.count
        let totalDuration = records.map { $0.duration }.reduce(0, +)
        let averageCompletion = records.isEmpty ? 0 :
            records.map { $0.completionRate }.reduce(0, +) / Double(records.count)
        let averageRating = records.isEmpty ? 0 :
            Double(records.map { $0.selfRating }.reduce(0, +)) / Double(records.count)
        
        // 训练类型分布
        let categoryDistributionRaw = Dictionary(grouping: records) { $0.methodId }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        let categoryDistribution = Dictionary(uniqueKeysWithValues: categoryDistributionRaw)
        
        // 进步亮点
        let highlights = generateHighlights(records: records, reviewStats: reviewStats)
        
        // 待改进项
        let improvements = generateImprovements(records: records, reviewStats: reviewStats)
        
        // 下期建议
        let suggestions = generateSuggestions(records: records, reviewStats: reviewStats, period: period)
        
        return ReviewReport(
            id: UUID(),
            startDate: startDate,
            endDate: endDate,
            period: period,
            totalSessions: totalSessions,
            totalDuration: totalDuration,
            averageCompletion: averageCompletion,
            averageRating: averageRating,
            averageFeelingScore: reviewStats.averageFeelingScore,
            averageDifficultyScore: reviewStats.averageDifficultyScore,
            categoryDistribution: categoryDistribution,
            highlights: highlights,
            improvements: improvements,
            suggestions: suggestions,
            commonBodyReactions: reviewStats.commonBodyReactions
        )
    }
    
    // MARK: - 报告内容生成
    
    /// 生成进步亮点
    private func generateHighlights(records: [TrainingRecord], reviewStats: ReviewStatistics) -> [String] {
        var highlights: [String] = []
        
        // 训练频率亮点
        if records.count >= 5 {
            highlights.append("本周坚持训练\(records.count)次，训练频率稳定")
        }
        
        // 完成度亮点
        let avgCompletion = records.isEmpty ? 0 : records.map { $0.completionRate }.reduce(0, +) / Double(records.count)
        if avgCompletion >= 0.8 {
            highlights.append("平均完成度\(Int(avgCompletion * 100))%，训练质量很高")
        }
        
        // 自评亮点
        if reviewStats.averageFeelingScore >= 4.0 {
            highlights.append("训练感受良好，平均感受评分\(String(format: "%.1f", reviewStats.averageFeelingScore))")
        }
        
        // 高完成率训练
        let highCompletionCount = records.filter { $0.completionRate >= 0.9 }.count
        if highCompletionCount >= 3 {
            highlights.append("\(highCompletionCount)次训练完成度超过90%，表现出色")
        }
        
        if highlights.isEmpty {
            highlights.append("已完成本周训练计划，继续保持")
        }
        
        return highlights
    }
    
    /// 生成待改进项
    private func generateImprovements(records: [TrainingRecord], reviewStats: ReviewStatistics) -> [String] {
        var improvements: [String] = []
        
        // 训练频率不足
        if records.count < 3 {
            improvements.append("训练频率偏低，建议增加至每周3次以上")
        }
        
        // 完成度不足
        let avgCompletion = records.isEmpty ? 0 : records.map { $0.completionRate }.reduce(0, +) / Double(records.count)
        if avgCompletion < 0.6 && !records.isEmpty {
            improvements.append("平均完成度仅\(Int(avgCompletion * 100))%，建议降低训练强度或时长")
        }
        
        // 难度偏高
        if reviewStats.averageDifficultyScore >= 4.0 {
            improvements.append("训练难度偏高，建议适当降低强度循序渐进")
        }
        
        // 感受偏低
        if reviewStats.averageFeelingScore <= 2.0 && !records.isEmpty {
            improvements.append("训练感受评分较低，注意身体信号，避免过度训练")
        }
        
        if improvements.isEmpty {
            improvements.append("整体表现良好，可以适当增加训练挑战")
        }
        
        return improvements
    }
    
    /// 生成下期建议
    private func generateSuggestions(records: [TrainingRecord], reviewStats: ReviewStatistics, period: ReportPeriod) -> [String] {
        var suggestions: [String] = []
        
        let periodText = period == .weekly ? "下周" : "下月"
        
        // 频率建议
        if records.count < 3 {
            suggestions.append("\(periodText)建议保持每周至少3次训练频率")
        } else {
            suggestions.append("\(periodText)继续保持当前训练频率")
        }
        
        // 难度建议
        if reviewStats.averageDifficultyScore >= 4.0 {
            suggestions.append("建议\(periodText)适当降低训练难度，先巩固基础")
        } else if reviewStats.averageDifficultyScore <= 2.0 {
            suggestions.append("可以尝试\(periodText)增加训练难度，挑战更高水平")
        }
        
        // 时长建议
        let avgDuration = records.isEmpty ? 0 : records.map { $0.duration }.reduce(0, +) / Double(records.count)
        if avgDuration < 300 { // 5分钟
            suggestions.append("建议\(periodText)适当延长单次训练时长至5分钟以上")
        }
        
        // 休息建议
        suggestions.append("训练后注意充分休息，保证恢复时间")
        
        return suggestions
    }
    
    // MARK: - 辅助方法
    
    /// 格式化周标签
    private func formatWeekLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - 数据模型

/// 报告周期
enum ReportPeriod: String, Codable {
    case weekly = "周报"
    case monthly = "月报"
}

/// 每周训练频率
struct WeeklyFrequency: Identifiable {
    let id = UUID()
    let weekStart: Date
    let weekEnd: Date
    let label: String
    let count: Int
    let totalDuration: TimeInterval
}

/// 每周评分趋势
struct WeeklyScore: Identifiable {
    let id = UUID()
    let weekStart: Date
    let label: String
    let averageRating: Double
    let averageCompletion: Double
    let trainingCount: Int
}

/// 复盘报告
struct ReviewReport: Identifiable {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let period: ReportPeriod
    let totalSessions: Int
    let totalDuration: TimeInterval
    let averageCompletion: Double
    let averageRating: Double
    let averageFeelingScore: Double
    let averageDifficultyScore: Double
    let categoryDistribution: [UUID: Int]
    let highlights: [String]
    let improvements: [String]
    let suggestions: [String]
    let commonBodyReactions: [String]
    
    /// 格式化总时长
    var totalDurationDisplay: String {
        let hours = Int(totalDuration) / 3600
        let minutes = Int(totalDuration) % 3600 / 60
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        }
        return "\(minutes)分钟"
    }
    
    /// 格式化完成度
    var completionDisplay: String {
        "\(Int(averageCompletion * 100))%"
    }
    
    /// 格式化评分
    var ratingDisplay: String {
        String(format: "%.1f", averageRating)
    }
    
    /// 日期范围显示
    var dateRangeDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}
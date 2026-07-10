import Foundation

/// 打卡服务 - 负责打卡业务逻辑、成就计算和补签管理
class CheckInService {
    
    static let shared = CheckInService()
    
    private let checkInRepository: CheckInRepository
    private let notificationService: NotificationService
    
    private init(checkInRepository: CheckInRepository = CheckInRepository(),
                 notificationService: NotificationService = .shared) {
        self.checkInRepository = checkInRepository
        self.notificationService = notificationService
    }
    
    // MARK: - 打卡操作
    
    /// 执行打卡
    /// - Parameter trainingRecordId: 关联的训练记录ID（可选）
    /// - Returns: 打卡是否成功
    @discardableResult
    func checkIn(trainingRecordId: UUID? = nil) -> Bool {
        // 检查今天是否已打卡
        guard !checkInRepository.hasCheckedInToday() else { return false }
        
        // 创建打卡记录
        let record = CheckInRecord(
            date: Date(),
            checkInTime: Date(),
            trainingRecordId: trainingRecordId
        )
        checkInRepository.saveCheckInRecord(record)
        
        // 检查成就并发送通知
        checkAndNotifyAchievements()
        
        return true
    }
    
    /// 补签
    /// - Parameter date: 补签日期
    /// - Returns: 补签结果
    func makeUpCheckIn(for date: Date) -> MakeUpCheckInResult {
        // 检查本月补签次数
        let monthlyMakeUpCount = fetchMonthlyMakeUpCount()
        let maxMakeUpPerMonth = 3
        
        guard monthlyMakeUpCount < maxMakeUpPerMonth else {
            return .failure("本月补签次数已达上限（\(maxMakeUpPerMonth)次）")
        }
        
        // 执行补签
        let success = checkInRepository.makeUpCheckIn(for: date)
        if success {
            // 记录补签次数
            incrementMonthlyMakeUpCount()
            
            // 检查成就
            checkAndNotifyAchievements()
            
            return .success
        } else {
            return .failure("补签失败，请检查日期是否有效")
        }
    }
    
    // MARK: - 打卡统计
    
    /// 获取打卡统计数据
    /// - Returns: 打卡统计
    func fetchCheckInStatistics() -> CheckInStatistics {
        let consecutiveDays = checkInRepository.fetchConsecutiveCheckInDays()
        let totalDays = checkInRepository.fetchTotalCheckInDays()
        let monthlyRate = calculateMonthlyCheckInRate()
        let monthlyMakeUpCount = fetchMonthlyMakeUpCount()
        
        return CheckInStatistics(
            consecutiveDays: consecutiveDays,
            totalDays: totalDays,
            monthlyCheckInRate: monthlyRate,
            monthlyMakeUpCount: monthlyMakeUpCount,
            maxMakeUpPerMonth: 3
        )
    }
    
    /// 计算本月打卡率
    /// - Returns: 打卡率（0-1）
    func calculateMonthlyCheckInRate() -> Double {
        let calendar = Calendar.current
        let today = Date()
        
        // 获取本月已过天数
        let dayOfMonth = calendar.component(.day, from: today)
        
        // 获取本月打卡日期
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)
        let checkInDates = checkInRepository.fetchCheckInDatesForMonth(year: year, month: month)
        
        // 计算打卡率
        guard dayOfMonth > 0 else { return 0 }
        return Double(checkInDates.count) / Double(dayOfMonth)
    }
    
    /// 获取本月打卡天数
    /// - Returns: 本月打卡天数
    func fetchMonthlyCheckInDays() -> Int {
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let month = calendar.component(.month, from: today)
        return checkInRepository.fetchCheckInDatesForMonth(year: year, month: month).count
    }
    
    /// 获取本周打卡天数
    /// - Returns: 本周打卡天数
    func fetchWeeklyCheckInDays() -> Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        let records = checkInRepository.fetchCheckInRecords(from: startOfWeek, to: endOfWeek)
        return records.count
    }
    
    // MARK: - 成就系统
    
    /// 检查并发送成就通知
    private func checkAndNotifyAchievements() {
        let consecutiveDays = checkInRepository.fetchConsecutiveCheckInDays()
        let totalDays = checkInRepository.fetchTotalCheckInDays()
        
        // 连续打卡成就
        checkStreakAchievement(consecutiveDays)
        
        // 总打卡里程碑
        checkTotalDaysAchievement(totalDays)
    }
    
    /// 检查连续打卡成就
    private func checkStreakAchievement(_ days: Int) {
        let milestones = [3, 7, 14, 30, 60, 100]
        if milestones.contains(days) {
            let title = "连续\(days)天打卡！"
            let messages: [Int: String] = [
                3: "连续3天打卡，好习惯正在养成！",
                7: "坚持一周了，你真棒！",
                14: "两周连续打卡，毅力令人敬佩！",
                30: "一个月连续打卡，你已经脱胎换骨！",
                60: "两个月连续打卡，你是训练达人！",
                100: "百日连续打卡，传奇！"
            ]
            if let message = messages[days] {
                notificationService.sendAchievementNotification(title: title, body: message)
            }
        }
    }
    
    /// 检查总打卡天数里程碑
    private func checkTotalDaysAchievement(_ days: Int) {
        let milestones = [10, 30, 50, 100, 200, 365]
        if milestones.contains(days) {
            let title = "累计打卡\(days)天！"
            let messages: [Int: String] = [
                10: "10天打卡，良好的开始！",
                30: "30天打卡，一个月的坚持！",
                50: "50天打卡，半百里程！",
                100: "100天打卡，百尺竿头！",
                200: "200天打卡，训练已成为习惯！",
                365: "365天打卡，一年的坚持！"
            ]
            if let message = messages[days] {
                notificationService.sendAchievementNotification(title: title, body: message)
            }
        }
    }
    
    /// 获取已解锁的成就列表
    /// - Returns: 成就列表
    func fetchAchievements() -> [CheckInAchievement] {
        let consecutiveDays = checkInRepository.fetchConsecutiveCheckInDays()
        let totalDays = checkInRepository.fetchTotalCheckInDays()
        
        return CheckInAchievement.allAchievements.map { achievement in
            let currentValue: Int
            switch achievement.type {
            case .streak: currentValue = consecutiveDays
            case .total: currentValue = totalDays
            }
            
            var unlocked = false
            if currentValue >= achievement.requiredValue {
                unlocked = true
            }
            
            return CheckInAchievement(
                id: achievement.id,
                type: achievement.type,
                title: achievement.title,
                description: achievement.description,
                icon: achievement.icon,
                requiredValue: achievement.requiredValue,
                currentValue: currentValue,
                isUnlocked: unlocked
            )
        }
    }
    
    // MARK: - 补签管理
    
    /// 获取本月补签次数
    private func fetchMonthlyMakeUpCount() -> Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let month = calendar.component(.month, from: Date())
        let key = "makeUpCount_\(year)_\(month)"
        return UserDefaults.standard.integer(forKey: key)
    }
    
    /// 增加本月补签次数
    private func incrementMonthlyMakeUpCount() {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let month = calendar.component(.month, from: Date())
        let key = "makeUpCount_\(year)_\(month)"
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)
    }
    
    /// 获取可补签日期列表（过去7天内未打卡的日期）
    /// - Returns: 可补签日期列表
    func fetchMakeUpDates() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var makeUpDates: [Date] = []
        
        // 检查过去7天（不含今天）
        for dayOffset in 1...7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // 只允许补签3天内的日期
            if dayOffset > 3 { break }
            
            // 检查是否已打卡
            if checkInRepository.fetchCheckInRecord(for: date) == nil {
                makeUpDates.append(date)
            }
        }
        
        return makeUpDates
    }
    
    // MARK: - 鼓励语
    
    /// 获取随机鼓励语
    /// - Returns: 鼓励语
    func getEncouragement() -> String {
        let encouragements = [
            "坚持就是胜利！",
            "每一天的进步都值得庆祝！",
            "你正在变得更强！",
            "好习惯成就好结果！",
            "今天的努力是明天的收获！",
            "保持节奏，稳步前进！",
            "自律者自由！",
            "每一次打卡都是对自己的承诺！",
            "你比昨天的自己更优秀！",
            "持续训练，见证改变！"
        ]
        return encouragements.randomElement() ?? encouragements[0]
    }
    
    /// 根据连续天数获取鼓励语
    /// - Parameter streak: 连续天数
    /// - Returns: 鼓励语
    func getEncouragement(forStreak streak: Int) -> String {
        if streak == 0 {
            return "开始你的第一天打卡吧！"
        } else if streak < 3 {
            return "好的开始是成功的一半！"
        } else if streak < 7 {
            return "坚持\(streak)天了，继续保持！"
        } else if streak < 14 {
            return "连续\(streak)天，习惯正在养成！"
        } else if streak < 30 {
            return "连续\(streak)天，你的毅力令人敬佩！"
        } else if streak < 100 {
            return "连续\(streak)天，你已经是训练达人！"
        } else {
            return "连续\(streak)天，传奇！"
        }
    }
}

// MARK: - 补签结果枚举

enum MakeUpCheckInResult {
    case success
    case failure(String)
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .failure(let message) = self { return message }
        return nil
    }
}

// MARK: - 打卡统计数据

struct CheckInStatistics {
    let consecutiveDays: Int
    let totalDays: Int
    let monthlyCheckInRate: Double
    let monthlyMakeUpCount: Int
    let maxMakeUpPerMonth: Int
    
    /// 本月打卡率百分比
    var monthlyCheckInRatePercent: Int {
        Int(monthlyCheckInRate * 100)
    }
    
    /// 是否还有补签次数
    var canMakeUp: Bool {
        monthlyMakeUpCount < maxMakeUpPerMonth
    }
    
    /// 剩余补签次数
    var remainingMakeUpCount: Int {
        maxMakeUpPerMonth - monthlyMakeUpCount
    }
}

// MARK: - 打卡成就

struct CheckInAchievement: Identifiable {
    let id: UUID
    let type: AchievementType
    let title: String
    let description: String
    let icon: String
    let requiredValue: Int
    let currentValue: Int
    let isUnlocked: Bool
    
    /// 进度百分比
    var progress: Double {
        guard requiredValue > 0 else { return 1.0 }
        return min(Double(currentValue) / Double(requiredValue), 1.0)
    }
    
    enum AchievementType {
        case streak  // 连续打卡
        case total   // 累计打卡
    }
    
    /// 所有成就定义
    static let allAchievements: [CheckInAchievement] = [
        // 连续打卡成就
        CheckInAchievement(id: UUID(), type: .streak, title: "初露锋芒", description: "连续打卡3天", icon: "flame", requiredValue: 3, currentValue: 0, isUnlocked: false),
        CheckInAchievement(id: UUID(), type: .streak, title: "坚持不懈", description: "连续打卡7天", icon: "flame.fill", requiredValue: 7, currentValue: 0, isUnlocked: false),
        CheckInAchievement(id: UUID(), type: .streak, title: "习惯养成", description: "连续打卡14天", icon: "star", requiredValue: 14, currentValue: 0, isUnlocked: false),
        CheckInAchievement(id: UUID(), type: .streak, title: "月度达人", description: "连续打卡30天", icon: "star.fill", requiredValue: 30, currentValue: 0, isUnlocked: false),
        CheckInAchievement(id: UUID(), type: .streak, title: "双月传奇", description: "连续打卡60天", icon: "crown", requiredValue: 60, currentValue: 0, isUnlocked: false),
        CheckInAchievement(id: UUID(), type: .streak, title: "百日征途", description: "连续打卡100天", icon: "crown.fill", requiredValue: 100, currentValue: 0, isUnlocked: false),
        // 累计打卡成就
        CheckInAchievement(id: UUID(), type: .total, title: "起步之路", description: "累计打卡10天", icon: "figure.walk", requiredValue: 10, currentValue: 0, isUnlocked: false),
        CheckInAchievement(id: UUID(), type: .total, title: "稳步前行", description: "累计打卡30天", icon: "figure.run", requiredValue: 30, currentValue: 0, isUnlocked: false),
        CheckInAchievement(id: UUID(), type: .total, title: "半百里程", description: "累计打卡50天", icon: "trophy", requiredValue: 50, currentValue: 0, isUnlocked: false),
        CheckInAchievement(id: UUID(), type: .total, title: "百尺竿头", description: "累计打卡100天", icon: "trophy.fill", requiredValue: 100, currentValue: 0, isUnlocked: false),
        CheckInAchievement(id: UUID(), type: .total, title: "双百突破", description: "累计打卡200天", icon: "medal", requiredValue: 200, currentValue: 0, isUnlocked: false),
        CheckInAchievement(id: UUID(), type: .total, title: "年度坚持", description: "累计打卡365天", icon: "medal.fill", requiredValue: 365, currentValue: 0, isUnlocked: false),
    ]
}
import Foundation
import SwiftUI

/// 打卡视图模型 - 管理打卡状态和业务逻辑
class CheckInViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 今日是否已打卡
    @Published var todayCheckedIn: Bool = false
    /// 打卡统计数据
    @Published var statistics: CheckInStatistics?
    /// 连续打卡天数
    @Published var consecutiveDays: Int = 0
    /// 本月打卡日期集合
    @Published var checkedInDates: Set<Date> = []
    /// 当前显示月份
    @Published var displayedMonth: Date = Date()
    /// 成就列表
    @Published var achievements: [CheckInAchievement] = []
    /// 可补签日期
    @Published var makeUpDates: [Date] = []
    /// 是否显示打卡成功动画
    @Published var showCheckInAnimation: Bool = false
    /// 打卡成功鼓励语
    @Published var encouragement: String = ""
    /// 是否显示补签弹窗
    @Published var showMakeUpSheet: Bool = false
    /// 补签结果提示
    @Published var makeUpResult: MakeUpCheckInResult?
    /// 是否正在加载
    @Published var isLoading: Bool = false
    
    // MARK: - Dependencies
    
    private let checkInService: CheckInService
    private let checkInRepository: CheckInRepository
    
    init(checkInService: CheckInService = .shared,
         checkInRepository: CheckInRepository = CheckInRepository()) {
        self.checkInService = checkInService
        self.checkInRepository = checkInRepository
    }
    
    // MARK: - 数据加载
    
    /// 加载打卡数据
    func loadData() {
        isLoading = true
        
        // 加载今日打卡状态
        todayCheckedIn = checkInRepository.hasCheckedInToday()
        
        // 加载连续打卡天数
        consecutiveDays = checkInRepository.fetchConsecutiveCheckInDays()
        
        // 加载统计数据
        statistics = checkInService.fetchCheckInStatistics()
        
        // 加载当前月份打卡日历
        loadCalendarData()
        
        // 加载成就
        achievements = checkInService.fetchAchievements()
        
        // 加载可补签日期
        loadMakeUpDates()
        
        // 加载鼓励语
        encouragement = checkInService.getEncouragement(forStreak: consecutiveDays)
        
        isLoading = false
    }
    
    /// 加载日历数据
    func loadCalendarData() {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: displayedMonth)
        let month = calendar.component(.month, from: displayedMonth)
        checkedInDates = checkInRepository.fetchCheckInDatesForMonth(year: year, month: month)
    }
    
    /// 加载可补签日期
    func loadMakeUpDates() {
        makeUpDates = checkInService.fetchMakeUpDates()
    }
    
    /// 切换月份
    /// - Parameter direction: 方向（-1上月，1下月）
    func changeMonth(_ direction: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: direction, to: displayedMonth) {
            displayedMonth = newMonth
            loadCalendarData()
        }
    }
    
    // MARK: - 打卡操作
    
    /// 执行打卡
    func performCheckIn() {
        guard !todayCheckedIn else { return }
        
        let success = checkInService.checkIn()
        if success {
            todayCheckedIn = true
            
            // 更新连续天数
            consecutiveDays = checkInRepository.fetchConsecutiveCheckInDays()
            
            // 更新统计数据
            statistics = checkInService.fetchCheckInStatistics()
            
            // 更新日历
            loadCalendarData()
            
            // 更新成就
            achievements = checkInService.fetchAchievements()
            
            // 更新鼓励语
            encouragement = checkInService.getEncouragement(forStreak: consecutiveDays)
            
            // 显示打卡动画
            showCheckInAnimation = true
            
            // 更新可补签日期
            loadMakeUpDates()
        }
    }
    
    /// 执行补签
    /// - Parameter date: 补签日期
    func performMakeUpCheckIn(for date: Date) {
        let result = checkInService.makeUpCheckIn(for: date)
        makeUpResult = result
        
        if result.isSuccess {
            // 更新统计数据
            statistics = checkInService.fetchCheckInStatistics()
            
            // 更新日历
            loadCalendarData()
            
            // 更新成就
            achievements = checkInService.fetchAchievements()
            
            // 更新连续天数
            consecutiveDays = checkInRepository.fetchConsecutiveCheckInDays()
            encouragement = checkInService.getEncouragement(forStreak: consecutiveDays)
            
            // 更新可补签日期
            loadMakeUpDates()
            
            // 显示打卡动画
            showCheckInAnimation = true
        }
    }
    
    /// 隐藏打卡动画
    func hideCheckInAnimation() {
        showCheckInAnimation = false
    }
    
    /// 清除补签结果
    func clearMakeUpResult() {
        makeUpResult = nil
    }
    
    // MARK: - 日历辅助方法
    
    /// 获取指定月份的天数
    var daysInMonth: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)
        return range?.count ?? 30
    }
    
    /// 获取月份第一天是星期几（0=周日，1=周一...）
    var firstWeekdayOfMonth: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstDay = calendar.date(from: components) else { return 0 }
        return calendar.component(.weekday, from: firstDay)
    }
    
    /// 获取月份标题
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: displayedMonth)
    }
    
    /// 判断指定日期是否已打卡
    /// - Parameter date: 日期
    /// - Returns: 是否已打卡
    func isCheckedIn(date: Date) -> Bool {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return checkedInDates.contains(startOfDay)
    }
    
    /// 判断指定日期是否是今天
    /// - Parameter date: 日期
    /// - Returns: 是否是今天
    func isToday(date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    /// 判断指定日期是否在未来
    /// - Parameter date: 日期
    /// - Returns: 是否在未来
    func isFuture(date: Date) -> Bool {
        date > Date()
    }
    
    /// 获取指定日期的星期几名称
    /// - Parameter date: 日期
    /// - Returns: 星期几名称
    func weekdayName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    /// 格式化日期为补签显示
    /// - Parameter date: 日期
    /// - Returns: 格式化字符串
    func formatDateForMakeUp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEE"
        return formatter.string(from: date)
    }
    
    // MARK: - 成就辅助
    
    /// 已解锁成就数量
    var unlockedAchievementCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    /// 连续打卡成就
    var streakAchievements: [CheckInAchievement] {
        achievements.filter { $0.type == .streak }
    }
    
    /// 累计打卡成就
    var totalAchievements: [CheckInAchievement] {
        achievements.filter { $0.type == .total }
    }
}
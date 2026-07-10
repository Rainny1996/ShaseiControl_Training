import Foundation
import UserNotifications
import UIKit

/// 通知服务，负责本地通知管理
class NotificationService {
    static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    
    // 训练提醒消息模板
    private let trainingReminderMessages = [
        "是时候进行今日训练了，坚持就是胜利！",
        "今天的训练计划已准备好，开始吧！",
        "保持节奏，每天进步一点点！",
        "训练时间到了，你准备好了吗？",
        "坚持训练，你会看到改变的！",
        "今天的努力是明天的收获！",
        "专注当下，完成今日训练目标！"
    ]
    
    // 激励消息模板
    private let motivationalMessages = [
        "你已经连续训练多天了，继续保持！",
        "每一次训练都是对自己的投资！",
        "进步不在于速度，而在于坚持！",
        "你比昨天的自己更强了！",
        "训练的汗水不会白流！"
    ]
    
    private init() {}
    
    // MARK: - Authorization
    
    /// 请求通知授权
    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            UserDefaults.standard.set(granted, forKey: "notificationEnabled")
        }
    }
    
    /// 检查通知授权状态
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            completion(settings.authorizationStatus == .authorized)
        }
    }
    
    // MARK: - Training Reminders
    
    /// 安排每日训练提醒
    /// - Parameters:
    ///   - hour: 小时（0-23）
    ///   - minute: 分钟（0-59）
    func scheduleDailyTrainingReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "训练提醒"
        content.body = randomTrainingMessage()
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "TRAINING_REMINDER"
        content.userInfo = ["type": "dailyTraining"]
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "dailyTrainingReminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule daily reminder: \(error)")
            }
        }
    }
    
    /// 安排自定义训练提醒（带训练内容信息）
    /// - Parameters:
    ///   - hour: 小时
    ///   - minute: 分钟
    ///   - trainingNames: 今日训练方法名称
    func scheduleTrainingReminderWithContent(hour: Int, minute: Int, trainingNames: [String]) {
        let content = UNMutableNotificationContent()
        content.title = "训练提醒"
        
        if trainingNames.isEmpty {
            content.body = "今天是休息日，好好恢复！"
        } else if trainingNames.count == 1 {
            content.body = "今天的训练：\(trainingNames[0])，准备好了吗？"
        } else {
            let names = trainingNames.prefix(3).joined(separator: "、")
            content.body = "今天有\(trainingNames.count)项训练：\(names)等，开始吧！"
        }
        
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "TRAINING_REMINDER"
        content.userInfo = ["type": "trainingWithContent", "trainingCount": trainingNames.count]
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "dailyTrainingReminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule training reminder: \(error)")
            }
        }
    }
    
    /// 取消每日训练提醒
    func cancelDailyTrainingReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["dailyTrainingReminder"])
    }
    
    // MARK: - Check-in Reminders
    
    /// 安排打卡提醒（如果当天未打卡）
    func scheduleCheckInReminder() {
        let content = UNMutableNotificationContent()
        content.title = "打卡提醒"
        content.body = "今天还没有打卡哦，完成训练后记得打卡！"
        content.sound = .default
        content.categoryIdentifier = "CHECKIN_REMINDER"
        
        // 晚上8点提醒
        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "checkInReminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule check-in reminder: \(error)")
            }
        }
    }
    
    /// 取消打卡提醒
    func cancelCheckInReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["checkInReminder"])
    }
    
    // MARK: - Achievement Notifications
    
    /// 发送成就通知
    /// - Parameters:
    ///   - title: 通知标题
    ///   - body: 通知内容
    func sendAchievementNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "ACHIEVEMENT"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to send achievement notification: \(error)")
            }
        }
    }
    
    // MARK: - Plan Milestone Notifications
    
    /// 发送计划进度里程碑通知
    /// - Parameter progress: 进度百分比（0-1）
    func sendPlanMilestoneNotification(progress: Double) {
        let milestones: [(threshold: Double, title: String, body: String)] = [
            (0.25, "进度25%", "你已经完成了四分之一的训练计划，继续加油！"),
            (0.50, "进度50%", "半程达成！你的坚持令人钦佩！"),
            (0.75, "进度75%", "四分之三完成，胜利就在眼前！"),
            (1.00, "计划完成！", "恭喜你完成了整个训练计划！🎉")
        ]
        
        for milestone in milestones {
            if abs(progress - milestone.threshold) < 0.02 {
                sendAchievementNotification(title: milestone.title, body: milestone.body)
                break
            }
        }
    }
    
    /// 发送连续训练激励通知
    /// - Parameter streakDays: 连续训练天数
    func sendStreakMotivationNotification(streakDays: Int) {
        let messages: [(days: Int, title: String, body: String)] = [
            (3, "连续3天！", "连续训练3天，好习惯正在养成！"),
            (7, "一周达成！", "你已经坚持训练一周了，真棒！"),
            (14, "两周达成！", "连续训练两周，你的毅力令人敬佩！"),
            (30, "一个月！", "坚持训练一个月，你已经蜕变！")
        ]
        
        for message in messages {
            if streakDays == message.days {
                sendAchievementNotification(title: message.title, body: message.body)
                break
            }
        }
    }
    
    /// 发送训练完成确认通知
    /// - Parameter methodName: 完成的训练方法名称
    func sendTrainingCompletionNotification(methodName: String) {
        let content = UNMutableNotificationContent()
        content.title = "训练完成"
        content.body = "\(methodName)已完成，\(randomMotivationalMessage())"
        content.sound = .default
        content.categoryIdentifier = "TRAINING_COMPLETE"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to send completion notification: \(error)")
            }
        }
    }
    
    // MARK: - Badge Management
    
    /// 清除应用角标
    func clearBadge() {
        center.removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    /// 更新应用角标
    /// - Parameter count: 角标数字
    func updateBadge(count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }
    
    // MARK: - Pending Notifications Management
    
    /// 获取待发送的通知数量
    func getPendingNotificationCount(completion: @escaping (Int) -> Void) {
        center.getPendingNotificationRequests { requests in
            completion(requests.count)
        }
    }
    
    /// 取消所有通知
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        clearBadge()
    }
    
    // MARK: - Weekly Analysis Report
    
    /// 安排每周状态分析报告通知
    /// - Parameter weekday: 星期几（1=周日, 2=周一, ..., 7=周六）
    func scheduleWeeklyAnalysisReport(weekday: Int = 2) {
        let content = UNMutableNotificationContent()
        content.title = "每周状态分析"
        content.body = "你的本周训练状态分析报告已生成，点击查看详情！"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "ANALYSIS_REPORT"
        content.userInfo = ["type": "weeklyAnalysis"]
        
        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weeklyAnalysisReport",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule weekly analysis report: \(error)")
            }
        }
    }
    
    /// 取消每周状态分析报告通知
    func cancelWeeklyAnalysisReport() {
        center.removePendingNotificationRequests(withIdentifiers: ["weeklyAnalysisReport"])
    }
    
    /// 发送即时状态分析通知
    /// - Parameter score: 综合评分
    func sendAnalysisUpdateNotification(score: Int, level: String) {
        let content = UNMutableNotificationContent()
        content.title = "状态分析更新"
        content.body = "你的当前能力评分：\(score)分（\(level)），点击查看详细分析！"
        content.sound = .default
        content.categoryIdentifier = "ANALYSIS_UPDATE"
        content.userInfo = ["type": "analysisUpdate", "score": score]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("Failed to send analysis update notification: \(error)")
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// 随机获取训练提醒消息
    private func randomTrainingMessage() -> String {
        trainingReminderMessages.randomElement() ?? trainingReminderMessages[0]
    }
    
    /// 随机获取激励消息
    private func randomMotivationalMessage() -> String {
        motivationalMessages.randomElement() ?? motivationalMessages[0]
    }
}
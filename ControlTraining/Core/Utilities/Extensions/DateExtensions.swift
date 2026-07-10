import Foundation

extension Date {
    /// 获取当天开始时间
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// 获取当天结束时间
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    /// 是否是今天
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// 是否是昨天
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
    
    /// 格式化为中文日期
    var formattedDateCN: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
    
    /// 格式化为时间
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// 获取星期几（中文）
    var weekdayCN: String {
        let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
        let component = Calendar.current.component(.weekday, from: self)
        return "周\(weekdays[component - 1])"
    }
    
    /// 距离现在的时间描述
    var timeAgoDescription: String {
        let interval = Date().timeIntervalSince(self)
        
        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分钟前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))小时前"
        } else if interval < 604800 {
            return "\(Int(interval / 86400))天前"
        } else {
            return formattedDateCN
        }
    }
}

extension TimeInterval {
    /// 格式化为时长显示
    var formattedDuration: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        
        if hours > 0 {
            return String(format: "%d小时%d分", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d分%d秒", minutes, seconds)
        } else {
            return String(format: "%d秒", seconds)
        }
    }
    
    /// 格式化为计时器显示 (MM:SS)
    var timerDisplay: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
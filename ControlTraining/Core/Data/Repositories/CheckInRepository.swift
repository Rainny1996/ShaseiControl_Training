import Foundation
import CoreData

/// 打卡数据仓库，封装打卡相关的数据操作
class CheckInRepository {
    private let dataController: DataController
    
    init(dataController: DataController = .shared) {
        self.dataController = dataController
    }
    
    // MARK: - Check-in Records
    
    /// 保存打卡记录
    func saveCheckInRecord(_ record: CheckInRecord) {
        dataController.performBackgroundTask { context in
            CDCheckInRecord(context: context, from: record)
        }
    }
    
    /// 今日是否已打卡
    func hasCheckedInToday() -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<CDCheckInRecord> = CDCheckInRecord.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let count = try dataController.container.viewContext.count(for: request)
            return count > 0
        } catch {
            print("Failed to check today's check-in: \(error)")
            return false
        }
    }
    
    /// 获取指定日期的打卡记录
    func fetchCheckInRecord(for date: Date) -> CheckInRecord? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<CDCheckInRecord> = CDCheckInRecord.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.first?.toDomainModel()
        } catch {
            print("Failed to fetch check-in record: \(error)")
            return nil
        }
    }
    
    /// 获取指定日期范围的打卡记录
    func fetchCheckInRecords(from startDate: Date, to endDate: Date) -> [CheckInRecord] {
        let request: NSFetchRequest<CDCheckInRecord> = CDCheckInRecord.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.map { $0.toDomainModel() }
        } catch {
            print("Failed to fetch check-in records: \(error)")
            return []
        }
    }
    
    /// 获取连续打卡天数
    func fetchConsecutiveCheckInDays() -> Int {
        let request: NSFetchRequest<CDCheckInRecord> = CDCheckInRecord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            let dates = results.compactMap { $0.date }
                .map { Calendar.current.startOfDay(for: $0) }
            
            guard !dates.isEmpty else { return 0 }
            
            // 检查今天是否已打卡，如果没有则从昨天开始计算
            let today = Calendar.current.startOfDay(for: Date())
            var startDate = dates.contains(today) ? today :
                Calendar.current.date(byAdding: .day, value: -1, to: today)!
            
            var consecutiveDays = 0
            let uniqueDates = Set(dates)
            
            while uniqueDates.contains(startDate) {
                consecutiveDays += 1
                guard let prevDay = Calendar.current.date(byAdding: .day, value: -1, to: startDate) else { break }
                startDate = prevDay
            }
            
            return consecutiveDays
        } catch {
            print("Failed to fetch consecutive check-in days: \(error)")
            return 0
        }
    }
    
    /// 获取总打卡天数
    func fetchTotalCheckInDays() -> Int {
        let request: NSFetchRequest<CDCheckInRecord> = CDCheckInRecord.fetchRequest()
        
        do {
            return try dataController.container.viewContext.count(for: request)
        } catch {
            print("Failed to count check-in records: \(error)")
            return 0
        }
    }
    
    /// 获取打卡日历数据（指定月份的打卡日期集合）
    func fetchCheckInDatesForMonth(year: Int, month: Int) -> Set<Date> {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let startOfMonth = Calendar.current.date(from: components),
              let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return []
        }
        
        let records = fetchCheckInRecords(from: startOfMonth, to: endOfMonth)
        return Set(records.map { Calendar.current.startOfDay(for: $0.date) })
    }
    
    /// 补签（允许补签过去3天内的日期）
    func makeUpCheckIn(for date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)
        
        // 只允许补签过去3天内（不含今天）的日期
        guard let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today) else { return false }
        guard targetDate > threeDaysAgo && targetDate < today else { return false }
        
        // 检查目标日期是否已打卡
        if fetchCheckInRecord(for: targetDate) != nil { return false }
        
        let record = CheckInRecord(date: targetDate, checkInTime: Date())
        saveCheckInRecord(record)
        return true
    }
}
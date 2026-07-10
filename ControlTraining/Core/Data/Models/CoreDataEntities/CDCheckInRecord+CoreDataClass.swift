import Foundation
import CoreData

/// Core Data 打卡记录实体
/// 属性声明由 Xcode 自动生成（CDCheckInRecord+CoreDataProperties.swift）
@objc(CDCheckInRecord)
public class CDCheckInRecord: NSManagedObject {
}

extension CDCheckInRecord {
    /// 便利初始化方法
    convenience init(context: NSManagedObjectContext, from record: CheckInRecord) {
        self.init(context: context)
        self.id = record.id
        self.date = record.date
        self.checkInTime = record.checkInTime
        self.trainingRecordId = record.trainingRecordId
    }
    
    /// 转换为领域模型
    func toDomainModel() -> CheckInRecord {
        return CheckInRecord(
            id: id!,
            date: date!,
            checkInTime: checkInTime!,
            trainingRecordId: trainingRecordId
        )
    }
}
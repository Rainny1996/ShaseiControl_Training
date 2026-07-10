import Foundation
import CoreData

/// Core Data 训练记录实体
@objc(CDTrainingRecord)
public class CDTrainingRecord: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var methodId: UUID
    @NSManaged public var date: Date
    @NSManaged public var duration: Double
    @NSManaged public var completionRate: Double
    @NSManaged public var selfRating: Int16
    @NSManaged public var notes: String?
    @NSManaged public var mode: String
    @NSManaged public var user: CDUser?
    @NSManaged public var reviewNotes: NSSet?
}

extension CDTrainingRecord {
    /// 便利初始化方法
    convenience init(context: NSManagedObjectContext, from record: TrainingRecord) {
        self.init(context: context)
        self.id = record.id
        self.methodId = record.methodId
        self.date = record.date
        self.duration = record.duration
        self.completionRate = record.completionRate
        self.selfRating = Int16(record.selfRating)
        self.notes = record.notes
        self.mode = record.mode.rawValue
    }
    
    /// 转换为领域模型
    func toDomainModel() -> TrainingRecord {
        return TrainingRecord(
            id: id,
            methodId: methodId,
            date: date,
            duration: duration,
            completionRate: completionRate,
            selfRating: Int(selfRating),
            notes: notes ?? "",
            mode: TrainingMode(rawValue: mode) ?? .basic
        )
    }
}
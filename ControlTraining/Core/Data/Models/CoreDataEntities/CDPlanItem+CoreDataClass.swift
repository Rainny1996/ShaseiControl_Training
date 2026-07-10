import Foundation
import CoreData

/// Core Data 计划项实体
@objc(CDPlanItem)
public class CDPlanItem: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var methodId: UUID
    @NSManaged public var methodName: String
    @NSManaged public var duration: Double
    @NSManaged public var isCompleted: Bool
    @NSManaged public var completedAt: Date?
    @NSManaged public var plan: CDTrainingPlan?
}

extension CDPlanItem {
    /// 便利初始化方法
    convenience init(context: NSManagedObjectContext, from item: PlanItem) {
        self.init(context: context)
        self.id = item.id
        self.date = item.date
        self.methodId = item.methodId
        self.methodName = item.methodName
        self.duration = item.duration
        self.isCompleted = item.isCompleted
        self.completedAt = item.completedAt
    }
    
    /// 转换为领域模型
    func toDomainModel() -> PlanItem {
        return PlanItem(
            id: id,
            date: date,
            methodId: methodId,
            methodName: methodName,
            duration: duration,
            isCompleted: isCompleted,
            completedAt: completedAt
        )
    }
}
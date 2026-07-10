import Foundation
import CoreData

/// Core Data 计划项实体
/// 属性声明由 Xcode 自动生成（CDPlanItem+CoreDataProperties.swift）
@objc(CDPlanItem)
public class CDPlanItem: NSManagedObject {
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
            id: id!,
            date: date!,
            methodId: methodId!,
            methodName: methodName!,
            duration: duration,
            isCompleted: isCompleted,
            completedAt: completedAt
        )
    }
}
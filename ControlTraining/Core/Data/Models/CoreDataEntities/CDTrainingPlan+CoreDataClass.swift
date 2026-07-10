import Foundation
import CoreData

/// Core Data 训练计划实体
/// 属性声明由 Xcode 自动生成（CDTrainingPlan+CoreDataProperties.swift）
@objc(CDTrainingPlan)
public class CDTrainingPlan: NSManagedObject {
}

extension CDTrainingPlan {
    /// 便利初始化方法
    convenience init(context: NSManagedObjectContext, from plan: TrainingPlan) {
        self.init(context: context)
        self.id = plan.id
        self.startDate = plan.startDate
        self.endDate = plan.endDate
        self.progress = plan.progress
        self.goal = plan.goal
    }
    
    /// 转换为领域模型
    func toDomainModel() -> TrainingPlan {
        let items = (planItems as? Set<CDPlanItem>)?.map { $0.toDomainModel() } ?? []
        return TrainingPlan(
            id: id!,
            startDate: startDate!,
            endDate: endDate!,
            items: items,
            progress: progress,
            goal: goal!
        )
    }
    
    /// 更新计划项
    func updatePlanItems(from items: [PlanItem], in context: NSManagedObjectContext) {
        // 移除旧的计划项
        if let existingItems = planItems as? Set<CDPlanItem> {
            for item in existingItems {
                context.delete(item)
            }
        }
        // 添加新的计划项
        var newItems = Set<CDPlanItem>()
        for item in items {
            let cdItem = CDPlanItem(context: context, from: item)
            cdItem.plan = self
            newItems.insert(cdItem)
        }
        planItems = newItems as NSSet
    }
}
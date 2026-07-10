import Foundation
import CoreData

/// 计划数据仓库，封装训练计划相关的数据操作
class PlanRepository {
    private let dataController: DataController
    
    init(dataController: DataController = .shared) {
        self.dataController = dataController
    }
    
    // MARK: - Training Plan
    
    /// 保存训练计划
    func saveTrainingPlan(_ plan: TrainingPlan) {
        dataController.performBackgroundTask { context in
            let cdPlan = CDTrainingPlan(context: context, from: plan)
            // 保存计划项
            for item in plan.items {
                let cdItem = CDPlanItem(context: context, from: item)
                cdItem.plan = cdPlan
            }
        }
    }
    
    /// 获取当前活跃的训练计划
    func fetchActivePlan() -> TrainingPlan? {
        let request: NSFetchRequest<CDTrainingPlan> = CDTrainingPlan.fetchRequest()
        request.predicate = NSPredicate(format: "endDate >= %@", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.first?.toDomainModel()
        } catch {
            print("Failed to fetch active plan: \(error)")
            return nil
        }
    }
    
    /// 获取所有训练计划
    func fetchAllPlans() -> [TrainingPlan] {
        let request: NSFetchRequest<CDTrainingPlan> = CDTrainingPlan.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.map { $0.toDomainModel() }
        } catch {
            print("Failed to fetch all plans: \(error)")
            return []
        }
    }
    
    /// 更新计划进度
    func updatePlanProgress(planId: UUID, progress: Double) {
        let request: NSFetchRequest<CDTrainingPlan> = CDTrainingPlan.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", planId as CVarArg)
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            if let plan = results.first {
                plan.progress = progress
                dataController.save()
            }
        } catch {
            print("Failed to update plan progress: \(error)")
        }
    }
    
    /// 标记计划项完成
    func markPlanItemCompleted(itemId: UUID) {
        let request: NSFetchRequest<CDPlanItem> = CDPlanItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            if let item = results.first {
                item.isCompleted = true
                item.completedAt = Date()
                dataController.save()
                
                // 自动更新计划进度
                if let plan = item.plan {
                    let totalItems = (plan.planItems as? Set<CDPlanItem>)?.count ?? 0
                    let completedItems = (plan.planItems as? Set<CDPlanItem>)?.filter { $0.isCompleted }.count ?? 0
                    if totalItems > 0 {
                        plan.progress = Double(completedItems) / Double(totalItems)
                    }
                    dataController.save()
                }
            }
        } catch {
            print("Failed to mark plan item completed: \(error)")
        }
    }
    
    /// 获取今日计划项
    func fetchTodayPlanItems() -> [PlanItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<CDPlanItem> = CDPlanItem.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.map { $0.toDomainModel() }
        } catch {
            print("Failed to fetch today's plan items: \(error)")
            return []
        }
    }
    
    /// 获取指定日期范围的计划项
    func fetchPlanItems(from startDate: Date, to endDate: Date) -> [PlanItem] {
        let request: NSFetchRequest<CDPlanItem> = CDPlanItem.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.map { $0.toDomainModel() }
        } catch {
            print("Failed to fetch plan items: \(error)")
            return []
        }
    }
    
    /// 删除训练计划
    func deletePlan(_ planId: UUID) {
        dataController.performBackgroundTask { context in
            let request: NSFetchRequest<CDTrainingPlan> = CDTrainingPlan.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", planId as CVarArg)
            
            do {
                let results = try context.fetch(request)
                results.forEach { context.delete($0) }
            } catch {
                print("Failed to delete plan: \(error)")
            }
        }
    }
    
    /// 更新训练计划（替换计划项）
    func updatePlanItems(planId: UUID, items: [PlanItem]) {
        let request: NSFetchRequest<CDTrainingPlan> = CDTrainingPlan.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", planId as CVarArg)
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            if let plan = results.first {
                plan.updatePlanItems(from: items, in: dataController.container.viewContext)
                // 重新计算进度
                var mutablePlan = plan.toDomainModel()
                mutablePlan.updateProgress()
                plan.progress = mutablePlan.progress
                dataController.save()
            }
        } catch {
            print("Failed to update plan items: \(error)")
        }
    }
    
    /// 获取计划完成率
    func fetchPlanCompletionRate(planId: UUID) -> Double {
        let request: NSFetchRequest<CDTrainingPlan> = CDTrainingPlan.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", planId as CVarArg)
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.first?.progress ?? 0
        } catch {
            print("Failed to fetch plan completion rate: \(error)")
            return 0
        }
    }
}
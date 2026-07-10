import Foundation
import CoreData

/// 训练数据仓库，封装训练相关的数据操作
class TrainingRepository {
    private let dataController: DataController
    
    init(dataController: DataController = .shared) {
        self.dataController = dataController
    }
    
    // MARK: - Training Records
    
    /// 保存训练记录
    func saveTrainingRecord(_ record: TrainingRecord) {
        dataController.performBackgroundTask { context in
            CDTrainingRecord(context: context, from: record)
        }
    }
    
    /// 获取指定日期范围的训练记录
    func fetchTrainingRecords(from startDate: Date, to endDate: Date) -> [TrainingRecord] {
        let request: NSFetchRequest<CDTrainingRecord> = CDTrainingRecord.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.map { $0.toDomainModel() }
        } catch {
            print("Failed to fetch training records: \(error)")
            return []
        }
    }
    
    /// 获取今日训练记录
    func fetchTodayRecords() -> [TrainingRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return fetchTrainingRecords(from: startOfDay, to: endOfDay)
    }
    
    /// 获取指定训练方法的记录
    func fetchRecordsByMethod(_ methodId: UUID) -> [TrainingRecord] {
        let request: NSFetchRequest<CDTrainingRecord> = CDTrainingRecord.fetchRequest()
        request.predicate = NSPredicate(format: "methodId == %@", methodId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.map { $0.toDomainModel() }
        } catch {
            print("Failed to fetch records by method: \(error)")
            return []
        }
    }
    
    /// 获取训练记录总数
    func fetchTotalRecordCount() -> Int {
        let request: NSFetchRequest<CDTrainingRecord> = CDTrainingRecord.fetchRequest()
        
        do {
            return try dataController.container.viewContext.count(for: request)
        } catch {
            print("Failed to count training records: \(error)")
            return 0
        }
    }
    
    /// 删除训练记录
    func deleteTrainingRecord(_ recordId: UUID) {
        dataController.performBackgroundTask { context in
            let request: NSFetchRequest<CDTrainingRecord> = CDTrainingRecord.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", recordId as CVarArg)
            
            do {
                let results = try context.fetch(request)
                results.forEach { context.delete($0) }
            } catch {
                print("Failed to delete training record: \(error)")
            }
        }
    }
    
    // MARK: - Training Methods
    
    /// 保存训练方法
    func saveTrainingMethod(_ method: TrainingMethod) {
        dataController.performBackgroundTask { context in
            CDTrainingMethod(context: context, from: method)
        }
    }
    
    /// 获取所有训练方法
    func fetchAllTrainingMethods() -> [TrainingMethod] {
        let request: NSFetchRequest<CDTrainingMethod> = CDTrainingMethod.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true)]
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.map { $0.toDomainModel() }
        } catch {
            print("Failed to fetch training methods: \(error)")
            return []
        }
    }
    
    /// 按分类获取训练方法
    func fetchTrainingMethods(by category: TrainingCategory) -> [TrainingMethod] {
        let request: NSFetchRequest<CDTrainingMethod> = CDTrainingMethod.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category.rawValue)
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.map { $0.toDomainModel() }
        } catch {
            print("Failed to fetch training methods by category: \(error)")
            return []
        }
    }
    
    /// 切换收藏状态
    func toggleFavorite(methodId: UUID) {
        let request: NSFetchRequest<CDTrainingMethod> = CDTrainingMethod.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", methodId as CVarArg)
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            if let method = results.first {
                method.isFavorite = !method.isFavorite
                dataController.save()
            }
        } catch {
            print("Failed to toggle favorite: \(error)")
        }
    }
    
    /// 获取收藏的训练方法
    func fetchFavoriteMethods() -> [TrainingMethod] {
        let request: NSFetchRequest<CDTrainingMethod> = CDTrainingMethod.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == YES")
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.map { $0.toDomainModel() }
        } catch {
            print("Failed to fetch favorite methods: \(error)")
            return []
        }
    }
    
    /// 批量导入训练方法（首次启动时使用）
    func importTrainingMethods(_ methods: [TrainingMethod]) {
        dataController.performBackgroundTask { context in
            for method in methods {
                CDTrainingMethod(context: context, from: method)
            }
        }
    }
}
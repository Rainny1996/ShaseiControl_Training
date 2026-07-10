import CoreData
import SwiftUI

/// Core Data 数据控制器，管理持久化容器和数据上下文
class DataController: ObservableObject {
    static let shared = DataController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ControlTrainingModel")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // 配置数据保护级别
        if let description = container.persistentStoreDescriptions.first {
            description.setOption(FileProtectionType.complete.rawValue as NSNumber,
                                  forKey: NSPersistentStoreFileProtectionKey)
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Context Management
    
    /// 保存视图上下文
    func save() {
        guard container.viewContext.hasChanges else { return }
        
        do {
            try container.viewContext.save()
        } catch {
            print("Failed to save Core Data context: \(error)")
        }
    }
    
    /// 创建后台上下文用于批量操作
    func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
    
    /// 在后台上下文中执行操作
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { context in
            block(context)
            
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    print("Failed to save background context: \(error)")
                }
            }
        }
    }
    
    // MARK: - Data Management
    
    /// 删除所有用户数据（用于隐私保护功能）
    func deleteAllUserData() {
        let entities = ["CDTrainingRecord", "CDCheckInRecord", "CDTrainingPlan", "CDAbilityProfile", "CDReviewNote"]
        
        performBackgroundTask { context in
            for entityName in entities {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                
                do {
                    try context.execute(deleteRequest)
                } catch {
                    print("Failed to delete \(entityName): \(error)")
                }
            }
        }
        
        // 批量删除直接操作SQLite，绕过viewContext，必须刷新缓存
        DispatchQueue.main.async { [weak self] in
            self?.container.viewContext.reset()
        }
    }
}
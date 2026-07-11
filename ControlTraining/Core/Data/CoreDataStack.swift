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
            description.setOption(FileProtectionType.complete.rawValue,
                                  forKey: NSPersistentStoreFileProtectionKey)
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }

        // AC-7.5: 排除 iCloud 备份
        if let url = container.persistentStoreDescriptions.first?.url {
            excludeFromiCloudBackup(directoryAt: url)
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
    /// ARC-03 修复: 在后台任务完成后再 reset，消除竞态
    func deleteAllUserData() {
        let entities = ["CDTrainingRecord", "CDCheckInRecord", "CDTrainingPlan", "CDAbilityProfile", "CDReviewNote"]
        
        container.performBackgroundTask { [weak self] context in
            for entityName in entities {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                do {
                    try context.execute(deleteRequest)
                } catch {
                    print("Failed to delete \(entityName): \(error)")
                }
            }
            if context.hasChanges {
                try? context.save()
            }
            // 批量删除直接操作SQLite绕过viewContext，必须在后台保存完成后刷新
            DispatchQueue.main.async {
                self?.container.viewContext.reset()
            }
        }
    }

    // MARK: - iCloud Exclusion (AC-7.5)

    /// 为 Core Data 存储目录设置 skipBackup 属性，排除 iCloud 备份
    private func excludeFromiCloudBackup(directoryAt storeURL: URL) {
        var url = storeURL
        url.deleteLastPathComponent()
        do {
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
        } catch {
            print("⚠️ Failed to set iCloud backup exclusion: \(error.localizedDescription)")
        }
    }
}
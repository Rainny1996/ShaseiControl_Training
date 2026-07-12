import CoreData

/// Core Data 存储栈，启用 NSFileProtectionComplete 文件级加密
final class CoreDataStack {
    static let shared = CoreDataStack()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        // 启用轻量级自动迁移，兼容旧版本写入的 store
        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true
        container.loadPersistentStores { [weak self] _, error in
            if let error {
                // 旧 schema / 损坏的 store 可能导致加载失败：销毁后重建，避免 fatalError 让 app 闪退
                print("Core Data 加载失败，尝试销毁并重建: \(error)")
                self?.destroyAndRebuildStore()
                return
            }
            // 启用文件级加密
            self?.applyFileProtection()
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    /// 删除已存在的持久化 store 文件并触发重建（仅用于开发期旧数据损坏兜底）
    private func destroyAndRebuildStore() {
        guard let storeURL = persistentContainer.persistentStoreDescriptions.first?.url
                ?? persistentContainer.persistentStoreCoordinator.persistentStores.first?.url else { return }
        try? persistentContainer.persistentStoreCoordinator.destroyPersistentStore(
            at: storeURL, ofType: NSSQLiteStoreType, options: nil
        )
        try? FileManager.default.removeItem(at: storeURL)
        // 重新加载（lazy 已执行，这里直接重建容器引用）
        persistentContainer.loadPersistentStores { [weak self] _, error in
            if let error {
                print("Core Data 重建仍失败: \(error)")
                return
            }
            self?.applyFileProtection()
        }
    }

    var context: NSManagedObjectContext { persistentContainer.viewContext }

    private func applyFileProtection() {
        guard let storeURL = persistentContainer.persistentStoreCoordinator.persistentStores.first?.url else { return }
        do {
            try FileManager.default.setAttributes(
                [FileAttributeKey.protectionKey: FileProtectionType.complete],
                ofItemAtPath: storeURL.path
            )
        } catch {
            // 部分模拟器不支持加密属性，忽略
        }
    }

    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("保存失败: \(error)")
        }
    }

    func insertSession(from machine: TrainingStateMachine) -> TrainingSession {
        let session = TrainingSession(context: context)
        session.id = UUID()
        session.startTime = machine.startTime
        session.endTime = Date()
        session.totalDuration = Int32(Date().timeIntervalSince(machine.startTime))
        session.cycleCount = Int32(machine.controlDurations.count)
        session.controlDurationsArray = machine.controlDurations
        session.usedSqueeze = machine.usedSqueeze
        session.prematureEjaculation = machine.prematureEjaculation
        session.brakePoint = machine.brakePoint
        save()
        return session
    }

    func allSessions() -> [TrainingSession] {
        let req = TrainingSession.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        return (try? context.fetch(req)) ?? []
    }
}

import CoreData

/// Core Data 存储栈，启用 NSFileProtectionComplete 文件级加密
final class CoreDataStack {
    static let shared = CoreDataStack()

    private var _container: NSPersistentContainer?
    var persistentContainer: NSPersistentContainer {
        if let c = _container { return c }
        let c = Self.buildContainer()
        _container = c
        return c
    }

    /// 同步构建容器：加载失败（旧 schema / 损坏 store）时删除文件并重建，绝不 fatalError
    private static func buildContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "Model")
        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true

        let semaphore = DispatchSemaphore(value: 0)
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
            semaphore.signal()
        }
        semaphore.wait()

        if let error = loadError {
            print("Core Data 加载失败，删除损坏 store 后重建: \(error)")
            if let url = description?.url {
                try? container.persistentStoreCoordinator.destroyPersistentStore(
                    at: url, ofType: NSSQLiteStoreType, options: nil
                )
                try? FileManager.default.removeItem(at: url)
            }
            // 重建
            let sem2 = DispatchSemaphore(value: 0)
            container.loadPersistentStores { _, error in
                if let e = error { print("Core Data 重建仍失败: \(e)") }
                sem2.signal()
            }
            sem2.wait()
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        // 启用文件级加密
        if let url = container.persistentStoreCoordinator.persistentStores.first?.url {
            try? FileManager.default.setAttributes(
                [FileAttributeKey.protectionKey: FileProtectionType.complete],
                ofItemAtPath: url.path
            )
        }
        return container
    }

    var context: NSManagedObjectContext { persistentContainer.viewContext }

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

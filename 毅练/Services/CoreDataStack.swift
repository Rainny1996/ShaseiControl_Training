import CoreData

/// Core Data 存储栈，启用 NSFileProtectionComplete 文件级加密
final class CoreDataStack {
    static let shared = CoreDataStack()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores { [weak self] _, error in
            if let error {
                fatalError("Core Data 加载失败: \(error)")
            }
            // 启用文件级加密
            self?.applyFileProtection()
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

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

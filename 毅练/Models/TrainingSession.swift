import Foundation
import CoreData

/// Core Data 实体映射 - 训练记录（PRD §5.1）
@objc(TrainingSession)
public class TrainingSession: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var totalDuration: Int32      // 秒
    @NSManaged public var cycleCount: Int32
    @NSManaged public var controlDurations: Data?     // [Int] 各循环可控区间时长（秒），JSON 编码
    @NSManaged public var usedSqueeze: Bool
    @NSManaged public var prematureEjaculation: Bool
    @NSManaged public var note: String?
    @NSManaged public var brakePoint: Float          // 进入7分时的刹车点等级（6.5 / 7 等）
    @NSManaged public var phaseDurations: Data?      // [[String: Double]] 每轮各阶段时长（秒），JSON 编码；索引 0 为无循环维度的阶段

    var controlDurationsArray: [Int] {
        get {
            guard let data = controlDurations else { return [] }
            return (try? JSONDecoder().decode([Int].self, from: data)) ?? []
        }
        set {
            controlDurations = try? JSONEncoder().encode(newValue)
        }
    }

    /// 每轮各阶段时长（秒）：phaseDurationsByCycle[cycle-1][stage] = 秒数
    var phaseDurationsByCycle: [[String: Double]] {
        get {
            guard let data = phaseDurations else { return [] }
            return (try? JSONDecoder().decode([[String: Double]].self, from: data)) ?? []
        }
        set {
            phaseDurations = try? JSONEncoder().encode(newValue)
        }
    }
}

extension TrainingSession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TrainingSession> {
        return NSFetchRequest<TrainingSession>(entityName: "TrainingSession")
    }

    /// 导出为加密 JSON 用的纯数值模型（不含 PII）
    func toExportDictionary() -> [String: Any] {
        return [
            "id": id?.uuidString ?? "",
            "startTime": startTime?.timeIntervalSince1970 ?? 0,
            "endTime": endTime?.timeIntervalSince1970 ?? 0,
            "totalDuration": totalDuration,
            "cycleCount": cycleCount,
            "controlDurations": controlDurationsArray,
            "phaseDurations": phaseDurationsByCycle,
            "usedSqueeze": usedSqueeze,
            "prematureEjaculation": prematureEjaculation,
            "brakePoint": brakePoint
        ]
    }
}

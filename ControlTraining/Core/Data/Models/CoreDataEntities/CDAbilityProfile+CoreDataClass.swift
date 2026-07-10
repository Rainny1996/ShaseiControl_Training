import Foundation
import CoreData

/// Core Data 能力档案实体
@objc(CDAbilityProfile)
public class CDAbilityProfile: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var overallScore: Int16
    @NSManaged public var endurance: Double
    @NSManaged public var control: Double
    @NSManaged public var recovery: Double
    @NSManaged public var breathCoordination: Double
    @NSManaged public var muscleStrength: Double
    @NSManaged public var level: String
    @NSManaged public var lastUpdated: Date
    @NSManaged public var user: CDUser?
}

extension CDAbilityProfile {
    /// 便利初始化方法
    convenience init(context: NSManagedObjectContext, from profile: AbilityProfile) {
        self.init(context: context)
        self.id = profile.id
        self.overallScore = Int16(profile.overallScore)
        self.endurance = profile.endurance
        self.control = profile.control
        self.recovery = profile.recovery
        self.breathCoordination = profile.breathCoordination
        self.muscleStrength = profile.muscleStrength
        self.level = profile.level.rawValue
        self.lastUpdated = profile.lastUpdated
    }
    
    /// 转换为领域模型
    func toDomainModel() -> AbilityProfile {
        return AbilityProfile(
            id: id,
            overallScore: Int(overallScore),
            endurance: endurance,
            control: control,
            recovery: recovery,
            breathCoordination: breathCoordination,
            muscleStrength: muscleStrength,
            lastUpdated: lastUpdated
        )
    }
}
import Foundation
import CoreData

/// Core Data 训练方法实体
@objc(CDTrainingMethod)
public class CDTrainingMethod: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var category: String
    @NSManaged public var difficulty: String
    @NSManaged public var methodDescription: String
    @NSManaged public var principle: String
    @NSManaged public var stepsData: Data?
    @NSManaged public var precautionsData: Data?
    @NSManaged public var expectedEffect: String
    @NSManaged public var targetAudience: String
    @NSManaged public var defaultDuration: Double
    @NSManaged public var isFavorite: Bool
}

extension CDTrainingMethod {
    /// 便利初始化方法
    convenience init(context: NSManagedObjectContext, from method: TrainingMethod) {
        self.init(context: context)
        self.id = method.id
        self.name = method.name
        self.category = method.category.rawValue
        self.difficulty = method.difficulty.rawValue
        self.methodDescription = method.description
        self.principle = method.principle
        self.expectedEffect = method.expectedEffect
        self.targetAudience = method.targetAudience
        self.defaultDuration = method.defaultDuration
        self.isFavorite = method.isFavorite
        
        // 编码步骤和注意事项为JSON数据
        if let stepsData = try? JSONEncoder().encode(method.steps) {
            self.stepsData = stepsData
        }
        if let precautionsData = try? JSONEncoder().encode(method.precautions) {
            self.precautionsData = precautionsData
        }
    }
    
    /// 转换为领域模型
    func toDomainModel() -> TrainingMethod {
        let steps = stepsData.flatMap { try? JSONDecoder().decode([TrainingStep].self, from: $0) } ?? []
        let precautions = precautionsData.flatMap { try? JSONDecoder().decode([String].self, from: $0) } ?? []
        
        return TrainingMethod(
            id: id,
            name: name,
            category: TrainingCategory(rawValue: category) ?? .kegel,
            difficulty: DifficultyLevel(rawValue: difficulty) ?? .beginner,
            description: methodDescription,
            principle: principle,
            steps: steps,
            precautions: precautions,
            expectedEffect: expectedEffect,
            targetAudience: targetAudience,
            defaultDuration: defaultDuration,
            isFavorite: isFavorite
        )
    }
}
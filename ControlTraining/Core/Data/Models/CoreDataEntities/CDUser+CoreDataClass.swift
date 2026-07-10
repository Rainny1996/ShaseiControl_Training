import Foundation
import CoreData

/// Core Data 用户实体
/// 属性声明由 Xcode 自动生成（CDUser+CoreDataProperties.swift）
@objc(CDUser)
public class CDUser: NSManagedObject {
}

extension CDUser {
    /// 便利初始化方法
    convenience init(context: NSManagedObjectContext, name: String? = nil, age: Int32 = 0) {
        self.init(context: context)
        self.id = UUID()
        self.createdAt = Date()
        self.assessmentCompleted = false
        self.name = name
        self.age = age
    }
    
    /// 转换为领域模型
    func toDomainModel() -> UserProfile {
        return UserProfile(
            id: id!,
            createdAt: createdAt!,
            assessmentCompleted: assessmentCompleted,
            name: name ?? "",
            age: Int(age)
        )
    }
}

/// 用户领域模型（非Core Data依赖）
struct UserProfile: Identifiable {
    let id: UUID
    let createdAt: Date
    var assessmentCompleted: Bool
    var name: String
    var age: Int
}
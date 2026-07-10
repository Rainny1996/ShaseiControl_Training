import Foundation
import CoreData

/// Core Data 复盘笔记实体
/// 属性声明由 Xcode 自动生成（CDReviewNote+CoreDataProperties.swift）
@objc(CDReviewNote)
public class CDReviewNote: NSManagedObject {
}

extension CDReviewNote {
    /// 便利初始化方法
    convenience init(context: NSManagedObjectContext, from review: ReviewNote) {
        self.init(context: context)
        self.id = review.id
        self.trainingRecordId = review.trainingRecordId
        self.date = review.date
        self.feelingScore = Int16(review.feelingScore)
        self.difficultyScore = Int16(review.difficultyScore)
        self.bodyReaction = review.bodyReaction
        self.notes = review.notes
    }
    
    /// 转换为领域模型
    func toDomainModel() -> ReviewNote {
        return ReviewNote(
            id: id!,
            trainingRecordId: trainingRecordId!,
            date: date!,
            feelingScore: Int(feelingScore),
            difficultyScore: Int(difficultyScore),
            bodyReaction: bodyReaction ?? "",
            notes: notes ?? ""
        )
    }
}
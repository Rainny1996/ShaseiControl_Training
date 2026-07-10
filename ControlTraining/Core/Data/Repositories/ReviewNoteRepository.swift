import Foundation
import CoreData

/// 复盘笔记数据仓库，封装复盘相关的数据操作
class ReviewNoteRepository {
    private let dataController: DataController
    
    init(dataController: DataController = .shared) {
        self.dataController = dataController
    }
    
    // MARK: - Review Notes
    
    /// 保存复盘笔记
    func saveReviewNote(_ note: ReviewNote) {
        dataController.performBackgroundTask { context in
            CDReviewNote(context: context, from: note)
        }
    }
    
    /// 获取指定训练记录的复盘笔记
    func fetchReviewNote(for trainingRecordId: UUID) -> ReviewNote? {
        let request: NSFetchRequest<CDReviewNote> = CDReviewNote.fetchRequest()
        request.predicate = NSPredicate(format: "trainingRecordId == %@", trainingRecordId as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.first?.toDomainModel()
        } catch {
            print("Failed to fetch review note: \(error)")
            return nil
        }
    }
    
    /// 获取指定日期范围的复盘笔记
    func fetchReviewNotes(from startDate: Date, to endDate: Date) -> [ReviewNote] {
        let request: NSFetchRequest<CDReviewNote> = CDReviewNote.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.map { $0.toDomainModel() }
        } catch {
            print("Failed to fetch review notes: \(error)")
            return []
        }
    }
    
    /// 获取所有复盘笔记（按日期降序）
    func fetchAllReviewNotes() -> [ReviewNote] {
        let request: NSFetchRequest<CDReviewNote> = CDReviewNote.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.map { $0.toDomainModel() }
        } catch {
            print("Failed to fetch all review notes: \(error)")
            return []
        }
    }
    
    /// 更新复盘笔记
    func updateReviewNote(_ note: ReviewNote) {
        let request: NSFetchRequest<CDReviewNote> = CDReviewNote.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", note.id as CVarArg)
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            if let cdNote = results.first {
                cdNote.feelingScore = Int16(note.feelingScore)
                cdNote.difficultyScore = Int16(note.difficultyScore)
                cdNote.bodyReaction = note.bodyReaction
                cdNote.notes = note.notes
                dataController.save()
            }
        } catch {
            print("Failed to update review note: \(error)")
        }
    }
    
    /// 删除复盘笔记
    func deleteReviewNote(_ noteId: UUID) {
        dataController.performBackgroundTask { context in
            let request: NSFetchRequest<CDReviewNote> = CDReviewNote.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", noteId as CVarArg)
            
            do {
                let results = try context.fetch(request)
                results.forEach { context.delete($0) }
            } catch {
                print("Failed to delete review note: \(error)")
            }
        }
    }
    
    // MARK: - Statistics
    
    /// 获取指定周期的平均感受评分
    func fetchAverageFeelingScore(from startDate: Date, to endDate: Date) -> Double {
        let notes = fetchReviewNotes(from: startDate, to: endDate)
        guard !notes.isEmpty else { return 0 }
        return Double(notes.map { $0.feelingScore }.reduce(0, +)) / Double(notes.count)
    }
    
    /// 获取指定周期的平均难度评分
    func fetchAverageDifficultyScore(from startDate: Date, to endDate: Date) -> Double {
        let notes = fetchReviewNotes(from: startDate, to: endDate)
        guard !notes.isEmpty else { return 0 }
        return Double(notes.map { $0.difficultyScore }.reduce(0, +)) / Double(notes.count)
    }
    
    /// 获取复盘笔记统计数据（用于周/月报告）
    func fetchReviewStatistics(from startDate: Date, to endDate: Date) -> ReviewStatistics {
        let notes = fetchReviewNotes(from: startDate, to: endDate)
        
        guard !notes.isEmpty else {
            return ReviewStatistics(
                totalCount: 0,
                averageFeelingScore: 0,
                averageDifficultyScore: 0,
                feelingTrend: [],
                difficultyTrend: [],
                commonBodyReactions: []
            )
        }
        
        let avgFeeling = Double(notes.map { $0.feelingScore }.reduce(0, +)) / Double(notes.count)
        let avgDifficulty = Double(notes.map { $0.difficultyScore }.reduce(0, +)) / Double(notes.count)
        
        // 按日计算趋势
        let calendar = Calendar.current
        var dailyFeeling: [Date: [Int]] = [:]
        var dailyDifficulty: [Date: [Int]] = [:]
        for note in notes {
            let day = calendar.startOfDay(for: note.date)
            dailyFeeling[day, default: []].append(note.feelingScore)
            dailyDifficulty[day, default: []].append(note.difficultyScore)
        }
        
        let feelingTrend = dailyFeeling.sorted { $0.key < $1.key }.map { date, scores in
            DailyScore(date: date, score: Double(scores.reduce(0, +)) / Double(scores.count))
        }
        let difficultyTrend = dailyDifficulty.sorted { $0.key < $1.key }.map { date, scores in
            DailyScore(date: date, score: Double(scores.reduce(0, +)) / Double(scores.count))
        }
        
        // 统计常见身体反应
        let bodyReactions = notes.compactMap { $0.bodyReaction.isEmpty ? nil : $0.bodyReaction }
        let reactionCounts = Dictionary(bodyReactions.map { ($0, 1) }, uniquingKeysWith: +)
        let topReactions = reactionCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
        
        return ReviewStatistics(
            totalCount: notes.count,
            averageFeelingScore: avgFeeling,
            averageDifficultyScore: avgDifficulty,
            feelingTrend: feelingTrend,
            difficultyTrend: difficultyTrend,
            commonBodyReactions: topReactions
        )
    }
}

// MARK: - Review Statistics Models

/// 每日评分数据点
struct DailyScore: Identifiable {
    let id = UUID()
    let date: Date
    let score: Double
}

/// 复盘统计数据
struct ReviewStatistics {
    let totalCount: Int
    let averageFeelingScore: Double
    let averageDifficultyScore: Double
    let feelingTrend: [DailyScore]
    let difficultyTrend: [DailyScore]
    let commonBodyReactions: [String]
}
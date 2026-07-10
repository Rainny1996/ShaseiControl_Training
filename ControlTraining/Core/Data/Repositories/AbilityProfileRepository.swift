import Foundation
import CoreData

/// 能力档案数据仓库，封装能力评分相关的数据操作
class AbilityProfileRepository {
    private let dataController: DataController
    
    init(dataController: DataController = .shared) {
        self.dataController = dataController
    }
    
    // MARK: - Ability Profile
    
    /// 保存能力档案
    func saveAbilityProfile(_ profile: AbilityProfile) {
        dataController.performBackgroundTask { context in
            // 检查是否已存在能力档案
            let request: NSFetchRequest<CDAbilityProfile> = CDAbilityProfile.fetchRequest()
            
            do {
                let results = try context.fetch(request)
                if let existing = results.first {
                    // 更新现有档案
                    existing.overallScore = Int16(profile.overallScore)
                    existing.endurance = profile.endurance
                    existing.control = profile.control
                    existing.recovery = profile.recovery
                    existing.breathCoordination = profile.breathCoordination
                    existing.muscleStrength = profile.muscleStrength
                    existing.level = profile.level.rawValue
                    existing.lastUpdated = Date()
                } else {
                    // 创建新档案
                    CDAbilityProfile(context: context, from: profile)
                }
            } catch {
                print("Failed to save ability profile: \(error)")
            }
        }
    }
    
    /// 获取当前能力档案
    func fetchAbilityProfile() -> AbilityProfile? {
        let request: NSFetchRequest<CDAbilityProfile> = CDAbilityProfile.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastUpdated", ascending: false)]
        request.fetchLimit = 1
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            return results.first?.toDomainModel()
        } catch {
            print("Failed to fetch ability profile: \(error)")
            return nil
        }
    }
    
    /// 更新单个维度得分
    func updateDimension(dimension: AbilityDimension, score: Double) {
        let request: NSFetchRequest<CDAbilityProfile> = CDAbilityProfile.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            if let profile = results.first {
                switch dimension {
                case .endurance: profile.endurance = score
                case .control: profile.control = score
                case .recovery: profile.recovery = score
                case .breathCoordination: profile.breathCoordination = score
                case .muscleStrength: profile.muscleStrength = score
                }
                profile.lastUpdated = Date()
                dataController.save()
            }
        } catch {
            print("Failed to update dimension: \(error)")
        }
    }
    
    /// 更新综合评分
    func updateOverallScore(_ score: Int) {
        let request: NSFetchRequest<CDAbilityProfile> = CDAbilityProfile.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try dataController.container.viewContext.fetch(request)
            if let profile = results.first {
                profile.overallScore = Int16(score)
                profile.level = AbilityLevel(score: score).rawValue
                profile.lastUpdated = Date()
                dataController.save()
            }
        } catch {
            print("Failed to update overall score: \(error)")
        }
    }
    
    /// 获取能力历史记录（用于趋势图表）
    func fetchAbilityHistory(days: Int = 30) -> [AbilityProfile] {
        // Core Data中只保存最新状态，历史记录通过训练记录重新计算
        // 此方法返回基于训练记录计算的历史评分
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }
        
        let trainingRepo = TrainingRepository(dataController: dataController)
        let records = trainingRepo.fetchTrainingRecords(from: startDate, to: endDate)
        
        // 按日分组计算评分
        var dailyScores: [Date: [TrainingRecord]] = [:]
        for record in records {
            let day = calendar.startOfDay(for: record.date)
            dailyScores[day, default: []].append(record)
        }
        
        // 根据训练记录计算每日能力评分
        return dailyScores.map { date, dayRecords in
            let avgCompletion = dayRecords.map { $0.completionRate }.reduce(0, +) / Double(dayRecords.count)
            let avgRating = Double(dayRecords.map { $0.selfRating }.reduce(0, +)) / Double(dayRecords.count)
            let score = Int(avgCompletion * 60 + avgRating * 8)
            
            return AbilityProfile(
                overallScore: min(score, 100),
                endurance: avgCompletion,
                control: avgRating / 5.0,
                recovery: avgCompletion * 0.8,
                breathCoordination: avgRating / 5.0 * 0.9,
                muscleStrength: avgCompletion * 0.7,
                lastUpdated: date
            )
        }.sorted { $0.lastUpdated < $1.lastUpdated }
    }
}

/// 能力维度枚举
enum AbilityDimension: String, CaseIterable {
    case endurance = "持久力"
    case control = "控制力"
    case recovery = "恢复力"
    case breathCoordination = "呼吸配合"
    case muscleStrength = "肌肉力量"
}
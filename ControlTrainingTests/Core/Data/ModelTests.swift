import XCTest
import CoreData
@testable import ControlTraining

/// 数据模型单元测试
final class ModelTests: XCTestCase {
    
    var dataController: DataController!
    
    override func setUp() {
        super.setUp()
        // 使用内存数据库进行测试
        dataController = DataController(inMemory: true)
    }
    
    override func tearDown() {
        dataController = nil
        super.tearDown()
    }
    
    // MARK: - Training Models Tests
    
    /// 测试训练方法模型创建
    func testTrainingMethodCreation() {
        let steps = [
            TrainingStep(order: 1, title: "准备", instruction: "放松身体", duration: 30),
            TrainingStep(order: 2, title: "收缩", instruction: "收缩骨盆底肌", duration: 10),
            TrainingStep(order: 3, title: "放松", instruction: "放松肌肉", duration: 10)
        ]
        
        let method = TrainingMethod(
            name: "凯格尔运动",
            category: .kegel,
            difficulty: .beginner,
            description: "增强骨盆底肌的基础训练",
            principle: "通过有节奏的收缩和放松骨盆底肌",
            steps: steps,
            precautions: ["不要憋气", "不要收缩腹部"],
            expectedEffect: "提升控制力和持久力",
            targetAudience: "初学者",
            defaultDuration: 300
        )
        
        XCTAssertEqual(method.name, "凯格尔运动")
        XCTAssertEqual(method.category, .kegel)
        XCTAssertEqual(method.difficulty, .beginner)
        XCTAssertEqual(method.steps.count, 3)
        XCTAssertEqual(method.precautions.count, 2)
        XCTAssertFalse(method.isFavorite)
    }
    
    /// 测试训练记录模型创建
    func testTrainingRecordCreation() {
        let methodId = UUID()
        let record = TrainingRecord(
            methodId: methodId,
            duration: 300,
            completionRate: 0.85,
            selfRating: 4,
            notes: "感觉良好",
            mode: .progressive
        )
        
        XCTAssertEqual(record.methodId, methodId)
        XCTAssertEqual(record.duration, 300)
        XCTAssertEqual(record.completionRate, 0.85, accuracy: 0.01)
        XCTAssertEqual(record.selfRating, 4)
        XCTAssertEqual(record.mode, .progressive)
    }
    
    /// 测试训练类别枚举
    func testTrainingCategoryEnum() {
        XCTAssertEqual(TrainingCategory.allCases.count, 5)
        XCTAssertEqual(TrainingCategory.kegel.rawValue, "凯格尔运动")
        XCTAssertEqual(TrainingCategory.stopStart.rawValue, "停-动技术")
    }
    
    /// 测试难度等级枚举
    func testDifficultyLevelEnum() {
        XCTAssertEqual(DifficultyLevel.allCases.count, 3)
        XCTAssertEqual(DifficultyLevel.beginner.color, "green")
        XCTAssertEqual(DifficultyLevel.advanced.color, "red")
    }
    
    /// 测试训练模式枚举
    func testTrainingModeEnum() {
        XCTAssertEqual(TrainingMode.allCases.count, 3)
        XCTAssertFalse(TrainingMode.basic.description.isEmpty)
    }
    
    // MARK: - Ability Profile Tests
    
    /// 测试能力档案创建
    func testAbilityProfileCreation() {
        let profile = AbilityProfile(
            overallScore: 55,
            endurance: 0.6,
            control: 0.7,
            recovery: 0.5,
            breathCoordination: 0.4,
            muscleStrength: 0.55
        )
        
        XCTAssertEqual(profile.overallScore, 55)
        XCTAssertEqual(profile.level, .intermediate)
        XCTAssertEqual(profile.dimensions.count, 5)
        XCTAssertEqual(AbilityProfile.dimensionNames.count, 5)
    }
    
    /// 测试能力等级映射
    func testAbilityLevelMapping() {
        XCTAssertEqual(AbilityLevel(score: 10), .entry)
        XCTAssertEqual(AbilityLevel(score: 25), .beginner)
        XCTAssertEqual(AbilityLevel(score: 50), .intermediate)
        XCTAssertEqual(AbilityLevel(score: 70), .advanced)
        XCTAssertEqual(AbilityLevel(score: 90), .expert)
    }
    
    // MARK: - Plan Models Tests
    
    /// 测试训练计划创建
    func testTrainingPlanCreation() {
        let plan = TrainingPlan(
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 3600),
            items: [],
            progress: 0,
            goal: "提升持久力"
        )
        
        XCTAssertEqual(plan.periodType, .week)
        XCTAssertEqual(plan.goal, "提升持久力")
        XCTAssertEqual(plan.progress, 0)
    }
    
    /// 测试计划进度更新
    func testPlanProgressUpdate() {
        let items = [
            PlanItem(date: Date(), methodId: UUID(), methodName: "凯格尔", duration: 300, isCompleted: true),
            PlanItem(date: Date(), methodId: UUID(), methodName: "呼吸训练", duration: 180, isCompleted: false),
            PlanItem(date: Date(), methodId: UUID(), methodName: "停-动技术", duration: 240, isCompleted: true)
        ]
        
        var plan = TrainingPlan(
            startDate: Date(),
            endDate: Date().addingTimeInterval(7 * 24 * 3600),
            items: items,
            goal: "测试"
        )
        
        plan.updateProgress()
        XCTAssertEqual(plan.progress, 2.0/3.0, accuracy: 0.01)
    }
    
    /// 测试计划周期类型
    func testPlanPeriodType() {
        let weekPlan = TrainingPlan(
            startDate: Date(),
            endDate: Date().addingTimeInterval(6 * 24 * 3600),
            goal: "周计划"
        )
        XCTAssertEqual(weekPlan.periodType, .week)
        
        let monthPlan = TrainingPlan(
            startDate: Date(),
            endDate: Date().addingTimeInterval(30 * 24 * 3600),
            goal: "月计划"
        )
        XCTAssertEqual(monthPlan.periodType, .month)
        
        let quarterPlan = TrainingPlan(
            startDate: Date(),
            endDate: Date().addingTimeInterval(90 * 24 * 3600),
            goal: "季度计划"
        )
        XCTAssertEqual(quarterPlan.periodType, .quarter)
    }
    
    /// 测试评估模型
    func testAssessmentModel() {
        let assessment = Assessment(
            age: 42,
            currentAbilityScore: 5,
            trainingExperience: .beginner,
            physicalCondition: .good,
            trainingGoal: .endurance
        )
        
        XCTAssertEqual(assessment.age, 42)
        XCTAssertEqual(assessment.currentAbilityScore, 5)
        XCTAssertEqual(assessment.trainingExperience, .beginner)
        XCTAssertEqual(assessment.physicalCondition, .good)
        XCTAssertEqual(assessment.trainingGoal, .endurance)
    }
    
    // MARK: - Check-in Model Tests
    
    /// 测试打卡记录创建
    func testCheckInRecordCreation() {
        let record = CheckInRecord()
        XCTAssertNotNil(record.id)
        XCTAssertNotNil(record.date)
        XCTAssertNotNil(record.checkInTime)
        XCTAssertNil(record.trainingRecordId)
    }
    
    /// 测试带训练记录的打卡
    func testCheckInWithTrainingRecord() {
        let trainingId = UUID()
        let record = CheckInRecord(trainingRecordId: trainingId)
        XCTAssertEqual(record.trainingRecordId, trainingId)
    }
    
    // MARK: - Review Note Tests
    
    /// 测试复盘笔记创建
    func testReviewNoteCreation() {
        let recordId = UUID()
        let note = ReviewNote(
            trainingRecordId: recordId,
            feelingScore: 4,
            difficultyScore: 3,
            bodyReaction: "轻微疲劳",
            notes: "今天状态不错"
        )
        
        XCTAssertEqual(note.trainingRecordId, recordId)
        XCTAssertEqual(note.feelingScore, 4)
        XCTAssertEqual(note.difficultyScore, 3)
        XCTAssertEqual(note.bodyReaction, "轻微疲劳")
    }
    
    // MARK: - Crypto Service Tests
    
    /// 测试加密解密字符串
    func testEncryptDecryptString() {
        let cryptoService = CryptoService.shared
        let plaintext = "这是一条敏感的训练备注信息"
        
        guard let encrypted = cryptoService.encrypt(plaintext) else {
            XCTFail("加密失败")
            return
        }
        
        XCTAssertNotEqual(encrypted, plaintext)
        XCTAssertFalse(encrypted.isEmpty)
        
        guard let decrypted = cryptoService.decrypt(encrypted) else {
            XCTFail("解密失败")
            return
        }
        
        XCTAssertEqual(decrypted, plaintext)
    }
    
    /// 测试空字符串加密
    func testEncryptEmptyString() {
        let cryptoService = CryptoService.shared
        let result = cryptoService.encrypt("")
        XCTAssertEqual(result, "")
    }
    
    /// 测试哈希功能
    func testHashing() {
        let cryptoService = CryptoService.shared
        let data = "测试数据".data(using: .utf8)!
        
        let hash1 = cryptoService.hash(data)
        let hash2 = cryptoService.hash(data)
        
        XCTAssertEqual(hash1, hash2)
        XCTAssertEqual(hash1.count, 64) // SHA256 = 64 hex chars
    }
    
    /// 测试数据完整性验证
    func testDataIntegrityValidation() {
        let validator = DataIntegrityValidator()
        let record = TrainingRecord(
            methodId: UUID(),
            duration: 300,
            completionRate: 0.85,
            selfRating: 4
        )
        
        let checksum = validator.generateChecksum(for: record)
        XCTAssertTrue(validator.validate(record: record, checksum: checksum))
        
        // 修改记录后校验应失败
        let differentRecord = TrainingRecord(
            methodId: UUID(),
            duration: 300,
            completionRate: 0.85,
            selfRating: 4
        )
        XCTAssertFalse(validator.validate(record: differentRecord, checksum: checksum))
    }
    
    // MARK: - Keychain Service Tests
    
    /// 测试Keychain基本存取
    func testKeychainSaveAndLoad() {
        let keychain = KeychainService.shared
        let testKey = "test_key_\(UUID().uuidString)"
        let testValue = "test_value_敏感数据"
        
        let saveResult = keychain.save(string: testValue, forKey: testKey)
        XCTAssertTrue(saveResult)
        
        let loadedValue = keychain.loadString(forKey: testKey)
        XCTAssertEqual(loadedValue, testValue)
        
        // 清理
        keychain.delete(forKey: testKey)
    }
    
    /// 测试Keychain Codable对象存取
    func testKeychainCodableObject() {
        let keychain = KeychainService.shared
        let testKey = "test_codable_\(UUID().uuidString)"
        
        let assessment = Assessment(
            age: 45,
            currentAbilityScore: 6,
            trainingExperience: .intermediate,
            physicalCondition: .good,
            trainingGoal: .control
        )
        
        let saveResult = keychain.save(object: assessment, forKey: testKey)
        XCTAssertTrue(saveResult)
        
        let loaded = keychain.loadObject(forKey: testKey, as: Assessment.self)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.age, 45)
        XCTAssertEqual(loaded?.trainingGoal, .control)
        
        // 清理
        keychain.delete(forKey: testKey)
    }
    
    /// 测试Keychain删除
    func testKeychainDelete() {
        let keychain = KeychainService.shared
        let testKey = "test_delete_\(UUID().uuidString)"
        
        keychain.save(string: "test", forKey: testKey)
        XCTAssertNotNil(keychain.loadString(forKey: testKey))
        
        let deleteResult = keychain.delete(forKey: testKey)
        XCTAssertTrue(deleteResult)
        XCTAssertNil(keychain.loadString(forKey: testKey))
    }
}
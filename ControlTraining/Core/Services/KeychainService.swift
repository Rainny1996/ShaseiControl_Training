import Foundation
import Security

/// Keychain服务，用于安全存储敏感数据
/// 测试环境下自动降级为内存字典存储（避免模拟器 Keychain 不可用）
class KeychainService {
    static let shared = KeychainService()
    
    private let service: String = "com.controltraining.security"

    /// 测试环境检测：XCTest 运行时回退到内存存储
    private var isTestEnvironment: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }
    private var memoryStore: [String: Data] = [:]
    
    private init() {}
    
    // MARK: - Basic Operations
    
    /// 保存数据到Keychain（测试环境使用内存字典）
    /// - Parameters:
    ///   - data: 要保存的数据
    ///   - key: 存储键名
    /// - Returns: 是否保存成功
    @discardableResult
    func save(data: Data, forKey key: String) -> Bool {
        if isTestEnvironment {
            memoryStore[key] = data
            return true
        }
        // 先删除已存在的项
        delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// 从Keychain读取数据
    /// - Parameter key: 存储键名
    /// - Returns: 存储的数据，不存在则返回nil
    func load(forKey key: String) -> Data? {
        if isTestEnvironment { return memoryStore[key] }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
    
    /// 从Keychain删除数据
    /// - Parameter key: 存储键名
    /// - Returns: 是否删除成功
    @discardableResult
    func delete(forKey key: String) -> Bool {
        if isTestEnvironment {
            memoryStore.removeValue(forKey: key)
            return true
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Convenience Methods (String)
    
    /// 保存字符串到Keychain
    @discardableResult
    func save(string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data: data, forKey: key)
    }
    
    /// 从Keychain读取字符串
    func loadString(forKey key: String) -> String? {
        guard let data = load(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Convenience Methods (Codable)
    
    /// 保存Codable对象到Keychain
    @discardableResult
    func save<T: Codable>(object: T, forKey key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(object) else { return false }
        return save(data: data, forKey: key)
    }
    
    /// 从Keychain读取Codable对象
    func loadObject<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = load(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    // MARK: - App Specific Keys
    
    /// Keychain存储键名常量
    enum KeychainKey: String {
        case userAuthToken = "user_auth_token"
        case assessmentData = "assessment_data"
        case userPreferences = "user_preferences"
        case encryptionKey = "encryption_key"
        case lastSyncTimestamp = "last_sync_timestamp"
        case appLockPIN = "app_lock_pin"
    }
    
    /// 保存用户认证令牌
    func saveAuthToken(_ token: String) -> Bool {
        return save(string: token, forKey: KeychainKey.userAuthToken.rawValue)
    }
    
    /// 读取用户认证令牌
    func loadAuthToken() -> String? {
        return loadString(forKey: KeychainKey.userAuthToken.rawValue)
    }
    
    /// 保存评估数据
    func saveAssessment(_ assessment: Assessment) -> Bool {
        return save(object: assessment, forKey: KeychainKey.assessmentData.rawValue)
    }
    
    /// 读取评估数据
    func loadAssessment() -> Assessment? {
        return loadObject(forKey: KeychainKey.assessmentData.rawValue, as: Assessment.self)
    }
    
    /// 保存应用锁PIN码
    func savePIN(_ pin: String) -> Bool {
        return save(string: pin, forKey: KeychainKey.appLockPIN.rawValue)
    }
    
    /// 读取应用锁PIN码
    func loadPIN() -> String? {
        return loadString(forKey: KeychainKey.appLockPIN.rawValue)
    }
    
    /// 验证PIN码
    func verifyPIN(_ pin: String) -> Bool {
        guard let storedPIN = loadPIN() else { return false }
        return storedPIN == pin
    }
    
    /// 清除所有敏感数据（用于隐私保护/退出登录）
    func clearAllSensitiveData() {
        let keys = [
            KeychainKey.userAuthToken.rawValue,
            KeychainKey.assessmentData.rawValue,
            KeychainKey.userPreferences.rawValue,
            KeychainKey.lastSyncTimestamp.rawValue,
            KeychainKey.appLockPIN.rawValue
        ]
        // 注意：不删除encryptionKey，因为可能还有加密数据需要解密
        for key in keys {
            delete(forKey: key)
        }
    }
}
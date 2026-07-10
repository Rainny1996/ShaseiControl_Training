import Foundation
import LocalAuthentication
import UIKit
import CryptoKit
import Security

/// 安全服务，负责隐私保护相关功能
class SecurityService {
    
    static let shared = SecurityService()
    
    private let keychainService = "com.controltraining.security"
    private let passwordKey = "appPassword"
    private let passwordSaltKey = "passwordSalt"
    
    private init() {}
    
    // MARK: - Biometric Authentication
    
    /// 使用Face ID/Touch ID进行身份验证
    /// - Parameter completion: 验证结果回调
    func authenticate(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // 不支持生物识别，尝试设备密码
            authenticateWithDevicePassword(completion: completion)
            return
        }
        
        let reason = "验证身份以访问训练数据"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    /// 使用设备密码验证
    private func authenticateWithDevicePassword(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            completion(false)
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "验证身份") { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    /// 检查设备是否支持生物识别
    var biometricType: LABiometryType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        return context.biometryType
    }
    
    /// 是否支持生物识别
    var isBiometricAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// 根据需要验证身份
    func authenticateIfNeeded() {
        let securityEnabled = isSecurityEnabled()
        guard securityEnabled else { return }
        
        authenticate { success in
            if !success {
                // 验证失败，保持锁定状态
            }
        }
    }
    
    // MARK: - Password Lock
    
    /// 设置应用密码
    /// - Parameter password: 密码字符串
    /// - Returns: 是否设置成功
    @discardableResult
    func setPassword(_ password: String) -> Bool {
        guard !password.isEmpty else { return false }
        
        // 生成随机盐
        let salt = generateRandomSalt()
        
        // 使用盐值哈希密码
        guard let hashedPassword = hashPassword(password, salt: salt) else { return false }
        
        // 存储盐值和哈希密码到Keychain
        let saltSaved = saveToKeychain(key: passwordSaltKey, data: salt)
        let passwordSaved = saveToKeychain(key: passwordKey, data: hashedPassword)
        
        if saltSaved && passwordSaved {
            UserDefaults.standard.set(true, forKey: "isPasswordSet")
            return true
        }
        return false
    }
    
    /// 验证密码
    /// - Parameter password: 输入的密码
    /// - Returns: 是否验证通过
    func verifyPassword(_ password: String) -> Bool {
        guard let storedSalt = loadFromKeychain(key: passwordSaltKey),
              let storedHash = loadFromKeychain(key: passwordKey) else {
            return false
        }
        
        guard let inputHash = hashPassword(password, salt: storedSalt) else {
            return false
        }
        
        return inputHash == storedHash
    }
    
    /// 删除密码
    func removePassword() {
        removeFromKeychain(key: passwordKey)
        removeFromKeychain(key: passwordSaltKey)
        UserDefaults.standard.set(false, forKey: "isPasswordSet")
    }
    
    /// 是否已设置密码
    var isPasswordSet: Bool {
        return UserDefaults.standard.bool(forKey: "isPasswordSet")
    }
    
    /// 使用密码或生物识别验证
    /// - Parameter completion: 验证结果
    func authenticateWithPasswordOrBiometric(completion: @escaping (Bool) -> Void) {
        let authMode = getAuthMode()
        
        switch authMode {
        case .biometric:
            authenticate(completion: completion)
        case .password:
            // 密码验证由UI层处理，这里返回需要密码验证
            completion(false)
        case .biometricAndPassword:
            // 优先生物识别，失败则由UI层切换到密码
            authenticate { success in
                if !success && self.isPasswordSet {
                    // 生物识别失败，通知UI显示密码输入
                    NotificationCenter.default.post(name: .showPasswordInput, object: nil)
                }
                completion(success)
            }
        case .none:
            completion(true)
        }
    }
    
    // MARK: - Auth Mode Management
    
    /// 认证模式
    enum AuthMode: String, CaseIterable {
        case none = "无保护"
        case biometric = "生物识别"
        case password = "密码锁"
        case biometricAndPassword = "生物识别+密码"
        
        var iconName: String {
            switch self {
            case .none: return "lock.open"
            case .biometric: return "faceid"
            case .password: return "lock"
            case .biometricAndPassword: return "lock.shield"
            }
        }
        
        var description: String {
            switch self {
            case .none: return "无需验证即可进入应用"
            case .biometric: return "使用Face ID或Touch ID解锁"
            case .password: return "使用数字密码解锁"
            case .biometricAndPassword: return "优先生物识别，备选密码解锁"
            }
        }
    }
    
    /// 获取当前认证模式
    func getAuthMode() -> AuthMode {
        let useFaceID = UserDefaults.standard.bool(forKey: "useFaceID")
        let usePassword = isPasswordSet
        
        if useFaceID && usePassword {
            return .biometricAndPassword
        } else if useFaceID {
            return .biometric
        } else if usePassword {
            return .password
        } else {
            return .none
        }
    }
    
    /// 设置认证模式
    func setAuthMode(_ mode: AuthMode) {
        switch mode {
        case .none:
            UserDefaults.standard.set(false, forKey: "useFaceID")
        case .biometric:
            UserDefaults.standard.set(true, forKey: "useFaceID")
        case .password:
            UserDefaults.standard.set(false, forKey: "useFaceID")
            // 密码需通过setPassword设置
        case .biometricAndPassword:
            UserDefaults.standard.set(true, forKey: "useFaceID")
            // 密码需通过setPassword设置
        }
    }
    
    /// 是否启用安全保护
    func isSecurityEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "useFaceID") || isPasswordSet
    }
    
    // MARK: - App Protection
    
    /// 配置应用保护
    func configureProtection() {
        // 仅监听前台返回事件（后台锁定由AppDelegate处理，避免双重触发）
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.unlockAppIfNeeded()
        }
    }
    
    /// 锁定应用
    func lockApp() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appDidLock, object: nil)
        }
    }
    
    /// 根据需要解锁应用
    private func unlockAppIfNeeded() {
        let securityEnabled = isSecurityEnabled()
        guard securityEnabled else {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .appDidUnlock, object: nil)
            }
            return
        }
        
        authenticateWithPasswordOrBiometric { success in
            if success {
                NotificationCenter.default.post(name: .appDidUnlock, object: nil)
            }
        }
    }
    
    // MARK: - Blur Protection
    
    /// 是否启用后台模糊保护
    var isBlurProtectionEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "blurProtectionEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "blurProtectionEnabled") }
    }
    
    // MARK: - Data Encryption
    
    /// 加密敏感数据（委托给CryptoService，统一加密入口）
    /// - Parameter data: 原始数据
    /// - Returns: 加密后的数据
    func encryptData(_ data: Data) -> Data? {
        return CryptoService.shared.encryptData(data)
    }
    
    /// 解密敏感数据（委托给CryptoService，统一加密入口）
    /// - Parameter encryptedData: 加密数据
    /// - Returns: 解密后的数据
    func decryptData(_ encryptedData: Data) -> Data? {
        return CryptoService.shared.decryptData(encryptedData)
    }
    
    /// 安全删除数据
    /// - Parameter data: 要删除的数据
    func secureDelete(_ data: Data) {
        var mutableData = data
        let count = mutableData.count
        memset(&mutableData, 0, count)
    }
    
    // MARK: - Private Helpers
    
    /// 生成随机盐值
    private func generateRandomSalt() -> Data {
        var salt = Data(count: 32)
        salt.withUnsafeMutableBytes { saltBytes in
            _ = SecRandomCopyBytes(kSecRandomDefault, 32, saltBytes.baseAddress!)
        }
        return salt
    }
    
    /// 使用SHA256哈希密码
    private func hashPassword(_ password: String, salt: Data) -> Data? {
        guard let passwordData = password.data(using: .utf8) else { return nil }
        var combinedData = salt
        combinedData.append(passwordData)
        
        let hashed = SHA256.hash(data: combinedData)
        return Data(hashed)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let appDidLock = Notification.Name("appDidLock")
    static let appDidUnlock = Notification.Name("appDidUnlock")
    static let showPasswordInput = Notification.Name("showPasswordInput")
}
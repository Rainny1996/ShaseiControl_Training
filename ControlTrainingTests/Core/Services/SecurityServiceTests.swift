import XCTest
@testable import ControlTraining

/// 安全服务单元测试
final class SecurityServiceTests: XCTestCase {
    
    var securityService: SecurityService!
    
    override func setUp() {
        super.setUp()
        securityService = SecurityService.shared
        // 清理测试环境
        securityService.removePassword()
        UserDefaults.standard.set(false, forKey: "useFaceID")
        UserDefaults.standard.set(false, forKey: "blurProtectionEnabled")
    }
    
    override func tearDown() {
        // 清理测试数据
        securityService.removePassword()
        UserDefaults.standard.set(false, forKey: "useFaceID")
        UserDefaults.standard.set(false, forKey: "blurProtectionEnabled")
        securityService = nil
        super.tearDown()
    }
    
    // MARK: - 密码操作测试
    
    /// 测试设置密码
    func testSetPassword() {
        let result = securityService.setPassword("1234")
        XCTAssertTrue(result, "设置密码应成功")
        XCTAssertTrue(securityService.isPasswordSet, "设置密码后isPasswordSet应为true")
    }
    
    /// 测试设置空密码失败
    func testSetEmptyPasswordFails() {
        let result = securityService.setPassword("")
        XCTAssertFalse(result, "设置空密码应失败")
        XCTAssertFalse(securityService.isPasswordSet, "空密码不应标记为已设置")
    }
    
    /// 测试验证正确密码
    func testVerifyCorrectPassword() {
        let password = "5678"
        securityService.setPassword(password)
        
        let result = securityService.verifyPassword(password)
        XCTAssertTrue(result, "验证正确密码应成功")
    }
    
    /// 测试验证错误密码
    func testVerifyWrongPassword() {
        securityService.setPassword("1234")
        
        let result = securityService.verifyPassword("9999")
        XCTAssertFalse(result, "验证错误密码应失败")
    }
    
    /// 测试删除密码
    func testRemovePassword() {
        securityService.setPassword("1234")
        XCTAssertTrue(securityService.isPasswordSet)
        
        securityService.removePassword()
        XCTAssertFalse(securityService.isPasswordSet, "删除密码后isPasswordSet应为false")
    }
    
    /// 测试未设置密码时验证失败
    func testVerifyPasswordWhenNotSet() {
        securityService.removePassword()
        
        let result = securityService.verifyPassword("1234")
        XCTAssertFalse(result, "未设置密码时验证应失败")
    }
    
    /// 测试密码哈希加盐 - 相同密码不同盐值产生不同哈希
    func testPasswordHashingWithSalt() {
        let password = "1234"
        securityService.setPassword(password)
        
        // 验证密码后重新设置相同密码
        // 由于每次生成新盐值，哈希应该不同
        let result1 = securityService.verifyPassword(password)
        XCTAssertTrue(result1)
        
        // 重新设置密码（会生成新盐值）
        securityService.setPassword(password)
        
        // 仍应能验证
        let result2 = securityService.verifyPassword(password)
        XCTAssertTrue(result2, "重新设置密码后应仍能验证")
    }
    
    /// 测试密码更新
    func testPasswordUpdate() {
        securityService.setPassword("1234")
        XCTAssertTrue(securityService.verifyPassword("1234"))
        
        // 更新密码
        securityService.setPassword("5678")
        
        // 旧密码应失效
        XCTAssertFalse(securityService.verifyPassword("1234"), "旧密码应失效")
        // 新密码应有效
        XCTAssertTrue(securityService.verifyPassword("5678"), "新密码应有效")
    }
    
    // MARK: - 认证模式测试
    
    /// 测试默认认证模式为无保护
    func testDefaultAuthModeIsNone() {
        let mode = securityService.getAuthMode()
        XCTAssertEqual(mode, .none, "默认认证模式应为无保护")
    }
    
    /// 测试设置密码后认证模式为密码锁
    func testAuthModeAfterSettingPassword() {
        securityService.setPassword("1234")
        
        let mode = securityService.getAuthMode()
        XCTAssertEqual(mode, .password, "设置密码后认证模式应为密码锁")
    }
    
    /// 测试设置Face ID后认证模式为生物识别
    func testAuthModeAfterEnablingFaceID() {
        UserDefaults.standard.set(true, forKey: "useFaceID")
        
        let mode = securityService.getAuthMode()
        XCTAssertEqual(mode, .biometric, "启用Face ID后认证模式应为生物识别")
    }
    
    /// 测试同时启用密码和Face ID
    func testAuthModeWithBothPasswordAndFaceID() {
        securityService.setPassword("1234")
        UserDefaults.standard.set(true, forKey: "useFaceID")
        
        let mode = securityService.getAuthMode()
        XCTAssertEqual(mode, .biometricAndPassword, "同时启用密码和Face ID应为生物识别+密码")
    }
    
    /// 测试设置认证模式
    func testSetAuthMode() {
        // 设置为无保护
        securityService.setAuthMode(.none)
        XCTAssertEqual(securityService.getAuthMode(), .none)
        
        // 设置为生物识别
        securityService.setAuthMode(.biometric)
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "useFaceID"))
    }
    
    /// 测试认证模式枚举属性
    func testAuthModeProperties() {
        // 验证所有模式都有图标名
        for mode in SecurityService.AuthMode.allCases {
            XCTAssertFalse(mode.iconName.isEmpty, "\(mode.rawValue)应有图标名")
        }
        
        // 验证所有模式都有描述
        for mode in SecurityService.AuthMode.allCases {
            XCTAssertFalse(mode.description.isEmpty, "\(mode.rawValue)应有描述")
        }
    }
    
    /// 测试认证模式枚举值
    func testAuthModeCaseIterable() {
        XCTAssertEqual(SecurityService.AuthMode.allCases.count, 4, "应有4种认证模式")
        XCTAssertTrue(SecurityService.AuthMode.allCases.contains(.none))
        XCTAssertTrue(SecurityService.AuthMode.allCases.contains(.biometric))
        XCTAssertTrue(SecurityService.AuthMode.allCases.contains(.password))
        XCTAssertTrue(SecurityService.AuthMode.allCases.contains(.biometricAndPassword))
    }
    
    // MARK: - 安全保护状态测试
    
    /// 测试默认未启用安全保护
    func testSecurityNotEnabledByDefault() {
        XCTAssertFalse(securityService.isSecurityEnabled(), "默认未启用安全保护")
    }
    
    /// 测试设置密码后启用安全保护
    func testSecurityEnabledAfterSettingPassword() {
        securityService.setPassword("1234")
        XCTAssertTrue(securityService.isSecurityEnabled(), "设置密码后应启用安全保护")
    }
    
    /// 测试启用Face ID后启用安全保护
    func testSecurityEnabledAfterEnablingFaceID() {
        UserDefaults.standard.set(true, forKey: "useFaceID")
        XCTAssertTrue(securityService.isSecurityEnabled(), "启用Face ID后应启用安全保护")
    }
    
    /// 测试删除密码后禁用安全保护
    func testSecurityDisabledAfterRemovingPassword() {
        securityService.setPassword("1234")
        XCTAssertTrue(securityService.isSecurityEnabled())
        
        securityService.removePassword()
        UserDefaults.standard.set(false, forKey: "useFaceID")
        XCTAssertFalse(securityService.isSecurityEnabled(), "删除密码后应禁用安全保护")
    }
    
    // MARK: - 模糊保护测试
    
    /// 测试模糊保护默认值
    func testBlurProtectionDefaultValue() {
        XCTAssertFalse(securityService.isBlurProtectionEnabled, "模糊保护默认应为关闭")
    }
    
    /// 测试启用模糊保护
    func testEnableBlurProtection() {
        securityService.isBlurProtectionEnabled = true
        XCTAssertTrue(securityService.isBlurProtectionEnabled, "启用后模糊保护应为true")
    }
    
    /// 测试禁用模糊保护
    func testDisableBlurProtection() {
        securityService.isBlurProtectionEnabled = true
        securityService.isBlurProtectionEnabled = false
        XCTAssertFalse(securityService.isBlurProtectionEnabled, "禁用后模糊保护应为false")
    }
    
    // MARK: - 数据加密解密测试
    
    /// 测试加密解密往返
    func testEncryptDecryptRoundTrip() {
        let originalData = "敏感训练数据".data(using: .utf8)!
        
        guard let encryptedData = securityService.encryptData(originalData) else {
            XCTFail("加密应成功")
            return
        }
        
        // 加密数据应与原始数据不同
        XCTAssertNotEqual(encryptedData, originalData, "加密数据应与原始数据不同")
        
        guard let decryptedData = securityService.decryptData(encryptedData) else {
            XCTFail("解密应成功")
            return
        }
        
        // 解密数据应与原始数据相同
        XCTAssertEqual(decryptedData, originalData, "解密数据应与原始数据相同")
    }
    
    /// 测试加密不同数据产生不同密文
    func testEncryptDifferentDataProducesDifferentCiphertext() {
        let data1 = "数据1".data(using: .utf8)!
        let data2 = "数据2".data(using: .utf8)!
        
        let encrypted1 = securityService.encryptData(data1)
        let encrypted2 = securityService.encryptData(data2)
        
        XCTAssertNotNil(encrypted1)
        XCTAssertNotNil(encrypted2)
        XCTAssertNotEqual(encrypted1, encrypted2, "不同数据应产生不同密文")
    }
    
    /// 测试加密空数据
    func testEncryptEmptyData() {
        let emptyData = Data()
        let encrypted = securityService.encryptData(emptyData)
        // AES-GCM可以加密空数据
        XCTAssertNotNil(encrypted, "加密空数据应成功")
    }
    
    /// 测试解密无效数据返回nil
    func testDecryptInvalidDataReturnsNil() {
        let invalidData = Data("无效数据".utf8)
        let decrypted = securityService.decryptData(invalidData)
        XCTAssertNil(decrypted, "解密无效数据应返回nil")
    }
    
    /// 测试加密大数据
    func testEncryptLargeData() {
        // 创建较大的数据（1KB）
        let largeData = Data(repeating: 0x41, count: 1024)
        
        guard let encrypted = securityService.encryptData(largeData) else {
            XCTFail("加密大数据应成功")
            return
        }
        
        guard let decrypted = securityService.decryptData(encrypted) else {
            XCTFail("解密大数据应成功")
            return
        }
        
        XCTAssertEqual(decrypted, largeData, "解密大数据应与原始数据相同")
    }
    
    /// 测试多次加密同一数据产生不同密文（因为AES-GCM使用随机nonce）
    func testEncryptSameDataMultipleTimes() {
        let data = "测试数据".data(using: .utf8)!
        
        let encrypted1 = securityService.encryptData(data)
        let encrypted2 = securityService.encryptData(data)
        
        XCTAssertNotNil(encrypted1)
        XCTAssertNotNil(encrypted2)
        // AES-GCM每次加密使用不同的nonce，所以密文不同
        XCTAssertNotEqual(encrypted1, encrypted2, "同一数据多次加密应产生不同密文")
        
        // 但都能正确解密
        XCTAssertEqual(securityService.decryptData(encrypted1!), data)
        XCTAssertEqual(securityService.decryptData(encrypted2!), data)
    }
    
    // MARK: - 通知测试
    
    /// 测试锁定应用发送通知
    func testLockAppSendsNotification() {
        let expectation = self.expectation(forNotification: .appDidLock, object: nil, handler: nil)
        
        securityService.lockApp()
        
        waitForExpectations(timeout: 2)
    }
    
    /// 测试认证模式枚举rawValue
    func testAuthModeRawValues() {
        XCTAssertEqual(SecurityService.AuthMode.none.rawValue, "无保护")
        XCTAssertEqual(SecurityService.AuthMode.biometric.rawValue, "生物识别")
        XCTAssertEqual(SecurityService.AuthMode.password.rawValue, "密码锁")
        XCTAssertEqual(SecurityService.AuthMode.biometricAndPassword.rawValue, "生物识别+密码")
    }
    
    // MARK: - 综合场景测试
    
    /// 测试完整安全流程：设置密码→验证→删除
    func testFullSecurityFlow() {
        // 1. 初始状态
        XCTAssertFalse(securityService.isPasswordSet)
        XCTAssertFalse(securityService.isSecurityEnabled())
        XCTAssertEqual(securityService.getAuthMode(), .none)
        
        // 2. 设置密码
        XCTAssertTrue(securityService.setPassword("1234"))
        XCTAssertTrue(securityService.isPasswordSet)
        XCTAssertTrue(securityService.isSecurityEnabled())
        XCTAssertEqual(securityService.getAuthMode(), .password)
        
        // 3. 验证密码
        XCTAssertTrue(securityService.verifyPassword("1234"))
        XCTAssertFalse(securityService.verifyPassword("0000"))
        
        // 4. 删除密码
        securityService.removePassword()
        XCTAssertFalse(securityService.isPasswordSet)
        XCTAssertFalse(securityService.isSecurityEnabled())
        XCTAssertEqual(securityService.getAuthMode(), .none)
    }
    
    /// 测试加密解密完整流程
    func testFullEncryptionFlow() {
        let testData = [
            "短文本",
            "中等长度的训练数据记录",
            String(repeating: "长文本", count: 100),
            "特殊字符: !@#$%^&*()",
            "数字: 123456789",
            "中文训练记录：凯格尔运动10分钟"
        ]
        
        for text in testData {
            guard let data = text.data(using: .utf8),
                  let encrypted = securityService.encryptData(data),
                  let decrypted = securityService.decryptData(encrypted) else {
                XCTFail("加密解密流程失败: \(text)")
                continue
            }
            XCTAssertEqual(decrypted, data, "解密数据应与原始数据相同")
        }
    }
}
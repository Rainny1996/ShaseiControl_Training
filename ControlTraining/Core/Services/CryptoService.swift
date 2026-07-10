import Foundation
import CryptoKit

/// 数据加密服务，使用CryptoKit实现敏感字段加密
/// 用于加密训练记录备注、复盘笔记等敏感文本
class CryptoService {
    static let shared = CryptoService()
    
    private let keyService = KeychainService.shared
    
    private init() {}
    
    // MARK: - Key Management
    
    /// 获取或创建加密密钥
    /// - Returns: AES密钥
    private func getOrCreateKey() -> SymmetricKey? {
        let keyKey = KeychainService.KeychainKey.encryptionKey.rawValue
        
        // 尝试从Keychain加载已有密钥
        if let keyData = keyService.load(forKey: keyKey) {
            return SymmetricKey(data: keyData)
        }
        
        // 创建新密钥并保存
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        if keyService.save(data: keyData, forKey: keyKey) {
            return newKey
        }
        
        return nil
    }
    
    // MARK: - Encryption/Decryption
    
    /// 加密字符串
    /// - Parameter plaintext: 明文字符串
    /// - Returns: 加密后的Base64编码字符串，失败返回nil
    func encrypt(_ plaintext: String) -> String? {
        guard !plaintext.isEmpty else { return "" }
        guard let key = getOrCreateKey(),
              let data = plaintext.data(using: .utf8) else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined?.base64EncodedString()
        } catch {
            print("Encryption failed: \(error)")
            return nil
        }
    }
    
    /// 解密字符串
    /// - Parameter ciphertext: Base64编码的密文字符串
    /// - Returns: 解密后的明文字符串，失败返回nil
    func decrypt(_ ciphertext: String) -> String? {
        guard !ciphertext.isEmpty else { return "" }
        guard let key = getOrCreateKey(),
              let data = Data(base64Encoded: ciphertext) else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("Decryption failed: \(error)")
            return nil
        }
    }
    
    /// 加密数据
    /// - Parameter data: 原始数据
    /// - Returns: 加密后的数据，失败返回nil
    func encryptData(_ data: Data) -> Data? {
        guard let key = getOrCreateKey() else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Data encryption failed: \(error)")
            return nil
        }
    }
    
    /// 解密数据
    /// - Parameter encryptedData: 加密的数据
    /// - Returns: 解密后的原始数据，失败返回nil
    func decryptData(_ encryptedData: Data) -> Data? {
        guard let key = getOrCreateKey() else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            print("Data decryption failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Codable Encryption
    
    /// 加密Codable对象为Base64字符串
    /// - Parameter object: 要加密的对象
    /// - Returns: 加密后的Base64字符串
    func encryptObject<T: Codable>(_ object: T) -> String? {
        guard let data = try? JSONEncoder().encode(object) else { return nil }
        guard let encrypted = encryptData(data) else { return nil }
        return encrypted.base64EncodedString()
    }
    
    /// 解密Base64字符串为Codable对象
    /// - Parameters:
    ///   - ciphertext: 加密的Base64字符串
    ///   - type: 目标类型
    /// - Returns: 解密后的对象
    func decryptObject<T: Codable>(_ ciphertext: String, as type: T.Type) -> T? {
        guard let data = Data(base64Encoded: ciphertext) else { return nil }
        guard let decrypted = decryptData(data) else { return nil }
        return try? JSONDecoder().decode(type, from: decrypted)
    }
    
    // MARK: - Hashing
    
    /// 生成数据的SHA256哈希值
    /// - Parameter data: 原始数据
    /// - Returns: 哈希值的十六进制字符串
    func hash(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// 生成字符串的SHA256哈希值
    /// - Parameter string: 原始字符串
    /// - Returns: 哈希值的十六进制字符串
    func hash(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        return hash(data)
    }
    
    /// 验证数据完整性
    /// - Parameters:
    ///   - data: 原始数据
    ///   - expectedHash: 预期的哈希值
    /// - Returns: 是否匹配
    func verifyIntegrity(_ data: Data, against expectedHash: String) -> Bool {
        return hash(data) == expectedHash
    }
}

// MARK: - Encrypted Field Wrapper

/// 加密字段包装器，用于自动加密/解密敏感字段
@propertyWrapper
struct EncryptedField: Codable {
    private var encryptedValue: String?
    
    var wrappedValue: String {
        get {
            guard let encrypted = encryptedValue else { return "" }
            return CryptoService.shared.decrypt(encrypted) ?? ""
        }
        set {
            encryptedValue = CryptoService.shared.encrypt(newValue)
        }
    }
    
    init(wrappedValue: String) {
        self.encryptedValue = CryptoService.shared.encrypt(wrappedValue)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        encryptedValue = try container.decodeIfPresent(String.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(encryptedValue)
    }
}

// MARK: - Data Integrity Validator

/// 数据完整性验证器
struct DataIntegrityValidator {
    private let cryptoService = CryptoService.shared
    
    /// 为训练记录生成完整性校验值
    func generateChecksum(for record: TrainingRecord) -> String {
        let data = "\(record.id.uuidString)\(record.methodId.uuidString)\(record.duration)\(record.completionRate)\(record.selfRating)"
        return cryptoService.hash(data)
    }
    
    /// 验证训练记录的完整性
    func validate(record: TrainingRecord, checksum: String) -> Bool {
        return generateChecksum(for: record) == checksum
    }
    
    /// 为复盘笔记生成完整性校验值
    func generateChecksum(for note: ReviewNote) -> String {
        let data = "\(note.id.uuidString)\(note.trainingRecordId.uuidString)\(note.feelingScore)\(note.difficultyScore)"
        return cryptoService.hash(data)
    }
    
    /// 验证复盘笔记的完整性
    func validate(note: ReviewNote, checksum: String) -> Bool {
        return generateChecksum(for: note) == checksum
    }
}
import SwiftUI
import CoreData
import CryptoKit
import UniformTypeIdentifiers

/// 数据管理 ViewModel — 加密导出 / 从文件恢复 / 彻底删除
/// AC: 8.1–8.5
@MainActor
final class DataViewModel: ObservableObject {
    @Published var isExporting = false
    @Published var isImporting = false
    @Published var isDeleting = false
    @Published var showDeleteConfirmation = false
    @Published var exportURL: URL?
    @Published var showActivity = false
    @Published var errorMessage: String?
    @Published var showingError = false

    private let dataController = DataController.shared
    private let cryptoService = CryptoService.shared
    private let keychainService = KeychainService.shared

    // MARK: - Export (AC-8.1)

    /// 加密导出所有用户数据为文件
    func exportData(authCompleted: @escaping (URL?) -> Void) {
        isExporting = true

        // 生物识别或密码确认
        SecurityService.shared.authenticate { [weak self] success in
            guard let self = self, success else {
                self?.isExporting = false
                self?.showError("身份验证失败，无法导出数据")
                authCompleted(nil)
                return
            }

            Task {
                let url = await self.performExport()
                await MainActor.run {
                    self.isExporting = false
                    self.exportURL = url
                    authCompleted(url)
                }
            }
        }
    }

    private func performExport() async -> URL? {
        return await Task.detached(priority: .userInitiated) {
            let context = DataController.shared.newBackgroundContext()

            do {
                // 1. 读取所有实体数据
                let exports = self.collectAllData(in: context)

                // 2. 序列化为 JSON
                let jsonData = try JSONEncoder().encode(exports)

                // 3. AES-256-GCM 二次加密
                guard let sealedBox = try self.cryptoService.encryptData(jsonData) else {
                    await MainActor.run { self.showError("导出加密失败") }
                    return nil
                }

                // 4. 写入临时文件
                let tempDir = FileManager.default.temporaryDirectory
                let fileName = "ControlTraining_Backup_\(DateFormatter.backup.string(from: Date())).ctbak"
                let fileURL = tempDir.appendingPathComponent(fileName)
                try sealedBox.write(to: fileURL)

                return fileURL
            } catch {
                await MainActor.run {
                    self.showError("导出失败: \(error.localizedDescription)")
                }
                return nil
            }
        }.value
    }

    // MARK: - Import (AC-8.2)

    /// 从加密备份文件恢复数据
    func importData(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            showError("无法访问所选文件")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        isImporting = true

        // 生物识别或密码确认
        SecurityService.shared.authenticate { [weak self] success in
            guard let self = self, success else {
                self?.isImporting = false
                self?.showError("身份验证失败，无法恢复数据")
                return
            }

            Task {
                await self.performImport(from: url)
                await MainActor.run { self.isImporting = false }
            }
        }
    }

    private func performImport(from url: URL) async {
        await Task.detached(priority: .userInitiated) {
            do {
                let sealedBox = try Data(contentsOf: url)
                guard let jsonData = try CryptoService.shared.decryptData(sealedBox) else {
                    throw DataError.invalidBackup
                }
                let exports = try JSONDecoder().decode(DataExport.self, from: jsonData)

                // 完整性校验: 至少有一类数据非空才视为有效备份
                guard !exports.trainingRecords.isEmpty || !exports.checkInRecords.isEmpty else {
                    throw DataError.invalidBackup
                }

                try await self.writeImportedData(exports)
            } catch {
                await MainActor.run {
                    self.showError("恢复失败: \(error.localizedDescription)")
                }
            }
        }.value
    }

    private func writeImportedData(_ exports: DataExport) async throws {
        let context = DataController.shared.newBackgroundContext()

        try await context.perform {
            for record in exports.trainingRecords {
                let cd = CDTrainingRecord(context: context)
                cd.id = record.id
                cd.methodId = record.methodId
                cd.date = record.date
                cd.duration = record.duration
                cd.completionRate = record.completionRate
                cd.selfRating = Int16(record.selfRating.clamped(1...5))
                cd.isPartial = record.isPartial ?? false
                cd.notes = record.notes
            }
            for checkIn in exports.checkInRecords {
                let cd = CDCheckInRecord(context: context)
                cd.id = checkIn.id
                cd.date = checkIn.date
                cd.checkInTime = checkIn.checkInTime
            }
            try context.save()
        }
    }

    // MARK: - Delete All (AC-8.3, AC-8.4)

    /// 显示删除确认对话框
    func requestDeleteAll() {
        showDeleteConfirmation = true
    }

    /// 执行彻底删除
    func deleteAllUserData() {
        isDeleting = true

        SecurityService.shared.authenticate { [weak self] success in
            guard let self = self, success else {
                self?.isDeleting = false
                self?.showError("身份验证失败，无法删除数据")
                return
            }

            self.performDelete()
        }
    }

    private func performDelete() {
        // 1. Core Data 批量删除（含 viewContext.reset()）
        dataController.deleteAllUserData()

        // 2. 清理 Keychain
        keychainService.clearAllSensitiveData()

        // 3. 重置 UserDefaults 偏好（保留基础标记）
        let domain = Bundle.main.bundleIdentifier ?? ""
        UserDefaults.standard.removePersistentDomain(forName: domain)

        // 4. 重置应用状态
        DispatchQueue.main.async {
            self.isDeleting = false
            self.showDeleteConfirmation = false
        }
    }

    // MARK: - Helpers

    private func collectAllData(in context: NSManagedObjectContext) -> DataExport {
        var exports = DataExport()

        let trainingRequest: NSFetchRequest<CDTrainingRecord> = CDTrainingRecord.fetchRequest()
        if let records = try? context.fetch(trainingRequest) {
            exports.trainingRecords = records.map {
                RecordEntry(id: $0.id ?? UUID(), methodId: $0.methodId ?? UUID(), date: $0.date ?? Date(),
                            duration: $0.duration, completionRate: $0.completionRate,
                            selfRating: Int($0.selfRating), isPartial: $0.isPartial, notes: $0.notes)
            }
        }

        let checkInRequest: NSFetchRequest<CDCheckInRecord> = CDCheckInRecord.fetchRequest()
        if let records = try? context.fetch(checkInRequest) {
            exports.checkInRecords = records.map {
                CheckInEntry(id: $0.id ?? UUID(), date: $0.date ?? Date(),
                             checkInTime: $0.checkInTime ?? Date())
            }
        }

        return exports
    }

    func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Data Export Model

struct DataExport: Codable {
    var trainingRecords: [RecordEntry] = []
    var checkInRecords: [CheckInEntry] = []
}

struct RecordEntry: Codable {
    let id: UUID
    let methodId: UUID
    let date: Date
    let duration: Double
    let completionRate: Double
    let selfRating: Int
    let isPartial: Bool?
    let notes: String?
}

struct CheckInEntry: Codable {
    let id: UUID
    let date: Date
    let checkInTime: Date
}

enum DataError: LocalizedError {
    case invalidBackup
    var errorDescription: String? { "备份文件无效或已损坏" }
}

extension DateFormatter {
    static let backup: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f
    }()
}

extension Int {
    func clamped(_ range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

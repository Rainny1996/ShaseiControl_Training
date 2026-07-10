import SwiftUI
import Combine

/// 设置偏好键名枚举（集中管理，呼应 S04）
enum SettingsKey: String {
    case trainingReminderEnabled   = "com.controltraining.reminder.enabled"
    case biometricEnabled          = "com.controltraining.biometric.enabled"
    case fontSize                  = "com.controltraining.fontSize"
    case breathGuideDefault        = "com.controltraining.breathGuide.default"
    case makeupLimit               = "com.controltraining.makeup.limit"
}

/// 字号偏好枚举
enum FontSizePreference: String, CaseIterable {
    case standard = "标准"
    case large    = "大"
    case extraLarge = "超大"

    var multiplier: CGFloat {
        switch self {
        case .standard:   return 1.0
        case .large:      return 1.3
        case .extraLarge: return 1.6
        }
    }

    var displayName: String { rawValue }
}

/// 设置 ViewModel — 管理用户偏好与无障碍
/// AC: 9.1–9.4, NF.4–NF.6
@MainActor
final class SettingsViewModel: ObservableObject {
    // 设置状态
    @Published var isReminderEnabled = true
    @Published var isBiometricEnabled = true
    @Published var fontSize: FontSizePreference = .large  // 默认大号
    @Published var isBreathGuideDefaultEnabled = true
    @Published var makeupLimit = 3  // 默认每月 3 次补签

    private let defaults = UserDefaults.standard

    init() {
        loadSettings()
    }

    // MARK: - AC-9.1 / AC-9.2: 持久化读写

    func loadSettings() {
        isReminderEnabled = defaults.object(forKey: SettingsKey.trainingReminderEnabled.rawValue) as? Bool ?? true
        isBiometricEnabled = defaults.object(forKey: SettingsKey.biometricEnabled.rawValue) as? Bool ?? true
        let rawSize = defaults.string(forKey: SettingsKey.fontSize.rawValue) ?? FontSizePreference.large.rawValue
        fontSize = FontSizePreference(rawValue: rawSize) ?? .large
        isBreathGuideDefaultEnabled = defaults.object(forKey: SettingsKey.breathGuideDefault.rawValue) as? Bool ?? true
        makeupLimit = defaults.integer(forKey: SettingsKey.makeupLimit.rawValue)
        if makeupLimit == 0 { makeupLimit = 3 }
    }

    func toggleReminder(_ enabled: Bool) {
        isReminderEnabled = enabled
        defaults.set(enabled, forKey: SettingsKey.trainingReminderEnabled.rawValue)
        if enabled {
            NotificationService.shared.requestAuthorization()
        } else {
            NotificationService.shared.cancelAllNotifications()
        }
    }

    func toggleBiometric(_ enabled: Bool) {
        isBiometricEnabled = enabled
        defaults.set(enabled, forKey: SettingsKey.biometricEnabled.rawValue)
        UserDefaults.standard.set(enabled, forKey: "useFaceID")
    }

    func updateFontSize(_ size: FontSizePreference) {
        fontSize = size
        defaults.set(size.rawValue, forKey: SettingsKey.fontSize.rawValue)
        // AC-9.3: 字号立即全局生效
        SizeCategoryEnvironment.updateGlobally(to: size)
    }

    func toggleBreathGuideDefault(_ enabled: Bool) {
        isBreathGuideDefaultEnabled = enabled
        defaults.set(enabled, forKey: SettingsKey.breathGuideDefault.rawValue)
    }

    func updateMakeupLimit(_ limit: Int) {
        let clamped = max(0, min(limit, 10))
        makeupLimit = clamped
        defaults.set(clamped, forKey: SettingsKey.makeupLimit.rawValue)
    }
}

/// Dynamic Type 全局联动辅助（AC-9.3）
enum SizeCategoryEnvironment {
    static func updateGlobally(to size: FontSizePreference) {
        // 通过 UserDefaults 传递字号配置，各 View 通过 @AppStorage 读取
        // 此为集中入口，实际 UI 响应在各自 View 中通过修饰器完成
    }
}

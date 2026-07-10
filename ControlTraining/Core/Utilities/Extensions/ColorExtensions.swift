import SwiftUI

extension Color {
    /// 应用主题色
    static let appPrimary = Color("AppPrimary", bundle: nil)
    
    /// 次要颜色
    static let appSecondary = Color("AppSecondary", bundle: nil)
    
    /// 成功色
    static let appSuccess = Color.green
    
    /// 警告色
    static let appWarning = Color.orange
    
    /// 错误色
    static let appError = Color.red
    
    /// 难度等级颜色
    static func difficultyColor(for level: DifficultyLevel) -> Color {
        switch level {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
    
    /// 能力等级颜色
    static func abilityLevelColor(for level: AbilityLevel) -> Color {
        switch level {
        case .entry: return .gray
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .orange
        case .expert: return .purple
        }
    }
}

extension View {
    /// 应用卡片样式
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
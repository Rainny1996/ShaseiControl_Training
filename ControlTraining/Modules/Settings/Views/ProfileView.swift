import SwiftUI
import CoreData
import UIKit

/// 我的页面视图
struct ProfileView: View {
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 能力概览
                    abilityOverviewSection
                    
                    // 数据统计
                    statisticsSection
                    
                    // 功能列表
                    featuresSection
                }
                .padding()
            }
            .navigationTitle("我的")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                ProfileSettingsView()
            }
        }
    }
    
    // MARK: - 能力概览
    
    private var abilityOverviewSection: some View {
        VStack(spacing: 16) {
            Text("能力雷达图")
                .font(.headline)
            
            // 雷达图占位
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 1)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 1)
                    .frame(width: 130, height: 130)
                
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 1)
                    .frame(width: 60, height: 60)
                
                Text("能力分析")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 数据统计
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("训练统计")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(title: "总训练次数", value: "0")
                StatCard(title: "总训练时长", value: "0分钟")
                StatCard(title: "连续打卡", value: "0天")
                StatCard(title: "能力评分", value: "0")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 功能列表
    
    private var featuresSection: some View {
        VStack(spacing: 0) {
            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "复盘报告", destination: Text("复盘报告"))
            Divider().padding(.leading, 44)
            FeatureRow(icon: "doc.text", title: "训练记录", destination: Text("训练记录"))
            Divider().padding(.leading, 44)
            FeatureRow(icon: "bell", title: "训练提醒", destination: Text("训练提醒"))
            Divider().padding(.leading, 44)
            FeatureRow(icon: "lock.shield", title: "隐私设置", destination: PrivacySettingsView())
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

/// 统计卡片
struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// 功能行
struct FeatureRow<D: View>: View {
    let icon: String
    let title: String
    let destination: D
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 28)
                
                Text(title)
                    .font(.body)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

/// 设置视图
struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("useFaceID") private var useFaceID = true
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("blurProtectionEnabled") private var blurProtectionEnabled = true
    
    @State private var showDeleteConfirmation = false
    @State private var showExportSuccess = false
    @State private var showDeleteSuccess = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("隐私安全") {
                    Toggle("Face ID / Touch ID", isOn: $useFaceID)
                    Toggle("后台模糊保护", isOn: $blurProtectionEnabled)
                    NavigationLink(destination: PrivacySettingsView()) {
                        HStack {
                            Label("隐私设置", systemImage: "lock.shield")
                        }
                    }
                }
                
                Section("通知") {
                    Toggle("训练提醒", isOn: $enableNotifications)
                }
                
                Section("数据") {
                    Button(action: exportTrainingData) {
                        HStack {
                            Label("导出训练数据", systemImage: "square.and.arrow.up")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        HStack {
                            Label("删除所有数据", systemImage: "trash")
                        }
                    }
                }
                
                Section("关于") {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Label("隐私政策", systemImage: "doc.text")
                    }
                    NavigationLink(destination: DataDescriptionView()) {
                        Label("数据说明", systemImage: "info.circle")
                    }
                    
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("导出成功", isPresented: $showExportSuccess) {
                Button("好的", role: .cancel) {}
            } message: {
                Text("训练数据已复制到剪贴板，您可以粘贴到其他应用中保存。")
            }
            .alert("确认删除", isPresented: $showDeleteConfirmation) {
                Button("取消", role: .cancel) {}
                Button("删除所有数据", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("此操作将永久删除所有训练记录、打卡记录、训练计划和能力评估数据，且无法恢复。确定要继续吗？")
            }
            .alert("数据已清除", isPresented: $showDeleteSuccess) {
                Button("好的", role: .cancel) {}
            } message: {
                Text("所有训练数据已成功删除。")
            }
        }
    }
    
    // MARK: - Data Actions
    
    /// 导出训练数据到剪贴板
    private func exportTrainingData() {
        let dataController = DataController.shared
        let context = dataController.container.viewContext
        
        var exportText = "=== 控训 - 训练数据导出 ===\n"
        exportText += "导出时间：\(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))\n\n"
        
        // 导出训练记录
        let recordRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "TrainingRecord")
        do {
            let records = try context.fetch(recordRequest)
            if records.isEmpty {
                exportText += "【训练记录】暂无数据\n\n"
            } else {
                exportText += "【训练记录】共\(records.count)条\n"
                for (index, record) in records.enumerated() {
                    let date = record.value(forKey: "date") as? Date ?? Date()
                    let duration = record.value(forKey: "duration") as? Double ?? 0
                    let completionRate = record.value(forKey: "completionRate") as? Double ?? 0
                    let selfRating = record.value(forKey: "selfRating") as? Int16 ?? 0
                    exportText += "  \(index + 1). \(DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)) - 时长:\(Int(duration))分钟 完成度:\(Int(completionRate * 100))% 评分:\(selfRating)\n"
                }
                exportText += "\n"
            }
        } catch {
            exportText += "【训练记录】导出失败\n\n"
        }
        
        // 导出打卡记录
        let checkInRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "CheckInRecord")
        do {
            let checkIns = try context.fetch(checkInRequest)
            if checkIns.isEmpty {
                exportText += "【打卡记录】暂无数据\n\n"
            } else {
                exportText += "【打卡记录】共\(checkIns.count)次\n"
                for (index, checkIn) in checkIns.enumerated() {
                    let date = checkIn.value(forKey: "date") as? Date ?? Date()
                    exportText += "  \(index + 1). \(DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none))\n"
                }
                exportText += "\n"
            }
        } catch {
            exportText += "【打卡记录】导出失败\n\n"
        }
        
        // 复制到剪贴板
        UIPasteboard.general.string = exportText
        showExportSuccess = true
    }
    
    /// 删除所有用户数据
    private func deleteAllData() {
        DataController.shared.deleteAllUserData()
        
        // 清除UserDefaults中的相关数据
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasCompletedAssessment")
        defaults.removeObject(forKey: "hasInitializedTrainingData")
        defaults.removeObject(forKey: "isOnboardingCompleted")
        defaults.removeObject(forKey: "isInitialSetupCompleted")
        defaults.removeObject(forKey: "trainingGoal")
        defaults.removeObject(forKey: "experienceLevel")
        
        // 清除Keychain中的密码
        SecurityService.shared.removePassword()
        
        showDeleteSuccess = true
    }
}

#Preview {
    ProfileView()
}
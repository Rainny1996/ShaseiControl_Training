import SwiftUI

/// 设置页 — AC: 9.1–9.3 / NF.4–NF.6
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
            // MARK: 训练提醒
            Section("训练提醒") {
                Toggle("开启每日训练提醒", isOn: $viewModel.isReminderEnabled)
                    .onChange(of: viewModel.isReminderEnabled) { viewModel.toggleReminder($0) }
            }

            // MARK: 安全
            Section("隐私安全") {
                Toggle("Face ID / Touch ID 解锁", isOn: $viewModel.isBiometricEnabled)
                    .onChange(of: viewModel.isBiometricEnabled) { viewModel.toggleBiometric($0) }
            }

            // MARK: 显示
            Section("显示偏好") {
                Picker("字号", selection: $viewModel.fontSize) {
                    ForEach(FontSizePreference.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .onChange(of: viewModel.fontSize) { viewModel.updateFontSize($0) }
                .pickerStyle(.segmented)

                Toggle("默认开启呼吸引导", isOn: $viewModel.isBreathGuideDefaultEnabled)
                    .onChange(of: viewModel.isBreathGuideDefaultEnabled) { viewModel.toggleBreathGuideDefault($0) }
            }

            // MARK: 打卡
            Section("打卡设置") {
                Stepper("每月补签次数: \(viewModel.makeupLimit)", value: $viewModel.makeupLimit, in: 0...10)
                    .onChange(of: viewModel.makeupLimit) { viewModel.updateMakeupLimit($0) }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}

import SwiftUI

/// 数据说明页面 - 向用户说明应用收集和处理的数据类型
struct DataDescriptionView: View {
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 概述
                dataSection(title: "数据说明") {
                    Text("本应用严格遵循数据最小化原则，仅收集为提供核心功能所必需的数据。所有数据均存储在您的设备本地，不会上传至任何服务器。")
                }
                
                // 数据类型
                dataSection(title: "收集的数据类型") {
                    dataTypeItem(icon: "figure.strengthtraining.traditional",
                                 title: "训练记录",
                                 types: ["训练日期", "训练时长", "完成度", "自我评分", "训练模式", "训练备注"],
                                 purpose: "记录训练历程，生成复盘报告",
                                 storage: "Core Data 本地数据库（AES-256加密）")
                    
                    dataTypeItem(icon: "checkmark.circle",
                                 title: "打卡记录",
                                 types: ["打卡日期", "打卡时间", "关联训练记录"],
                                 purpose: "追踪训练习惯，计算连续打卡",
                                 storage: "Core Data 本地数据库")
                    
                    dataTypeItem(icon: "chart.bar",
                                 title: "能力评估",
                                 types: ["年龄", "训练经验", "身体状况", "训练目标", "能力评分", "维度得分"],
                                 purpose: "生成个性化训练计划和能力分析",
                                 storage: "Core Data 本地数据库（AES-256加密）")
                    
                    dataTypeItem(icon: "calendar",
                                 title: "训练计划",
                                 types: ["计划日期", "训练项目", "训练时长", "完成状态"],
                                 purpose: "管理和追踪训练计划执行",
                                 storage: "Core Data 本地数据库")
                    
                    dataTypeItem(icon: "faceid",
                                 title: "认证数据",
                                 types: ["密码哈希值", "盐值", "认证模式偏好"],
                                 purpose: "保护应用数据不被未授权访问",
                                 storage: "系统 Keychain（硬件级安全）")
                }
                
                // 不收集的数据
                dataSection(title: "我们不收集的数据") {
                    notCollectItem(icon: "location.slash", title: "位置信息")
                    notCollectItem(icon: "person.2.slash", title: "通讯录")
                    notCollectItem(icon: "photo.on.rectangle.angled", title: "照片与媒体")
                    notCollectItem(icon: "network.slash", title: "网络浏览记录")
                    notCollectItem(icon: "device.phone.portrait", title: "设备广告标识符")
                    notCollectItem(icon: "mic.slash", title: "麦克风录音（仅使用系统TTS语音合成）")
                }
                
                // 数据生命周期
                dataSection(title: "数据生命周期") {
                    lifecycleItem(title: "创建", detail: "数据在您使用应用功能时自动创建，或由您主动输入")
                    lifecycleItem(title: "存储", detail: "数据存储在设备本地，使用加密保护敏感信息")
                    lifecycleItem(title: "使用", detail: "数据仅用于提供应用核心功能，不用于任何其他目的")
                    lifecycleItem(title: "删除", detail: "您可随时在设置中删除所有数据，卸载应用将清除全部数据")
                }
                
                // 技术细节
                dataSection(title: "技术安全措施") {
                    techItem(title: "AES-256-GCM 加密",
                             detail: "敏感数据使用AES-256-GCM算法加密，密钥存储在系统Keychain中")
                    techItem(title: "SHA-256 哈希",
                             detail: "密码使用SHA-256加盐哈希处理，不存储明文密码")
                    techItem(title: "Keychain 安全存储",
                             detail: "认证凭据使用iOS系统Keychain存储，受硬件安全模块保护")
                    techItem(title: "NSFileProtection",
                             detail: "数据库文件启用NSFileProtectionComplete，设备锁定时数据不可访问")
                    techItem(title: "后台模糊保护",
                             detail: "应用切换到后台时自动模糊界面，防止多任务切换时泄露数据")
                }
            }
            .padding()
        }
        .navigationTitle("数据说明")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Views
    
    private func dataSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func dataTypeItem(icon: String, title: String, types: [String], purpose: String, storage: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("包含字段：")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ForEach(types, id: \.self) { type in
                    Text("  • \(type)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 32)
            
            HStack(spacing: 4) {
                Text("用途：")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(purpose)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 32)
            
            HStack(spacing: 4) {
                Text("存储：")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(storage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 32)
        }
    }
    
    private func notCollectItem(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        }
    }
    
    private func lifecycleItem(title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.accentColor)
                .frame(width: 36, alignment: .leading)
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func techItem(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            Text(detail)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        DataDescriptionView()
    }
}
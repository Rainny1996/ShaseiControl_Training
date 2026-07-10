import SwiftUI

/// 隐私政策页面
struct PrivacyPolicyView: View {
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 更新日期
                Text("更新日期：2026年7月10日")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                // 引言
                policySection(title: "引言") {
                    Text("控训（以下简称"本应用"）非常重视您的隐私保护。本隐私政策旨在向您说明我们如何收集、使用、存储和保护您的个人信息。")
                    Text("在使用本应用前，请您仔细阅读本隐私政策。使用本应用即表示您同意本隐私政策的内容。")
                }
                
                // 数据收集
                policySection(title: "一、我们收集的信息") {
                    Text("本应用仅收集以下必要信息：")
                    
                    policyItem(title: "1. 训练数据",
                               detail: "包括训练记录（训练日期、时长、完成度、自我评分）、打卡记录、训练计划数据。这些数据由您主动输入或在训练过程中自动生成。")
                    
                    policyItem(title: "2. 能力评估数据",
                               detail: "包括初始评估问卷答案、能力评分、能力维度得分。这些数据用于为您生成个性化训练计划。")
                    
                    policyItem(title: "3. 设备认证信息",
                               detail: "当您启用Face ID/Touch ID或密码锁功能时，本应用会使用系统提供的生物识别API或本地密码进行身份验证。生物识别数据由系统安全管理，本应用无法访问您的生物识别原始数据。")
                }
                
                // 数据使用
                policySection(title: "二、我们如何使用信息") {
                    Text("您提供的信息仅用于以下目的：")
                    
                    policyItem(title: "1. 提供核心功能",
                               detail: "训练数据用于记录您的训练历程、生成复盘报告、分析能力变化趋势。")
                    
                    policyItem(title: "2. 个性化服务",
                               detail: "评估数据用于生成个性化训练计划、提供针对性改善建议。")
                    
                    policyItem(title: "3. 隐私保护",
                               detail: "认证信息用于保护您的应用数据不被他人访问。")
                }
                
                // 数据存储
                policySection(title: "三、数据存储与安全") {
                    Text("本应用采用以下措施保护您的数据安全：")
                    
                    policyItem(title: "1. 本地存储",
                               detail: "所有数据仅存储在您的设备本地，使用Core Data框架进行持久化管理。本应用不连接任何远程服务器，不会将您的数据上传至云端。")
                    
                    policyItem(title: "2. 数据加密",
                               detail: "敏感数据使用AES-256-GCM算法加密存储，密码使用SHA-256加盐哈希处理。加密密钥通过系统Keychain安全存储。")
                    
                    policyItem(title: "3. 界面保护",
                               detail: "支持后台切换时自动模糊界面，防止他人通过多任务切换查看您的训练数据。")
                    
                    policyItem(title: "4. 访问控制",
                               detail: "支持Face ID、Touch ID和密码锁多种认证方式，确保只有您本人可以访问应用数据。")
                }
                
                // 数据共享
                policySection(title: "四、数据共享与披露") {
                    Text("本应用承诺：")
                    
                    policyItem(title: "不共享",
                               detail: "本应用不会将您的任何数据共享给第三方，包括但不限于广告商、数据分析公司或其他应用开发者。")
                    
                    policyItem(title: "不收集",
                               detail: "本应用不收集设备标识符、位置信息、通讯录或其他与训练无关的个人信息。")
                    
                    policyItem(title: "不追踪",
                               detail: "本应用不包含任何第三方分析SDK或广告追踪框架，不会跨应用追踪您的行为。")
                }
                
                // 数据删除
                policySection(title: "五、数据删除") {
                    Text("您有权随时删除您的数据：")
                    
                    policyItem(title: "应用内删除",
                               detail: "您可以在设置中选择"删除所有数据"，这将永久清除所有训练记录、评估数据和应用设置。")
                    
                    policyItem(title: "卸载删除",
                               detail: "卸载本应用将自动删除所有本地存储的数据。Keychain中的认证信息也会在卸载时清除。")
                }
                
                // 儿童隐私
                policySection(title: "六、未成年人保护") {
                    Text("本应用面向成年用户，不面向14岁以下儿童。我们不会 knowingly 收集未成年人的个人信息。如果您发现未成年人未经授权使用本应用，请及时联系我们。")
                }
                
                // 政策更新
                policySection(title: "七、隐私政策更新") {
                    Text("我们可能会不时更新本隐私政策。更新后的政策将在应用内发布，重大变更将通过应用内通知提醒您。继续使用本应用即表示您同意更新后的隐私政策。")
                }
                
                // 联系方式
                policySection(title: "八、联系我们") {
                    Text("如果您对本隐私政策有任何疑问或建议，请通过以下方式联系我们：")
                    Text("邮箱：privacy@controltraining.app")
                }
            }
            .padding()
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Views
    
    private func policySection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 6) {
                content()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func policyItem(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(detail)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
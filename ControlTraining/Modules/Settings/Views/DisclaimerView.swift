import SwiftUI

/// 免责声明页 — AC-C.1
struct DisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)

                Text("免责声明")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 16) {
                    Text("本应用提供训练参考，不替代专业医疗诊断与治疗。")
                        .font(.headline)

                    Text("""
                    ControlTraining（"男性控制训练"）是一个帮助用户进行盆底肌训练和射精控制训练的个人健康管理工具。请注意以下事项：

                    • 本应用提供的训练方法基于公开医学文献和康复指南，仅供健康教育和训练参考。

                    • 本应用不构成医疗诊断、治疗建议或医疗处方。如果您有健康问题、疾病或身体不适，请及时咨询专业医生。

                    • 在开始任何新的训练计划前，特别是如果您有以下情况，请先咨询医生：
                      - 急性炎症或感染期
                      - 手术后的恢复期
                      - 严重心血管疾病史
                      - 任何不明原因的身体不适

                    • 训练过程中如出现疼痛、不适或其他异常症状，请立即停止训练并就医。

                    • 本应用对因使用本应用中的训练内容而产生的任何直接或间接后果不承担法律责任。
                    """)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle("免责声明")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { DisclaimerView() }
}

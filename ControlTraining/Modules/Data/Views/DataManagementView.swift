import SwiftUI
import UniformTypeIdentifiers

/// 数据管理页 — 加密导出 / 从文件恢复 / 彻底删除
/// AC: 8.1–8.5
struct DataManagementView: View {
    @StateObject private var viewModel = DataViewModel()

    var body: some View {
        List {
            // MARK: 加密导出 (AC-8.1)
            Section {
                Button {
                    viewModel.exportData { url in
                        if let url = url {
                            viewModel.showActivity = true
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.accentColor)
                        Text("加密导出全部数据")
                        Spacer()
                        if viewModel.isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isExporting)

                Text("导出文件经过二次 AES-256-GCM 加密，需生物识别确认后生成")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("数据备份")
            }

            // MARK: 从文件恢复 (AC-8.2)
            Section {
                NavigationLink {
                    ImportRestoreView(viewModel: viewModel)
                } label: {
                    Label("从备份文件恢复", systemImage: "square.and.arrow.down")
                }
                .disabled(viewModel.isImporting)

                Text("导入前校验完整性，需生物识别确认")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("数据恢复")
            }

            // MARK: 彻底删除 (AC-8.3 / AC-8.4)
            Section {
                Button(role: .destructive) {
                    viewModel.requestDeleteAll()
                } label: {
                    Label("彻底删除全部数据", systemImage: "trash")
                }
                .disabled(viewModel.isDeleting)

                Text("⚠️ 此操作将永久清除所有训练记录、打卡记录、计划和个人档案，不可恢复")
                    .font(.caption)
                    .foregroundColor(.red)
            } header: {
                Text("数据清除")
            }
        }
        .navigationTitle("数据管理")
        .navigationBarTitleDisplayMode(.inline)
        // 删除确认弹窗 (AC-8.4)
        .alert("确认删除", isPresented: $viewModel.showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("永久删除", role: .destructive) {
                viewModel.deleteAllUserData()
            }
        } message: {
            Text("此操作将永久删除所有训练记录和数据，无法恢复。\n确认继续？")
        }
        // 错误提示
        .alert("操作失败", isPresented: $viewModel.showingError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
        // 分享导出文件
        .sheet(isPresented: $viewModel.showActivity) {
            if let url = viewModel.exportURL {
                ActivityViewController(activityItems: [url])
            }
        }
    }
}

// MARK: - Import Subview

private struct ImportRestoreView: View {
    @ObservedObject var viewModel: DataViewModel
    @State private var showFilePicker = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "doc.badge.arrow.up")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("选择备份文件")
                .font(.title2)
                .fontWeight(.semibold)

            Text("选择此前导出的 .ctbak 加密备份文件\n数据将经过完整性校验后恢复")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showFilePicker = true
            } label: {
                Label("选择文件", systemImage: "folder")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 40)
            }

            if viewModel.isImporting {
                ProgressView("正在恢复数据...")
            }

            Spacer()
        }
        .navigationTitle("恢复数据")
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.init(filenameExtension: "ctbak") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.importData(from: url)
                }
            case .failure(let error):
                viewModel.showError("文件选择失败: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - UIActivityViewController Bridge

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack { DataManagementView() }
}

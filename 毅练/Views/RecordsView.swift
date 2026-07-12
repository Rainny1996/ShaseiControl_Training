import SwiftUI
import UIKit

/// 训练记录页：列表 + 自绘趋势折线图（iOS 15 兼容，不用 Charts）
struct RecordsView: View {
    @StateObject private var vm = RecordsViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 最新状态雷达图
                    RadarCardView(scores: vm.latestRadarScores())
                        .padding(.horizontal, 16)

                    if !vm.chartData.isEmpty {
                        TrendChartView(data: vm.chartData)
                            .frame(height: 180)
                            .padding(.horizontal, 16)
                    }
                    LazyVStack(spacing: 12) {
                        ForEach(vm.sessions, id: \.id) { s in
                            NavigationLink(destination: RecordDetailView(session: s)) {
                                RecordRow(session: s)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    Button(action: export) {
                        Label("导出加密数据", systemImage: "square.and.arrow.up")
                            .foregroundColor(.ylGreen)
                    }
                    .padding(.top, 8)
                }
                .padding(.top, 16)
            }
            .navigationTitle("训练记录")
            .onAppear { vm.reload() }
        }
        .navigationViewStyle(.stack)
    }

    private func export() {
        guard let url = vm.exportJSON() else { return }
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
}

struct RecordRow: View {
    let session: TrainingSession
    private var dateText: String {
        guard let d = session.startTime else { return "--" }
        let f = DateFormatter(); f.dateFormat = "MM-dd HH:mm"
        return f.string(from: d)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(dateText).font(.system(size: 16, weight: .semibold)).foregroundColor(.ylText)
                Spacer()
                Text("\(session.totalDuration / 60) 分").font(.system(size: 14)).foregroundColor(.ylTextSecondary)
            }
            HStack(spacing: 16) {
                Tag(text: "循环 \(session.cycleCount)")
                Tag(text: session.usedSqueeze ? "使用挤捏" : "未挤捏")
                if session.prematureEjaculation { Tag(text: "提前射精", color: .ylRed) }
            }
        }
        .padding(16)
        .background(Color.ylBackground2)
        .cornerRadius(16)
    }
}

struct Tag: View {
    let text: String
    var color: Color = .ylTextSecondary
    var body: some View {
        Text(text).font(.system(size: 12)).foregroundColor(color)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(color.opacity(0.15)).cornerRadius(8)
    }
}

/// 最新状态雷达图卡片
struct RadarCardView: View {
    let scores: [String: Double]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最新状态解析")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.ylText)
            let items = RecordsViewModel.radarDimensions.map { ($0, scores[$0] ?? 0) }
            if items.contains(where: { $0.1 > 0 }) {
                RadarChartView(scores: items)
                    .frame(height: 240)
            } else {
                Text("暂无训练数据")
                    .font(.system(size: 14))
                    .foregroundColor(.ylTextSecondary)
                    .frame(height: 120)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(16)
        .background(Color.ylBackground2)
        .cornerRadius(16)
    }
}

/// 自绘趋势折线图（可控区间平均时长）
struct TrendChartView: View {
    let data: [(index: Int, avgControl: Double)]
    var body: some View {
        GeometryReader { geo in
            let maxV = max(data.map { $0.avgControl }.max() ?? 1, 1)
            let stepX = data.count > 1 ? geo.size.width / CGFloat(data.count - 1) : 0
            Path { path in
                for (i, p) in data.enumerated() {
                    let x = CGFloat(i) * stepX
                    let y = geo.size.height - CGFloat(p.avgControl / maxV) * geo.size.height * 0.8 - 10
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(Color.ylGreen, lineWidth: 3)
            .overlay(
                Text("可控区间平均时长趋势").font(.system(size: 12)).foregroundColor(.ylTextSecondary)
                    .padding(8), alignment: .topLeading
            )
        }
    }
}

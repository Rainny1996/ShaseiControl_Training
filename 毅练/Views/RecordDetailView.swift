import SwiftUI

/// 训练记录详情：每轮各阶段时长 + 各项分析
struct RecordDetailView: View {
    let session: TrainingSession
    @StateObject private var vm = RecordsViewModel()

    private var dateText: String {
        guard let d = session.startTime else { return "--" }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: d)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 概览卡片
                overviewCard

                // 雷达分析
                radarCard

                // 每轮阶段明细
                phaseDetailSection

                // 各项分析
                analysisSection

                if let note = session.note, !note.isEmpty {
                    noteCard(note)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
        }
        .navigationTitle("训练详情")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.ylBackground.ignoresSafeArea())
    }

    // MARK: - 概览
    private var overviewCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text(dateText).font(.system(size: 15, weight: .semibold)).foregroundColor(.ylText)
                Spacer()
                Text("总时长 \(session.totalDuration / 60) 分 \(session.totalDuration % 60) 秒")
                    .font(.system(size: 14)).foregroundColor(.ylTextSecondary)
            }
            HStack(spacing: 16) {
                Tag(text: "循环 \(session.cycleCount)")
                Tag(text: session.usedSqueeze ? "使用挤捏" : "未挤捏")
                if session.prematureEjaculation { Tag(text: "提前射精", color: .ylRed) }
            }
            if session.brakePoint > 0 {
                HStack {
                    Text("刹车点").font(.system(size: 13)).foregroundColor(.ylTextSecondary)
                    Text(String(format: "%.1f 分", session.brakePoint))
                        .font(.system(size: 13, weight: .medium)).foregroundColor(.ylText)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(Color.ylBackground2)
        .cornerRadius(16)
    }

    // MARK: - 雷达
    private var radarCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("状态分析").font(.system(size: 16, weight: .semibold)).foregroundColor(.ylText)
            let scores = vm.radarScores(for: session)
            let items = RecordsViewModel.radarDimensions.map { ($0, scores[$0] ?? 0) }
            RadarChartView(scores: items).frame(height: 240)
        }
        .padding(16)
        .background(Color.ylBackground2)
        .cornerRadius(16)
    }

    // MARK: - 阶段明细
    private var phaseDetailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("每轮阶段时长").font(.system(size: 16, weight: .semibold)).foregroundColor(.ylText)
            let details = vm.cyclePhaseDetails(for: session)
            if details.isEmpty {
                Text("该记录无阶段明细（早期版本未记录）。可查看下方概览与可控区间时长。")
                    .font(.system(size: 13)).foregroundColor(.ylTextSecondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.ylBackground)
                    .cornerRadius(12)
            } else {
                ForEach(details, id: \.cycle) { item in
                    cycleBlock(cycle: item.cycle, phases: item.phases)
                }
            }
            // 可控区间时长明细（兼容老记录）
            if !session.controlDurationsArray.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("各轮可控区间时长（秒）").font(.system(size: 13, weight: .medium)).foregroundColor(.ylTextSecondary)
                    let arr = session.controlDurationsArray
                    ForEach(Array(arr.enumerated()), id: \.offset) { i, v in
                        HStack {
                            Text("第 \(i + 1) 轮").font(.system(size: 13)).foregroundColor(.ylTextSecondary)
                            Spacer()
                            Text("\(v) 秒").font(.system(size: 13, weight: .medium)).foregroundColor(.ylText)
                        }
                    }
                }
                .padding(12)
                .background(Color.ylBackground)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.ylBackground2)
        .cornerRadius(16)
    }

    private func cycleBlock(cycle: Int, phases: [(stage: String, seconds: Double)]) -> some View {
        let maxSec = phases.map { $0.seconds }.max() ?? 1
        return VStack(alignment: .leading, spacing: 8) {
            Text("第 \(cycle) 轮").font(.system(size: 14, weight: .semibold)).foregroundColor(.ylGreen)
            ForEach(phases, id: \.stage) { p in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(phaseDisplayName(p.stage)).font(.system(size: 13)).foregroundColor(.ylText)
                        Spacer()
                        Text(formatSeconds(p.seconds)).font(.system(size: 13, weight: .medium)).foregroundColor(.ylTextSecondary)
                    }
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.ylGreen.opacity(0.3))
                            .frame(width: geo.size.width * CGFloat(p.seconds / maxSec), height: 6)
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(12)
        .background(Color.ylBackground)
        .cornerRadius(12)
    }

    // MARK: - 各项分析
    private var analysisSection: some View {
        let scores = vm.radarScores(for: session)
        let controls = session.controlDurationsArray
        let avgControl = controls.isEmpty ? 0 : Double(controls.reduce(0, +)) / Double(controls.count)
        return VStack(alignment: .leading, spacing: 12) {
            Text("各项分析").font(.system(size: 16, weight: .semibold)).foregroundColor(.ylText)
            analysisRow(title: "控制力", score: scores["控制力"] ?? 0,
                        desc: avgControl > 0 ? "平均可控区间 \(Int(avgControl)) 秒" : "无可控区间记录")
            analysisRow(title: "恢复力", score: scores["恢复力"] ?? 0,
                        desc: session.usedSqueeze ? "已使用挤捏法辅助回落" : "未使用挤捏法")
            analysisRow(title: "耐力", score: scores["耐力"] ?? 0,
                        desc: "完成 \(session.cycleCount) 个循环，总时长 \(session.totalDuration / 60) 分")
            analysisRow(title: "稳定性", score: scores["稳定性"] ?? 0,
                        desc: session.brakePoint > 0 ? "刹车点 \(String(format: "%.1f", session.brakePoint)) 分" : "无刹车点记录")
            analysisRow(title: "完成度", score: scores["完成度"] ?? 0,
                        desc: session.prematureEjaculation ? "本次提前射精" : "正常完成")
        }
        .padding(16)
        .background(Color.ylBackground2)
        .cornerRadius(16)
    }

    private func analysisRow(title: String, score: Double, desc: String) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .medium)).foregroundColor(.ylText)
                Text(desc).font(.system(size: 12)).foregroundColor(.ylTextSecondary)
            }
            Spacer()
            Text("\(Int(score))").font(.system(size: 18, weight: .bold)).foregroundColor(.ylGreen)
        }
        .padding(.vertical, 4)
    }

    private func noteCard(_ note: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("备注").font(.system(size: 14, weight: .medium)).foregroundColor(.ylText)
            Text(note).font(.system(size: 13)).foregroundColor(.ylTextSecondary)
        }
        .padding(16)
        .background(Color.ylBackground2)
        .cornerRadius(16)
    }

    private func formatSeconds(_ s: Double) -> String {
        let total = Int(s)
        if total < 60 { return "\(total) 秒" }
        return "\(total / 60) 分 \(total % 60) 秒"
    }
}

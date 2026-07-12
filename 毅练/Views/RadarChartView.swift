import SwiftUI

/// 自绘雷达图（iOS 15 兼容，不用 Charts）
/// scores: 维度名 → 0-100 评分；维度顺序决定顶点位置
struct RadarChartView: View {
    let scores: [(label: String, value: Double)]
    var maxValue: Double = 100

    private var dimensions: Int { max(scores.count, 3) }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size / 2 - 36
            let angleStep = (2 * CGFloat.pi) / CGFloat(dimensions)

            ZStack {
                gridLayer(center: center, radius: radius, angleStep: angleStep)
                axisLayer(center: center, radius: radius, angleStep: angleStep)
                dataPolygon(center: center, radius: radius, angleStep: angleStep)
                verticesAndLabels(center: center, radius: radius, angleStep: angleStep)
            }
        }
    }

    private func gridLayer(center: CGPoint, radius: CGFloat, angleStep: CGFloat) -> some View {
        ForEach(1...4, id: \.self) { level in
            let r = radius * CGFloat(level) / 4
            Path { path in
                for i in 0..<dimensions {
                    let angle = -CGFloat.pi / 2 + angleStep * CGFloat(i)
                    let p = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
                    if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                }
                path.closeSubpath()
            }
            .stroke(Color.ylTextSecondary.opacity(0.25), lineWidth: 1)
        }
    }

    private func axisLayer(center: CGPoint, radius: CGFloat, angleStep: CGFloat) -> some View {
        Path { path in
            for i in 0..<dimensions {
                let angle = -CGFloat.pi / 2 + angleStep * CGFloat(i)
                let p = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
                path.move(to: center)
                path.addLine(to: p)
            }
        }
        .stroke(Color.ylTextSecondary.opacity(0.3), lineWidth: 1)
    }

    private func dataPolygon(center: CGPoint, radius: CGFloat, angleStep: CGFloat) -> some View {
        Path { path in
            for i in 0..<scores.count {
                let angle = -CGFloat.pi / 2 + angleStep * CGFloat(i)
                let v = CGFloat(min(max(scores[i].value, 0), maxValue) / maxValue)
                let p = CGPoint(x: center.x + radius * v * cos(angle), y: center.y + radius * v * sin(angle))
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
        .fill(Color.ylGreen.opacity(0.25))
        .stroke(Color.ylGreen, lineWidth: 2)
    }

    private func verticesAndLabels(center: CGPoint, radius: CGFloat, angleStep: CGFloat) -> some View {
        ForEach(Array(scores.enumerated()), id: \.offset) { i, item in
            let angle = -CGFloat.pi / 2 + angleStep * CGFloat(i)
            let v = CGFloat(min(max(item.value, 0), maxValue) / maxValue)
            let p = CGPoint(x: center.x + radius * v * cos(angle), y: center.y + radius * v * sin(angle))
            Circle()
                .fill(Color.ylGreen)
                .frame(width: 6, height: 6)
                .position(p)

            let labelP = CGPoint(x: center.x + (radius + 22) * cos(angle), y: center.y + (radius + 22) * sin(angle))
            Text(item.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.ylText)
                .position(labelP)
            Text("\(Int(item.value))")
                .font(.system(size: 11))
                .foregroundColor(.ylTextSecondary)
                .position(CGPoint(x: labelP.x, y: labelP.y + 15))
        }
    }
}

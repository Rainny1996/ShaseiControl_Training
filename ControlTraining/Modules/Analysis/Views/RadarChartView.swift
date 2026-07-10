import SwiftUI

/// 自定义雷达图视图 - 展示5维能力数据
struct RadarChartView: View {
    
    let values: [Double]       // 0-1范围的维度值
    let labels: [String]       // 维度标签
    let weakDimensions: [String] // 薄弱维度名称
    
    private let gridLevels = 5  // 网格层数
    private let gridColor = Color.gray.opacity(0.2)
    private let fillColor = Color.accentColor.opacity(0.25)
    private let strokeColor = Color.accentColor
    private let weakColor = Color.orange
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 30
            
            ZStack {
                // 网格层
                ForEach(1...gridLevels, id: \.self) { level in
                    RadarGridShape(
                        sides: values.count,
                        radius: radius * CGFloat(level) / CGFloat(gridLevels),
                        center: center
                    )
                    .stroke(gridColor, lineWidth: 1)
                }
                
                // 轴线
                ForEach(0..<values.count, id: \.self) { index in
                    let angle = angleForIndex(index, total: values.count)
                    LineShape(
                        from: center,
                        to: CGPoint(
                            x: center.x + cos(angle) * radius,
                            y: center.y + sin(angle) * radius
                        )
                    )
                    .stroke(gridColor, lineWidth: 1)
                }
                
                // 数据区域填充
                RadarDataShape(
                    values: values,
                    radius: radius,
                    center: center,
                    total: values.count
                )
                .fill(fillColor)
                
                // 数据区域边框
                RadarDataShape(
                    values: values,
                    radius: radius,
                    center: center,
                    total: values.count
                )
                .stroke(strokeColor, lineWidth: 2)
                
                // 数据点
                ForEach(0..<values.count, id: \.self) { index in
                    let angle = angleForIndex(index, total: values.count)
                    let pointRadius = radius * CGFloat(values[index])
                    let point = CGPoint(
                        x: center.x + cos(angle) * pointRadius,
                        y: center.y + sin(angle) * pointRadius
                    )
                    
                    Circle()
                        .fill(isWeak(index) ? weakColor : strokeColor)
                        .frame(width: 8, height: 8)
                        .position(point)
                }
                
                // 标签
                ForEach(0..<labels.count, id: \.self) { index in
                    let angle = angleForIndex(index, total: labels.count)
                    let labelRadius = radius + 24
                    let labelPoint = CGPoint(
                        x: center.x + cos(angle) * labelRadius,
                        y: center.y + sin(angle) * labelRadius
                    )
                    
                    Text(labels[index])
                        .font(.caption)
                        .fontWeight(isWeak(index) ? .bold : .regular)
                        .foregroundColor(isWeak(index) ? weakColor : .primary)
                        .position(labelPoint)
                }
                
                // 网格层刻度
                ForEach(1...gridLevels, id: \.self) { level in
                    let score = level * 20
                    let labelRadius = radius * CGFloat(level) / CGFloat(gridLevels)
                    let topPoint = CGPoint(x: center.x, y: center.y - labelRadius - 4)
                    
                    if level < gridLevels {
                        Text("\(score)")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                            .position(topPoint)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper
    
    private func angleForIndex(_ index: Int, total: Int) -> Double {
        // 从顶部开始（-π/2），顺时针排列
        return -Double.pi / 2 + (Double(index) / Double(total)) * 2 * Double.pi
    }
    
    private func isWeak(_ index: Int) -> Bool {
        guard index < labels.count else { return false }
        return weakDimensions.contains(labels[index])
    }
}

// MARK: - 雷达图网格Shape

struct RadarGridShape: Shape {
    let sides: Int
    let radius: CGFloat
    let center: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for index in 0..<sides {
            let angle = -Double.pi / 2 + (Double(index) / Double(sides)) * 2 * Double.pi
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - 雷达图数据Shape

struct RadarDataShape: Shape {
    let values: [Double]
    let radius: CGFloat
    let center: CGPoint
    let total: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        for index in 0..<values.count {
            let angle = -Double.pi / 2 + (Double(index) / Double(total)) * 2 * Double.pi
            let pointRadius = radius * CGFloat(values[index])
            let point = CGPoint(
                x: center.x + cos(angle) * pointRadius,
                y: center.y + sin(angle) * pointRadius
            )
            
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - 线条Shape

struct LineShape: Shape {
    let from: CGPoint
    let to: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }
}
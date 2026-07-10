# UI Preview Changelog

## [v0.0.1] - 2026-07-11

### Added
- **全新 iOS 27 Liquid Glass（液态玻璃）设计风格预览**
  - 深色渐变背景 + 多层半透明玻璃面板
  - `backdrop-filter: blur()` 毛玻璃效果
  - 动态光照与微动效
  - 自适应颜色系统（默认/着色模式参考）
- 5 个主要页面：首页 / 训练 / 计划 / 状态 / 我的
- 全屏陪练模式（液态玻璃版呼吸动画）
- 训练方法详情覆盖层
- 日历热力图
- 五维能力雷达图与趋势线

### Design Features
- **Glass Surface**: `rgba(255,255,255,0.06–0.18)` 半透明底色 + `backdrop-filter: blur(40–60px)`
- **Depth Layers**: 3 层深度结构（背景 → 次级玻璃 → 主玻璃）
- **Vibrant Accents**: 青绿渐变主色 + 紫粉点缀 + 暖橙珊瑚强调
- **Dynamic Lighting**: `radial-gradient` 模拟光源、hover 时玻璃光晕变化
- **Typography**: `SF Pro Display` / `PingFang SC`，细体字重 + 宽松字距
- **Border Treatment**: 超细 `rgba(255,255,255,0.06–0.12)` 边框模拟玻璃边缘反光

### Technical
- 纯 HTML + CSS + vanilla JS，浏览器直接打开即可预览
- iPhone 15 Pro 尺寸模拟框（390×844pt）
- 无外部依赖

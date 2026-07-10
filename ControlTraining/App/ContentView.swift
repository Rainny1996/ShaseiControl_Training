import SwiftUI

/// 主内容视图 - TabView框架
struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            if appState.isLocked {
                LockScreenView()
            } else if !appState.isOnboardingCompleted {
                OnboardingView()
            } else if !appState.isInitialSetupCompleted {
                InitialSetupView()
            } else {
                MainTabView(selectedTab: $selectedTab)
            }
        }
        .animation(.easeInOut, value: appState.isLocked)
        .animation(.easeInOut, value: appState.isOnboardingCompleted)
        .animation(.easeInOut, value: appState.isInitialSetupCompleted)
        .overlay {
            // 后台模糊遮罩
            if scenePhase != .active && SecurityService.shared.isBlurProtectionEnabled {
                BlurredOverlayView()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: scenePhase)
            }
        }
    }
}

/// 主标签视图
struct MainTabView: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首页", systemImage: "house.fill")
                }
                .tag(Tab.home)
            
            TrainingListView()
                .tabItem {
                    Label("训练", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(Tab.training)
            
            CoachView()
                .tabItem {
                    Label("陪练", systemImage: "headphones")
                }
                .tag(Tab.coach)
            
            PlanView()
                .tabItem {
                    Label("计划", systemImage: "calendar")
                }
                .tag(Tab.plan)
            
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .tint(.accentColor)
    }
}

/// 锁屏视图 - 隐私保护
struct LockScreenView: View {
    @EnvironmentObject var appState: AppState
    @State private var showPasswordInput = false
    @State private var enteredPassword = ""
    @State private var shakeOffset: CGFloat = 0
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var authMode: SecurityService.AuthMode = SecurityService.shared.getAuthMode()
    
    var body: some View {
        ZStack {
            // 背景
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // 图标
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("请验证身份")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                // 根据认证模式显示不同内容
                switch authMode {
                case .none:
                    // 无保护 - 不应出现此情况
                    Text("无需验证")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                case .biometric:
                    biometricOnlyView
                    
                case .password:
                    passwordOnlyView
                    
                case .biometricAndPassword:
                    biometricAndPasswordView
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            authMode = SecurityService.shared.getAuthMode()
            
            // 如果是生物识别模式，自动触发
            if authMode == .biometric || authMode == .biometricAndPassword {
                tryBiometricAuth()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPasswordInput)) { _ in
            showPasswordInput = true
        }
    }
    
    // MARK: - Biometric Only View
    
    private var biometricOnlyView: some View {
        VStack(spacing: 16) {
            Text("使用Face ID或Touch ID解锁")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button(action: tryBiometricAuth) {
                HStack {
                    Image(systemName: biometricIcon)
                    Text("验证身份")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(Color.accentColor)
                .cornerRadius(25)
            }
        }
    }
    
    // MARK: - Password Only View
    
    private var passwordOnlyView: some View {
        VStack(spacing: 16) {
            Text("请输入密码解锁")
                .font(.body)
                .foregroundColor(.secondary)
            
            // 密码输入指示器
            passwordIndicator
            
            // 数字键盘
            numericKeypad
        }
    }
    
    // MARK: - Biometric and Password View
    
    private var biometricAndPasswordView: some View {
        VStack(spacing: 16) {
            if showPasswordInput {
                // 密码输入模式
                Text("请输入密码")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                passwordIndicator
                
                numericKeypad
                
                // 切换回生物识别
                Button(action: {
                    showPasswordInput = false
                    tryBiometricAuth()
                }) {
                    HStack {
                        Image(systemName: biometricIcon)
                        Text("使用\(biometricName)解锁")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                }
                .padding(.top, 8)
            } else {
                // 生物识别模式
                Text("使用Face ID或Touch ID解锁")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Button(action: tryBiometricAuth) {
                    HStack {
                        Image(systemName: biometricIcon)
                        Text("验证身份")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(Color.accentColor)
                    .cornerRadius(25)
                }
                
                // 切换到密码输入
                Button("使用密码解锁") {
                    showPasswordInput = true
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Password Indicator
    
    private var passwordIndicator: some View {
        HStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index < enteredPassword.count ? Color.accentColor : Color.clear)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor.opacity(0.3), lineWidth: 2)
                    )
            }
        }
        .offset(x: shakeOffset)
        .animation(.default, value: shakeOffset)
    }
    
    // MARK: - Numeric Keypad
    
    private var numericKeypad: some View {
        VStack(spacing: 16) {
            // 1-3
            HStack(spacing: 24) {
                keypadButton("1")
                keypadButton("2")
                keypadButton("3")
            }
            // 4-6
            HStack(spacing: 24) {
                keypadButton("4")
                keypadButton("5")
                keypadButton("6")
            }
            // 7-9
            HStack(spacing: 24) {
                keypadButton("7")
                keypadButton("8")
                keypadButton("9")
            }
            // 空-0-删除
            HStack(spacing: 24) {
                // 空位
                Color.clear
                    .frame(width: 75, height: 75)
                
                keypadButton("0")
                
                // 删除按钮
                Button(action: {
                    if !enteredPassword.isEmpty {
                        enteredPassword.removeLast()
                    }
                }) {
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 75, height: 75)
                }
            }
        }
    }
    
    // MARK: - Keypad Button
    
    private func keypadButton(_ number: String) -> some View {
        Button(action: {
            enteredPassword.append(number)
            
            // 输入4位后自动验证
            if enteredPassword.count == 4 {
                verifyPassword()
            }
        }) {
            Text(number)
                .font(.title2)
                .fontWeight(.medium)
                .frame(width: 75, height: 75)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(Circle())
        }
        .foregroundColor(.primary)
    }
    
    // MARK: - Helpers
    
    private var biometricIcon: String {
        switch SecurityService.shared.biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock"
        }
    }
    
    private var biometricName: String {
        switch SecurityService.shared.biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        default: return "生物识别"
        }
    }
    
    private func tryBiometricAuth() {
        SecurityService.shared.authenticate { success in
            if success {
                appState.isLocked = false
            }
        }
    }
    
    private func verifyPassword() {
        let success = SecurityService.shared.verifyPassword(enteredPassword)
        if success {
            appState.isLocked = false
        } else {
            // 密码错误 - 抖动动画
            withAnimation(.easeInOut(duration: 0.05)) {
                shakeOffset = -10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.05)) {
                    shakeOffset = 10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.05)) {
                        shakeOffset = 0
                    }
                }
            }
            
            // 清空密码
            enteredPassword = ""
            errorMessage = "密码错误，请重试"
            showError = true
        }
    }
}

/// 标签枚举
enum Tab: String, CaseIterable {
    case home = "首页"
    case training = "训练"
    case coach = "陪练"
    case plan = "计划"
    case profile = "我的"
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppState())
}
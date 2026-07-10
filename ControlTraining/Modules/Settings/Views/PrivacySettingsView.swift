import SwiftUI

/// 隐私设置页面
struct PrivacySettingsView: View {
    
    @State private var useFaceID: Bool = UserDefaults.standard.bool(forKey: "useFaceID")
    @State private var isPasswordEnabled: Bool = SecurityService.shared.isPasswordSet
    @State private var isBlurEnabled: Bool = UserDefaults.standard.bool(forKey: "blurProtectionEnabled")
    
    @State private var showSetPassword = false
    @State private var showChangePassword = false
    @State private var showDisablePasswordConfirm = false
    
    @State private var authMode: SecurityService.AuthMode = SecurityService.shared.getAuthMode()
    
    var body: some View {
        Form {
            // MARK: - 认证方式
            Section {
                // 生物识别
                if SecurityService.shared.isBiometricAvailable {
                    Toggle(biometricName, isOn: $useFaceID)
                        .onChange(of: useFaceID) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "useFaceID")
                            updateAuthMode()
                        }
                }
                
                // 密码锁
                HStack {
                    Text("密码锁")
                    Spacer()
                    if isPasswordEnabled {
                        Text("已开启")
                            .foregroundColor(.secondary)
                    } else {
                        Text("未设置")
                            .foregroundColor(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isPasswordEnabled {
                        showChangePassword = true
                    } else {
                        showSetPassword = true
                    }
                }
                
                // 当前认证模式
                HStack {
                    Text("当前模式")
                    Spacer()
                    Label(authMode.rawValue, systemImage: authMode.iconName)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("认证方式")
            } footer: {
                Text("选择进入应用时的身份验证方式。生物识别需要设备支持Face ID或Touch ID。")
            }
            
            // MARK: - 密码管理
            if isPasswordEnabled {
                Section(header: Text("密码管理"), content: {
                    Button(action: { showChangePassword = true }) {
                        HStack {
                            Label("修改密码", systemImage: "pencil")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    Button(role: .destructive, action: { showDisablePasswordConfirm = true }) {
                        HStack {
                            Label("关闭密码锁", systemImage: "lock.open")
                            Spacer()
                        }
                    }
                }
            }
            
            // MARK: - 隐私保护
            Section(header: Text("隐私保护"), content: {
                Toggle("后台模糊保护", isOn: $isBlurEnabled)
                    .onChange(of: isBlurEnabled) { newValue in
                        SecurityService.shared.isBlurProtectionEnabled = newValue
                    }
            } footer: {
                Text("启用后，应用切换到后台时会自动模糊界面，防止他人通过多任务切换看到敏感内容。")
            }
            
            // MARK: - 数据安全
            Section(header: Text("数据安全"), content: {
                HStack {
                    Label("数据加密", systemImage: "lock.shield")
                    Spacer()
                    Text("已启用")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                HStack {
                    Label("安全存储", systemImage: "key")
                    Spacer()
                    Text("Keychain")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            } footer: {
                Text("敏感数据使用AES-256加密存储，密码使用SHA-256加盐哈希保存在系统Keychain中。")
            }
            
            // MARK: - 关于隐私
            Section(header: Text("关于"), content: {
                NavigationLink(destination: PrivacyPolicyView()) {
                    HStack {
                        Text("隐私政策")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                NavigationLink(destination: DataDescriptionView()) {
                    HStack {
                        Text("数据说明")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            } footer: {
                Text("所有训练数据仅存储在您的设备本地，不会上传至任何服务器。")
            }
        }
        .navigationTitle("隐私设置")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSetPassword) {
            SetPasswordView(isPasswordEnabled: $isPasswordEnabled, authMode: $authMode)
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
        .alert("关闭密码锁", isPresented: $showDisablePasswordConfirm) {
            Button("取消", role: .cancel) {}
            Button("确认关闭", role: .destructive) {
                disablePassword()
            }
        } message: {
            Text("关闭密码锁后，将无法通过密码保护应用。确定要关闭吗？")
        }
        .onAppear {
            authMode = SecurityService.shared.getAuthMode()
            isPasswordEnabled = SecurityService.shared.isPasswordSet
        }
    }
    
    // MARK: - Helpers
    
    private var biometricName: String {
        switch SecurityService.shared.biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "生物识别"
        }
    }
    
    private func updateAuthMode() {
        authMode = SecurityService.shared.getAuthMode()
    }
    
    private func disablePassword() {
        SecurityService.shared.removePassword()
        isPasswordEnabled = false
        updateAuthMode()
    }
}

// MARK: - Set Password View

/// 设置密码视图
struct SetPasswordView: View {
    
    @Binding var isPasswordEnabled: Bool
    @Binding var authMode: SecurityService.AuthMode
    
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showError = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 图标
                Image(systemName: "lock")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                
                Text("设置应用密码")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("请设置4位数字密码，用于保护您的训练数据")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // 密码输入
                VStack(spacing: 16) {
                    SecureField("输入密码", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                    
                    SecureField("确认密码", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                // 密码强度指示
                if !password.isEmpty {
                    passwordStrengthView
                }
                
                Spacer()
                
                // 设置按钮
                Button(action: setPassword) {
                    Text("设置密码")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(password.isEmpty || confirmPassword.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                }
                .disabled(password.isEmpty || confirmPassword.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarItems(trailing: Button("取消") { dismiss() })
            .alert("设置失败", isPresented: $showError) {
                Button("确定") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var passwordStrengthView: some View {
        VStack(spacing: 4) {
            HStack {
                Text("密码强度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(passwordStrengthText)
                    .font(.caption)
                    .foregroundColor(passwordStrengthColor)
            }
            
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(passwordStrengthColor)
                            .frame(width: geometry.size.width * passwordStrengthProgress, height: 4)
                    )
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 40)
    }
    
    private var passwordStrengthText: String {
        if password.count < 4 { return "太短" }
        if password.count == 4 { return "一般" }
        if password.count <= 6 { return "中等" }
        return "强"
    }
    
    private var passwordStrengthColor: Color {
        if password.count < 4 { return .red }
        if password.count == 4 { return .orange }
        if password.count <= 6 { return .yellow }
        return .green
    }
    
    private var passwordStrengthProgress: CGFloat {
        if password.count < 4 { return 0.25 }
        if password.count == 4 { return 0.5 }
        if password.count <= 6 { return 0.75 }
        return 1.0
    }
    
    private func setPassword() {
        // 验证密码
        guard password.count >= 4 else {
            errorMessage = "密码至少需要4位"
            showError = true
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "两次输入的密码不一致"
            showError = true
            return
        }
        
        // 设置密码
        let success = SecurityService.shared.setPassword(password)
        if success {
            isPasswordEnabled = true
            authMode = SecurityService.shared.getAuthMode()
            dismiss()
        } else {
            errorMessage = "密码设置失败，请重试"
            showError = true
        }
    }
}

// MARK: - Change Password View

/// 修改密码视图
struct ChangePasswordView: View {
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 图标
                Image(systemName: "pencil.and.lock")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                    .padding(.top, 20)
                
                Text("修改密码")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // 密码输入
                VStack(spacing: 16) {
                    SecureField("当前密码", text: $currentPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                    
                    SecureField("新密码", text: $newPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                    
                    SecureField("确认新密码", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // 修改按钮
                Button(action: changePassword) {
                    Text("修改密码")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canChange ? Color.blue : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!canChange)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationBarItems(trailing: Button("取消") { dismiss() })
            .alert("修改失败", isPresented: $showError) {
                Button("确定") {}
            } message: {
                Text(errorMessage)
            }
            .alert("修改成功", isPresented: $showSuccess) {
                Button("确定") { dismiss() }
            } message: {
                Text("密码已成功修改")
            }
        }
    }
    
    private var canChange: Bool {
        !currentPassword.isEmpty && !newPassword.isEmpty && !confirmPassword.isEmpty
    }
    
    private func changePassword() {
        // 验证当前密码
        guard SecurityService.shared.verifyPassword(currentPassword) else {
            errorMessage = "当前密码不正确"
            showError = true
            return
        }
        
        // 验证新密码
        guard newPassword.count >= 4 else {
            errorMessage = "新密码至少需要4位"
            showError = true
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "两次输入的密码不一致"
            showError = true
            return
        }
        
        guard newPassword != currentPassword else {
            errorMessage = "新密码不能与当前密码相同"
            showError = true
            return
        }
        
        // 设置新密码
        let success = SecurityService.shared.setPassword(newPassword)
        if success {
            showSuccess = true
        } else {
            errorMessage = "密码修改失败，请重试"
            showError = true
        }
    }
}

// MARK: - Preview

struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacySettingsView()
        }
    }
}
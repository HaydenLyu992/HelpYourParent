import SwiftUI

/// The login/registration screen presented when no user role is stored.
///
/// Allows the user to:
/// 1. Select their role (elder or guardian) via two large doodle buttons.
/// 2. Enter their phone number.
/// 3. Request an SMS verification code.
/// 4. Enter the code and complete login/registration.
///
/// On success, the tokens are stored in the Keychain, the user's identity
/// (role, userId, nickname, phone) is stored in `@AppStorage`, and the
/// APNs device token (if available) is registered with the backend.
struct LoginView: View {
    @Environment(APIClient.self) private var apiClient

    @AppStorage("userRole") private var userRole: String = ""
    @AppStorage("userId") private var userId: Int = 0
    @AppStorage("userNickname") private var userNickname: String = ""
    @AppStorage("userPhone") private var userPhone: String = ""

    @State private var selectedRole: String = ""
    @State private var phone: String = ""
    @State private var code: String = ""
    @State private var isCodeSent = false
    @State private var countdownSeconds = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    private let codeTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Logo and Title
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.doodleCoralLight)
                            .frame(width: 90, height: 90)
                            .doodleBorder(.doodleInk, width: 4)
                        Text("💗")
                            .font(.system(size: 44))
                    }

                    Text(String(localized: "app_name", defaultValue: "康护亲"))
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(.doodleInk)

                    Text(String(localized: "login_subtitle", defaultValue: "守护爸妈，不远不近刚刚好"))
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.doodleInkLight)
                }
                .padding(.top, 40)

                // MARK: - Stars Decoration
                HStack(spacing: 12) {
                    Text("⭐")
                        .font(.system(size: 22))
                        .rotationEffect(.degrees(-12))
                    Text("✨")
                        .font(.system(size: 16))
                        .rotationEffect(.degrees(8))
                    Text("🌟")
                        .font(.system(size: 28))
                        .rotationEffect(.degrees(-5))
                }

                // MARK: - Illustration
                HStack(spacing: 28) {
                    VStack(spacing: 6) {
                        Text("👵")
                            .font(.system(size: 38))
                            .frame(width: 72, height: 72)
                            .background(Color.doodleCoralLight)
                            .clipShape(Circle())
                            .doodleBorder(.doodleInk, width: 3)
                        Text(String(localized: "login_elder_avatar_label", defaultValue: "妈妈"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.doodleInk)
                    }

                    Text("💕")
                        .font(.system(size: 28))
                        .foregroundStyle(.doodleCoral)

                    VStack(spacing: 6) {
                        Text("👧")
                            .font(.system(size: 38))
                            .frame(width: 72, height: 72)
                            .background(Color.doodleSkyLight)
                            .clipShape(Circle())
                            .doodleBorder(.doodleInk, width: 3)
                        Text(String(localized: "login_guardian_avatar_label", defaultValue: "女儿"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.doodleInk)
                    }
                }

                // MARK: - Role Selector
                VStack(spacing: 8) {
                    Text(String(localized: "login_choose_role", defaultValue: "请选择您的身份"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.doodleInk)

                    HStack(spacing: 12) {
                        // Elder button
                        Button {
                            selectedRole = "elder"
                        } label: {
                            VStack(spacing: 6) {
                                Text("👴")
                                    .font(.system(size: 32))
                                Text(String(localized: "login_role_elder", defaultValue: "我是老人"))
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(selectedRole == "elder" ? Color.doodleCoral : Color.white)
                            .foregroundStyle(selectedRole == "elder" ? Color.white : Color.doodleInk)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .doodleBorder(.doodleInk, width: 3)
                            .shadow(color: .black.opacity(0.08), radius: 0, x: 2, y: 3)
                        }

                        // Guardian button
                        Button {
                            selectedRole = "guardian"
                        } label: {
                            VStack(spacing: 6) {
                                Text("👧")
                                    .font(.system(size: 32))
                                Text(String(localized: "login_role_guardian", defaultValue: "我是守护者"))
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(selectedRole == "guardian" ? Color.doodleCoral : Color.white)
                            .foregroundStyle(selectedRole == "guardian" ? Color.white : Color.doodleInk)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .doodleBorder(.doodleInk, width: 3)
                            .shadow(color: .black.opacity(0.08), radius: 0, x: 2, y: 3)
                        }
                    }
                }

                // MARK: - Phone Input
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Text("📱")
                            .font(.system(size: 20))
                        TextField(String(localized: "login_phone_placeholder", defaultValue: "请输入手机号"), text: $phone)
                            .keyboardType(.numberPad)
                            .font(.system(size: 17, design: .rounded))
                            .onChange(of: phone) { _, newValue in
                                phone = String(newValue.filter(\.isNumber).prefix(11))
                            }
                    }
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .doodleBorder(.doodleInk, width: 3)
                    .shadow(color: .black.opacity(0.06), radius: 0, x: 2, y: 3)
                }

                // MARK: - Code Input and Send Button
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Text("🔐")
                            .font(.system(size: 20))
                        TextField(String(localized: "login_code_placeholder", defaultValue: "请输入验证码"), text: $code)
                            .keyboardType(.numberPad)
                            .font(.system(size: 17, design: .rounded))
                            .onChange(of: code) { _, newValue in
                                code = String(newValue.filter(\.isNumber).prefix(6))
                            }
                    }
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .doodleBorder(.doodleInk, width: 3)
                    .shadow(color: .black.opacity(0.06), radius: 0, x: 2, y: 3)

                    // Send code button
                    Button {
                        sendCode()
                    } label: {
                        HStack {
                            Text("📨")
                            Text(isCodeSent
                                 ? String(localized: "login_resend_code", defaultValue: "重新发送 (\(countdownSeconds)s)")
                                 : String(localized: "login_send_code", defaultValue: "获取验证码"))
                        }
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isCodeSent ? Color.doodleInkLight : Color.doodleSky)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .doodleBorder(.doodleInk, width: 2)
                        .shadow(color: .black.opacity(0.08), radius: 0, x: 2, y: 3)
                    }
                    .disabled(isCodeSent || phone.count != 11 || selectedRole.isEmpty)
                    .opacity((isCodeSent || phone.count != 11 || selectedRole.isEmpty) ? 0.5 : 1)
                }

                // MARK: - Login Button
                Button {
                    login()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("\(String(localized: "login_button", defaultValue: "登录 / 注册"))")
                    }
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.doodleCoral)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .doodleBorder(.doodleInk, width: 3)
                    .shadow(color: .black.opacity(0.12), radius: 0, x: 3, y: 5)
                }
                .disabled(isLoading || code.count != 6 || phone.count != 11 || selectedRole.isEmpty)
                .opacity((isLoading || code.count != 6 || phone.count != 11 || selectedRole.isEmpty) ? 0.5 : 1)

                // MARK: - Footer
                Text(String(localized: "login_agreement", defaultValue: "注册即表示同意用户协议和隐私政策"))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.doodleInkLighter)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .background(Color.doodleCream)
        .onReceive(codeTimer) { _ in
            if countdownSeconds > 0 {
                countdownSeconds -= 1
            } else {
                isCodeSent = false
            }
        }
        .alert(String(localized: "login_error_title", defaultValue: "提示"),
               isPresented: $showError) {
            Button(String(localized: "ok", defaultValue: "确定"), role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Send Verification Code

    private func sendCode() {
        guard !selectedRole.isEmpty else {
            errorMessage = String(localized: "login_error_no_role", defaultValue: "请先选择您的身份")
            showError = true
            return
        }

        guard phone.count == 11 else {
            errorMessage = String(localized: "login_error_invalid_phone", defaultValue: "请输入正确的手机号")
            showError = true
            return
        }

        Task {
            do {
                let _: APIResponse<String> = try await apiClient.post(
                    Endpoint.sendCode.path,
                    body: ["phone": phone]
                )
                isCodeSent = true
                countdownSeconds = 60
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // MARK: - Login / Register

    private func login() {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                struct LoginResponseData: Codable {
                    let accessToken: String
                    let refreshToken: String
                    let userId: Int
                    let role: String
                    let nickname: String?
                    let phone: String?
                }

                let response: LoginResponseData = try await apiClient.post(
                    Endpoint.register.path,
                    body: [
                        "phone": phone,
                        "code": code,
                        "role": selectedRole
                    ]
                )

                // Store tokens in Keychain
                apiClient.storeTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)

                // Store user identity in @AppStorage
                userRole = response.role
                userId = response.userId
                userNickname = response.nickname ?? ""
                userPhone = response.phone ?? phone

                // Register APNs device token if available
                if let deviceToken = UserDefaults.standard.string(forKey: "apnsDeviceToken") {
                    registerDeviceToken(deviceToken)
                } else {
                    // Listen for the token notification in case it arrives shortly
                    NotificationCenter.default.addObserver(
                        forName: .didRegisterForRemoteNotifications,
                        object: nil,
                        queue: .main
                    ) { notification in
                        if let token = notification.userInfo?["deviceToken"] as? String {
                            registerDeviceToken(token)
                        }
                    }
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    /// Register the APNs device token with the backend.
    private func registerDeviceToken(_ token: String) {
        Task {
            do {
                struct DeviceRequest: Codable {
                    let deviceToken: String
                }
                let _: APIResponse<String>? = try? await apiClient.post(
                    Endpoint.registerDevice.path,
                    body: DeviceRequest(deviceToken: token)
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environment(APIClient())
}

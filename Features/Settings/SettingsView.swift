import SwiftUI

/// The settings screen shared by both elder and guardian roles.
///
/// Displays:
/// - Current user profile card (avatar, nickname, phone, role).
/// - Notification preference toggle (push notifications).
/// - Role-based lists of guardians (for elders) or elders (for guardians).
/// - A "switch role" button that logs out and returns to the login screen.
/// - A "logout" button.
struct SettingsView: View {
    @Environment(APIClient.self) private var apiClient

    @AppStorage("userRole") private var userRole: String = ""
    @AppStorage("userId") private var userId: Int = 0
    @AppStorage("userNickname") private var userNickname: String = ""
    @AppStorage("userPhone") private var userPhone: String = ""

    @State private var boundUsers: [BoundUserInfo] = []
    @State private var isLoadingBoundUsers = true
    @State private var showConfirmLogout = false
    @State private var showConfirmSwitchRole = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - User Profile Card
                DoodleCardView(background: .doodleCoralLight) {
                    HStack(spacing: 16) {
                        // Avatar
                        Text(roleAvatarEmoji)
                            .font(.system(size: 44))
                            .frame(width: 64, height: 64)
                            .background(role == "elder" ? Color.doodleCoralLight : Color.doodleSkyLight)
                            .clipShape(Circle())
                            .doodleBorder(.doodleInk, width: 3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName)
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(.doodleInk)

                            Text(userPhone)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(.doodleInkLight)

                            BadgeView(
                                text: role == "elder"
                                    ? String(localized: "role_elder_badge", defaultValue: "👴 老人端")
                                    : String(localized: "role_guardian_badge", defaultValue: "👧 守护者端"),
                                background: role == "elder" ? .doodleCoral : .doodleSky,
                                textColor: .white
                            )
                        }

                        Spacer()

                        Text("✏️")
                            .font(.system(size: 20))
                            .foregroundStyle(.doodleInkLight)
                    }
                }

                // MARK: - Notification Settings
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    DoodleCardView(background: .doodleSunLight) {
                        HStack(spacing: 12) {
                            Text("🔔")
                                .font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "settings_notifications", defaultValue: "通知设置"))
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(.doodleInk)
                                Text(String(localized: "settings_notifications_hint", defaultValue: "管理推送、短信和邮件通知渠道"))
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundStyle(.doodleInkLight)
                            }
                            Spacer()
                            Text("➡️")
                                .font(.system(size: 18))
                        }
                    }
                }
                .buttonStyle(.plain)

                // MARK: - Bound Users Section
                if !boundUsers.isEmpty {
                    DoodleCardView {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(boundUsersSectionTitle)
                                    .font(.system(size: 17, weight: .black, design: .rounded))
                                    .foregroundStyle(.doodleInk)
                                Spacer()
                                Text("\(boundUsers.count)")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .foregroundStyle(.doodleCoral)
                            }

                            ForEach(boundUsers) { boundUser in
                                HStack(spacing: 12) {
                                    Text(boundUser.avatarEmoji)
                                        .font(.system(size: 28))
                                        .frame(width: 44, height: 44)
                                        .background(Color.doodleCoralLight)
                                        .clipShape(Circle())
                                        .doodleBorder(.doodleInk, width: 2)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(boundUser.displayName)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundStyle(.doodleInk)
                                        Text(boundUser.relationshipLabel)
                                            .font(.system(size: 12, design: .rounded))
                                            .foregroundStyle(.doodleInkLight)
                                    }

                                    Spacer()

                                    Text("✓ \(String(localized: "settings_bound", defaultValue: "已绑定"))")
                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                        .foregroundStyle(.doodleSky)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.doodleSkyLight)
                                        .clipShape(Capsule())
                                        .doodleBorder(.doodleInk, width: 1)
                                }
                            }
                        }
                    }
                } else if !isLoadingBoundUsers {
                    DoodleCardView(background: .doodleSkyLight) {
                        HStack(spacing: 12) {
                            Text(role == "elder" ? "👨‍👩‍👧" : "👴")
                                .font(.system(size: 28))
                            Text(emptyBoundText)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    ProgressView()
                        .tint(.doodleCoral)
                }

                // MARK: - Switch Role Button
                Button {
                    showConfirmSwitchRole = true
                } label: {
                    HStack {
                        Text("🔄")
                        Text(switchRoleText)
                    }
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .foregroundStyle(.doodleInk)
                    .clipShape(Capsule())
                    .doodleBorder(.doodleInk, width: 3)
                    .shadow(color: .black.opacity(0.08), radius: 0, x: 2, y: 3)
                }

                // MARK: - Logout Button
                Button {
                    showConfirmLogout = true
                } label: {
                    HStack {
                        Text("🚪")
                        Text(String(localized: "settings_logout", defaultValue: "退出登录"))
                    }
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.doodleCoralLight)
                    .foregroundStyle(.doodleCoralDark)
                    .clipShape(Capsule())
                    .doodleBorder(.doodleInk, width: 3)
                    .shadow(color: .black.opacity(0.08), radius: 0, x: 2, y: 3)
                }

                // App version
                Text("\(String(localized: "settings_version", defaultValue: "版本")) \(appVersion)")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.doodleInkLighter)
                    .padding(.top, 8)
            }
            .padding()
        }
        .background(Color.doodleCream)
        .navigationTitle(String(localized: "settings_tab", defaultValue: "设置"))
        .task {
            await loadBoundUsers()
        }
        .confirmationDialog(
            String(localized: "settings_switch_role_title", defaultValue: "切换角色"),
            isPresented: $showConfirmSwitchRole,
            titleVisibility: .visible
        ) {
            Button(String(localized: "settings_switch_role_confirm", defaultValue: "确认切换"),
                   role: .destructive) {
                performLogout()
            }
            Button(String(localized: "cancel", defaultValue: "取消"), role: .cancel) {}
        } message: {
            Text(String(localized: "settings_switch_role_message", defaultValue: "切换角色将退出当前账号，返回登录页面"))
        }
        .confirmationDialog(
            String(localized: "settings_logout_title", defaultValue: "退出登录"),
            isPresented: $showConfirmLogout,
            titleVisibility: .visible
        ) {
            Button(String(localized: "settings_logout_confirm", defaultValue: "确认退出"),
                   role: .destructive) {
                performLogout()
            }
            Button(String(localized: "cancel", defaultValue: "取消"), role: .cancel) {}
        } message: {
            Text(String(localized: "settings_logout_message", defaultValue: "退出后需要重新登录才能使用"))
        }
    }

    // MARK: - Computed Properties

    private var role: String { userRole }

    private var displayName: String {
        userNickname.isEmpty ? userPhone : userNickname
    }

    private var roleAvatarEmoji: String {
        role == "elder" ? "👴" : "👧"
    }

    private var switchRoleText: String {
        role == "elder"
            ? String(localized: "settings_switch_to_guardian", defaultValue: "🔄 切换到守护者端")
            : String(localized: "settings_switch_to_elder", defaultValue: "🔄 切换到老人端")
    }

    private var boundUsersSectionTitle: Text {
        role == "elder"
            ? Text(String(localized: "settings_my_guardians", defaultValue: "我的守护者"))
            : Text(String(localized: "settings_my_elders", defaultValue: "我守护的老人"))
    }

    private var emptyBoundText: String {
        role == "elder"
            ? String(localized: "settings_no_guardians", defaultValue: "暂无守护者，邀请家人守护您的健康吧")
            : String(localized: "settings_no_elders", defaultValue: "暂未守护任何老人")
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    // MARK: - Actions

    /// Load the list of bound users (guardians for elder, elders for guardian).
    private func loadBoundUsers() async {
        isLoadingBoundUsers = true
        defer { isLoadingBoundUsers = false }

        do {
            // Use the existing guardianList endpoint; backend returns appropriate data based on role
            let users: [BoundUserInfo] = try await apiClient.get(Endpoint.guardianList.path)
            boundUsers = users
        } catch {
            // Silently fail — the view will show empty state
        }
    }

    /// Clear all stored session data and return to the login screen.
    private func performLogout() {
        // Clear Keychain tokens
        apiClient.clearTokens()

        // Clear @AppStorage identity
        userRole = ""
        userId = 0
        userNickname = ""
        userPhone = ""
    }
}

// MARK: - Supporting Types

/// A simplified representation of a bound user (guardian or elder).
struct BoundUserInfo: Codable, Identifiable {
    let userId: Int
    let nickname: String?
    let phone: String?
    let relationship: String?
    let avatarUrl: String?

    var id: Int { userId }

    var displayName: String {
        nickname ?? phone ?? String(localized: "unknown_user", defaultValue: "未知用户")
    }

    var relationshipLabel: String {
        relationship ?? String(localized: "unknown_relationship", defaultValue: "未知关系")
    }

    var avatarEmoji: String {
        "👨‍👩‍👧"
    }
}

// MARK: - Reusable Sub-Views

private struct DoodleCardView<Content: View>: View {
    let background: Color
    let content: Content

    init(background: Color = .white, @ViewBuilder content: () -> Content) {
        self.background = background
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .doodleBorder(.doodleInk, width: 3)
            .shadow(color: .black.opacity(0.1), radius: 0, x: 3, y: 5)
    }
}

/// A small capsule badge with doodle styling.
private struct BadgeView: View {
    let text: String
    let background: Color
    let textColor: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(background)
            .clipShape(Capsule())
            .doodleBorder(.doodleInk, width: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SettingsView()
            .environment(APIClient())
    }
}

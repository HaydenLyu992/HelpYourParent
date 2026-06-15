import SwiftUI

/// Notification preference management screen.
///
/// Lets the user toggle three independent notification channels:
/// - Push notifications (APNs, always available as fallback)
/// - SMS notifications (via Alibaba Cloud SMS)
/// - Email notifications (via Alibaba Cloud Email Push)
///
/// All preferences are persisted to the backend and synced on view load.
struct NotificationSettingsView: View {
    @Environment(APIClient.self) private var apiClient

    @State private var pushEnabled = true
    @State private var smsEnabled = false
    @State private var emailEnabled = false
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showSaved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                DoodleCardView(background: .doodleSunLight) {
                    HStack(spacing: 16) {
                        Text("🔔")
                            .font(.system(size: 42))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "notification_settings_title", defaultValue: "通知偏好"))
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(.doodleInk)
                            Text(String(localized: "notification_settings_subtitle", defaultValue: "选择您希望接收告警的方式"))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.doodleInkLight)
                        }
                    }
                }

                // Push toggle
                DoodleCardView {
                    ChannelToggleRow(
                        emoji: "📱",
                        title: String(localized: "channel_push_title", defaultValue: "App 推送通知"),
                        description: String(localized: "channel_push_desc", defaultValue: "通过 Apple 推送服务接收即时告警"),
                        isOn: $pushEnabled
                    )
                    .onChange(of: pushEnabled) { _, _ in savePreferences() }
                }

                // SMS toggle
                DoodleCardView {
                    ChannelToggleRow(
                        emoji: "💬",
                        title: String(localized: "channel_sms_title", defaultValue: "短信通知"),
                        description: String(localized: "channel_sms_desc", defaultValue: "紧急情况下通过手机短信接收告警（运营商可能收费）"),
                        isOn: $smsEnabled
                    )
                    .onChange(of: smsEnabled) { _, _ in savePreferences() }
                }

                // Email toggle
                DoodleCardView {
                    ChannelToggleRow(
                        emoji: "📧",
                        title: String(localized: "channel_email_title", defaultValue: "邮件通知"),
                        description: String(localized: "channel_email_desc", defaultValue: "接收详细的健康告警邮件报告"),
                        isOn: $emailEnabled
                    )
                    .onChange(of: emailEnabled) { _, _ in savePreferences() }
                }

                // Explanatory footer
                DoodleCardView(background: .doodleSkyLight) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(localized: "notification_footer_title", defaultValue: "关于通知"))
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.doodleInk)
                        Text(String(localized: "notification_footer_body", defaultValue: "即使关闭所有通知渠道，告警仍会在 App 内的通知中心展示。推送通知始终兜底发送以保证您不会错过紧急情况。"))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.doodleInkLight)
                    }
                }
            }
            .padding()
        }
        .background(Color.doodleCream)
        .navigationTitle(String(localized: "settings_notifications", defaultValue: "通知设置"))
        .task { await loadPreferences() }
    }

    private func loadPreferences() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let prefs: NotificationPrefsResponse = try await apiClient.get(
                Endpoint.notificationPreferences.path
            )
            pushEnabled = prefs.pushEnabled
            smsEnabled = prefs.smsEnabled
            emailEnabled = prefs.emailEnabled
        } catch {
            // Use defaults
        }
    }

    private func savePreferences() {
        guard !isLoading else { return }

        Task {
            isSaving = true
            defer { isSaving = false }

            do {
                let _: APIResponse<String>? = try? await apiClient.put(
                    Endpoint.updateNotificationPreferences.path,
                    body: NotificationPrefsBody(
                        pushEnabled: pushEnabled,
                        smsEnabled: smsEnabled,
                        emailEnabled: emailEnabled
                    )
                )
                showSaved = true
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                showSaved = false
            }
        }
    }
}

// MARK: - Supporting Types

struct NotificationPrefsResponse: Codable {
    let pushEnabled: Bool
    let smsEnabled: Bool
    let emailEnabled: Bool
}

struct NotificationPrefsBody: Codable {
    let pushEnabled: Bool
    let smsEnabled: Bool
    let emailEnabled: Bool
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

private struct ChannelToggleRow: View {
    let emoji: String
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 32))
                .frame(width: 48, height: 48)
                .background(Color.doodleCoralLight)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.doodleInk)
                Text(description)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.doodleInkLight)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(.doodleCoral)
                .labelsHidden()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationSettingsView()
            .environment(APIClient())
    }
}

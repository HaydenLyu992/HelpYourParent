import SwiftUI

/// The routing gate for the app.
///
/// Reads the user role from `@AppStorage("userRole")` and renders the
/// appropriate view hierarchy:
/// - Empty role  → `LoginView`
/// - `"elder"`   → `ElderTabView`
/// - `"guardian"` → `GuardianTabView`
///
/// Also listens for the `ShowBindingRequest` notification to present a
/// `BindingRequestView` sheet when the user taps a binding push notification.
struct RootView: View {
    @AppStorage("userRole") private var userRole: String = ""

    @State private var showBindingRequest = false
    @State private var bindingRequestId: String = ""
    @State private var bindingFromUserId: Int = 0

    var body: some View {
        Group {
            if userRole.isEmpty {
                LoginView()
                    .transition(.opacity)
            } else if userRole == "elder" {
                ElderTabView()
                    .transition(.opacity)
            } else if userRole == "guardian" {
                GuardianTabView()
                    .transition(.opacity)
            }
        }
        .animation(.default, value: userRole)
        .onReceive(NotificationCenter.default.publisher(for: .showBindingRequest)) { notification in
            if let requestId = notification.userInfo?["requestId"] as? String,
               let fromUserId = notification.userInfo?["fromUserId"] as? Int {
                bindingRequestId = requestId
                bindingFromUserId = fromUserId
                showBindingRequest = true
            }
        }
        .sheet(isPresented: $showBindingRequest) {
            BindingRequestView(
                requestId: bindingRequestId,
                fromUserId: bindingFromUserId
            )
        }
    }
}

// MARK: - Elder Tab View

private struct ElderTabView: View {
    @State private var selectedTab: ElderTab = .home

    enum ElderTab: String, CaseIterable {
        case home
        case health
        case ai
        case guardians
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ElderHomeView()
            }
            .tabItem {
                Label(String(localized: "elder_tab_home", defaultValue: "首页"), systemImage: "house.fill")
            }
            .tag(ElderTab.home)

            NavigationStack {
                HealthDetailView()
            }
            .tabItem {
                Label(String(localized: "health_tab", defaultValue: "健康"), systemImage: "heart.fill")
            }
            .tag(ElderTab.health)

            NavigationStack {
                AIAssistantView()
            }
            .tabItem {
                Label(String(localized: "ai_tab", defaultValue: "AI助手"), systemImage: "brain.head.profile")
            }
            .tag(ElderTab.ai)

            NavigationStack {
                GuardianManagementView()
            }
            .tabItem {
                Label(String(localized: "guardian_tab", defaultValue: "守护者"), systemImage: "person.2.fill")
            }
            .tag(ElderTab.guardians)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(String(localized: "settings_tab", defaultValue: "设置"), systemImage: "gearshape.fill")
            }
            .tag(ElderTab.settings)
        }
        .tint(.doodleCoral)
    }
}

// MARK: - Guardian Tab View

private struct GuardianTabView: View {
    @State private var selectedTab: GuardianTab = .home

    enum GuardianTab: String, CaseIterable {
        case home
        case alerts
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                GuardianHomeView()
                    .navigationTitle(String(localized: "guardian_home_title", defaultValue: "守护中心"))
            }
            .tabItem {
                Label(String(localized: "guardian_tab_home", defaultValue: "首页"), systemImage: "house.fill")
            }
            .tag(GuardianTab.home)

            NavigationStack {
                AlertHistoryView()
            }
            .tabItem {
                Label(String(localized: "guardian_tab_alerts", defaultValue: "告警"), systemImage: "bell.fill")
            }
            .tag(GuardianTab.alerts)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(String(localized: "settings_tab", defaultValue: "设置"), systemImage: "gearshape.fill")
            }
            .tag(GuardianTab.settings)
        }
        .tint(.doodleCoral)
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .environment(HealthKitManager())
        .environment(APIClient())
}

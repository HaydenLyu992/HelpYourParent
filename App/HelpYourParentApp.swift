import SwiftUI
import SwiftData

@main
struct HelpYourParentApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var healthKitManager = HealthKitManager()
    @State private var apiClient = APIClient()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(healthKitManager)
                .environment(apiClient)
                .modelContainer(for: [LocalUser.self, LocalAlert.self])
        }
    }
}

// MARK: Preview

#Preview {
    RootView()
        .environment(HealthKitManager())
        .environment(APIClient())
        .modelContainer(for: [LocalUser.self, LocalAlert.self], inMemory: true)
}

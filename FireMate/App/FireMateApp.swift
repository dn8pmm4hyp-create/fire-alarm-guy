import SwiftUI

@main
struct FireMateApp: App {
    @StateObject private var formsStore = FormsStore()
    @StateObject private var settings = SettingsStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(formsStore)
                .environmentObject(settings)
                .tint(Theme.accent)
        }
    }
}

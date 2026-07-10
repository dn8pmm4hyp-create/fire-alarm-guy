import SwiftUI

/// Top-level tab navigation for the five main areas of the app.
struct RootView: View {
    var body: some View {
        TabView {
            AssistantView()
                .tabItem { Label("Assistant", systemImage: "waveform.circle.fill") }

            ToolsView()
                .tabItem { Label("Tools", systemImage: "function") }

            FormsView()
                .tabItem { Label("Forms", systemImage: "doc.text.fill") }

            ReferenceView()
                .tabItem { Label("Reference", systemImage: "books.vertical.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(FormsStore())
        .environmentObject(SettingsStore())
}

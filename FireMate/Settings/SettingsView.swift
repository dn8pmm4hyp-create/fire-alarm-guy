import SwiftUI

/// User preferences: engineer profile (pre-fills forms), voice behaviour and
/// the Anthropic API key that powers the cloud assistant.
@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("engineerName") var engineerName = ""
    @AppStorage("companyName") var companyName = ""
    @AppStorage("speakReplies") var speakReplies = true
}

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var apiKey = KeychainStore.load(key: KeychainStore.apiKeyAccount) ?? ""
    @State private var apiKeySaved = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Engineer profile") {
                    TextField("Your name", text: settings.$engineerName)
                    TextField("Company", text: settings.$companyName)
                } footer: {
                    Text("Used to pre-fill new service forms and PDF sign-off.")
                }

                Section("Assistant") {
                    Toggle("Speak replies aloud", isOn: settings.$speakReplies)
                }

                Section("Cloud assistant (Claude API)") {
                    SecureField("Anthropic API key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button(apiKeySaved ? "Saved ✓" : "Save key") {
                        KeychainStore.save(key: KeychainStore.apiKeyAccount, value: apiKey)
                        apiKeySaved = true
                    }
                    .disabled(apiKeySaved)
                    .onChange(of: apiKey) { _, _ in apiKeySaved = false }
                } footer: {
                    Text("Stored in the device Keychain. Without a key, the assistant still answers common questions offline. Model: \(CloudAssistant.model).")
                }

                Section("About") {
                    LabeledContent("App", value: "FireMate")
                    LabeledContent("Version", value: appVersion)
                    Text("Calculators and reference notes are engineering aids based on BS 5839-1 rules of thumb. Always verify designs against the current published standard and manufacturer data.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsStore())
}

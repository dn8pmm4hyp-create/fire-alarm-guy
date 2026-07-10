import SwiftUI

/// Chat interface combining ButlerBrain (offline) and CloudAssistant (Claude API),
/// with hands-free voice input/output via VoiceEngine.
struct AssistantView: View {
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var voice = VoiceEngine()

    @State private var messages: [ChatMessage] = []
    @State private var input = ""
    @State private var isThinking = false

    private let brain = ButlerBrain()
    private let cloud = CloudAssistant()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messageList
                composer
            }
            .navigationTitle("FireMate")
            .background(Theme.screenBackground)
            .onAppear {
                voice.requestAuthorisation()
                voice.onFinalTranscript = { text in
                    input = text
                    submit()
                }
            }
        }
    }

    // MARK: Subviews

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Theme.spacing) {
                    if messages.isEmpty {
                        emptyState
                    }
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    if isThinking {
                        HStack {
                            ProgressView()
                            Text("Thinking…").foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }
                }
                .padding()
            }
            .onChange(of: messages) { _, newValue in
                if let last = newValue.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(Theme.accent)
            Text("Ask me anything about fire alarms")
                .font(.headline)
            Text("Battery sizing, sound levels, detector spacing, BS 5839-1 categories… Tap the mic to talk hands-free.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
    }

    private var composer: some View {
        HStack(spacing: Theme.spacing) {
            Button {
                toggleListening()
            } label: {
                Image(systemName: voice.isListening ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(voice.isListening ? Theme.amber : Theme.accent)
            }
            .accessibilityLabel(voice.isListening ? "Stop listening" : "Start voice input")

            TextField(voice.isListening ? "Listening…" : "Ask FireMate…",
                      text: voice.isListening ? $voice.transcript : $input,
                      axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .onSubmit(submit)
                .disabled(voice.isListening)

            Button(action: submit) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
            }
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || isThinking)
        }
        .padding()
        .background(.bar)
    }

    // MARK: Actions

    private func toggleListening() {
        if voice.isListening {
            voice.stopListening()
        } else {
            try? voice.startListening()
        }
    }

    private func submit() {
        let question = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isThinking else { return }
        input = ""
        messages.append(ChatMessage(role: .user, text: question))

        switch brain.respond(to: question) {
        case .answer(let text):
            deliver(ChatMessage(role: .assistant, text: text, isLocal: true))
        case .escalate:
            askCloud()
        }
    }

    private func askCloud() {
        isThinking = true
        let history = messages
        Task {
            defer { isThinking = false }
            do {
                let reply = try await cloud.send(history: history)
                deliver(ChatMessage(role: .assistant, text: reply))
            } catch {
                deliver(ChatMessage(role: .assistant, text: error.localizedDescription, isLocal: true))
            }
        }
    }

    private func deliver(_ message: ChatMessage) {
        messages.append(message)
        if settings.speakReplies {
            voice.speak(message.text)
        }
    }
}

// MARK: - Bubble

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 4) {
                Text(message.text)
                if message.role == .assistant && message.isLocal {
                    Label("Answered offline", systemImage: "bolt.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(10)
            .background(message.role == .user ? Theme.accent.opacity(0.15) : Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }
}

#Preview {
    AssistantView()
        .environmentObject(SettingsStore())
}

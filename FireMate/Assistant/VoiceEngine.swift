import Foundation
import AVFoundation
import Speech

/// Wraps speech-to-text (SFSpeechRecognizer) and text-to-speech (AVSpeechSynthesizer)
/// so the assistant can be driven hands-free on site.
@MainActor
final class VoiceEngine: NSObject, ObservableObject {
    @Published var isListening = false
    @Published var transcript = ""
    @Published var authorised = false

    private let recogniser = SFSpeechRecognizer(locale: Locale(identifier: "en-GB"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let synthesiser = AVSpeechSynthesizer()

    /// Called when the user stops speaking and the transcript is final.
    var onFinalTranscript: ((String) -> Void)?

    func requestAuthorisation() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                self?.authorised = (status == .authorized)
            }
        }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    // MARK: Listening

    func startListening() throws {
        guard !isListening else { return }
        stopSpeaking()
        transcript = ""

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true

        task = recogniser?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.finish(with: self.transcript)
                    }
                }
                if error != nil {
                    self.finish(with: self.transcript)
                }
            }
        }
    }

    func stopListening() {
        finish(with: transcript)
    }

    private func finish(with text: String) {
        guard isListening else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isListening = false
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            onFinalTranscript?(trimmed)
        }
    }

    // MARK: Speaking

    func speak(_ text: String) {
        stopSpeaking()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesiser.speak(utterance)
    }

    func stopSpeaking() {
        if synthesiser.isSpeaking {
            synthesiser.stopSpeaking(at: .immediate)
        }
    }
}

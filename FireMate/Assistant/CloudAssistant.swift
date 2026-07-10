import Foundation

/// Client for the Anthropic Messages API (`POST /v1/messages`) over URLSession.
/// Used when ButlerBrain can't answer locally. Requires an API key, entered in
/// Settings and stored in the Keychain.
final class CloudAssistant {

    enum CloudError: LocalizedError {
        case missingAPIKey
        case http(Int, String)
        case emptyResponse
        case refused

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "No API key set. Add one in Settings to enable the cloud assistant."
            case .http(let code, let message):
                return "Cloud assistant error (\(code)): \(message)"
            case .emptyResponse:
                return "The cloud assistant returned an empty response."
            case .refused:
                return "The cloud assistant declined to answer that question."
            }
        }
    }

    static let model = "claude-opus-4-8"

    private static let systemPrompt = """
    You are FireMate, an assistant for a UK fire alarm engineer working to BS 5839-1. \
    Answer questions about fire detection and alarm system design, installation, \
    commissioning, servicing and fault-finding. Be concise and practical — the user \
    is usually on site. State the relevant clause or rule of thumb where useful, and \
    recommend confirming safety-critical decisions against the current standard.
    """

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Sends the conversation and returns Claude's reply text.
    /// `history` is the full conversation so far, oldest first.
    func send(history: [ChatMessage]) async throws -> String {
        guard let apiKey = KeychainStore.load(key: KeychainStore.apiKeyAccount),
              !apiKey.isEmpty else {
            throw CloudError.missingAPIKey
        }

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body = MessagesRequest(
            model: Self.model,
            maxTokens: 16000,
            system: Self.systemPrompt,
            messages: history.map { .init(role: $0.role.rawValue, content: $0.text) }
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CloudError.emptyResponse
        }
        guard http.statusCode == 200 else {
            let message = (try? JSONDecoder().decode(APIErrorEnvelope.self, from: data))?
                .error.message ?? String(data: data, encoding: .utf8) ?? "unknown error"
            throw CloudError.http(http.statusCode, message)
        }

        let decoded = try JSONDecoder().decode(MessagesResponse.self, from: data)
        if decoded.stopReason == "refusal" {
            throw CloudError.refused
        }
        let text = decoded.content
            .filter { $0.type == "text" }
            .compactMap(\.text)
            .joined(separator: "\n")
        guard !text.isEmpty else { throw CloudError.emptyResponse }
        return text
    }
}

// MARK: - Chat model shared with the UI

struct ChatMessage: Identifiable, Equatable {
    enum Role: String {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
    /// True when the reply came from ButlerBrain rather than the API.
    var isLocal = false
}

// MARK: - Wire types

private struct MessagesRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }

    let model: String
    let maxTokens: Int
    let system: String
    let messages: [Message]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }
}

private struct MessagesResponse: Decodable {
    struct ContentBlock: Decodable {
        let type: String
        let text: String?
    }

    let content: [ContentBlock]
    let stopReason: String?

    enum CodingKeys: String, CodingKey {
        case content
        case stopReason = "stop_reason"
    }
}

private struct APIErrorEnvelope: Decodable {
    struct APIError: Decodable {
        let message: String
    }
    let error: APIError
}

// MARK: - Keychain

/// Minimal Keychain wrapper for storing the API key securely.
enum KeychainStore {
    static let apiKeyAccount = "com.firemate.anthropic-api-key"

    static func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        guard !value.isEmpty else { return }
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

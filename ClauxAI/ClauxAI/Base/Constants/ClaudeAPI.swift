 import Foundation

// MARK: - Claude API Client
// Covers all Anthropic API endpoints:
//   POST /v1/messages              — single completion
//   POST /v1/messages (streaming)  — streaming completion
//   POST /v1/messages/batches      — async batch jobs
//   GET  /v1/messages/batches      — list batches
//   GET  /v1/messages/batches/{id} — get batch status
//   GET  /v1/messages/batches/{id}/results — stream batch results
//   DEL  /v1/messages/batches/{id} — cancel batch
//   GET  /v1/models                — list models
//   GET  /v1/models/{id}           — get model details

public final class ClaudeAPIClient {

    // MARK: - Configuration

    public static let shared = ClaudeAPIClient()

    private let baseURL = "https://api.anthropic.com"
    private let apiVersion = "2023-06-01"

    /// Loaded from Firebase via DatabaseManager, or overridden by env / APIConfiguration.
    public var apiKey: String = ""

    /// Loaded from Firebase (`geminiKey`) via DatabaseManager for dual-mode GPT requests.
    public var gptApiKey: String = ""

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        // Non-streaming smart-tool responses can take minutes (long docs, up to 8192 tokens).
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 600
        return URLSession(configuration: config)
    }()

    private init() {}

    // MARK: - Base request builder

    private func request(
        method: String,
        path: String,
        body: Encodable? = nil,
        extraHeaders: [String: String] = [:]
    ) throws -> URLRequest {
        guard !apiKey.isEmpty else {
            throw ClaudeError.missingAPIKey
        }
        guard let url = URL(string: baseURL + path) else {
            throw ClaudeError.invalidURL
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (k, v) in extraHeaders { req.setValue(v, forHTTPHeaderField: k) }
        if let body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            req.httpBody = try encoder.encode(body)
        }
        return req
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // Surface API errors as ClaudeError
        if let apiError = try? decoder.decode(APIErrorResponse.self, from: data),
           apiError.type == "error" {
            throw ClaudeError.apiError(apiError.error)
        }
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - 1. Messages — POST /v1/messages

extension ClaudeAPIClient {

    /// Send a message and receive a full (non-streaming) response.
    public func sendMessage(_ request: MessageRequest) async throws -> MessageResponse {
        var req = request
        req.stream = false
        let urlRequest = try self.request(method: "POST", path: "/v1/messages", body: req)
        let (data, _) = try await session.data(for: urlRequest)
        return try decode(data)
    }
}

// MARK: - 2. Streaming Messages — POST /v1/messages (stream: true)

extension ClaudeAPIClient {

    /// Stream a message response, yielding raw server-sent event lines.
    /// Parse `data:` lines as `StreamEvent` for structured access.
    public func streamMessage(
        _ request: MessageRequest,
        onEvent: @escaping (StreamEvent) -> Void
    ) async throws {
        var req = request
        req.stream = true
        let urlRequest = try self.request(method: "POST", path: "/v1/messages", body: req)

        let (bytes, response) = try await session.bytes(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ClaudeError.unexpectedStatusCode
        }

        var buffer = Data()
        for try await byte in bytes {
            buffer.append(byte)

            while let newlineIndex = buffer.firstIndex(of: 0x0A) {
                let lineData = buffer[..<newlineIndex]
                buffer.removeSubrange(buffer.startIndex...newlineIndex)

                guard let line = String(data: lineData, encoding: .utf8)?
                    .trimmingCharacters(in: .init(charactersIn: "\r")),
                      line.hasPrefix("data: ") else { continue }

                let jsonStr = String(line.dropFirst(6))
                if jsonStr == "[DONE]" { return }
                if let data = jsonStr.data(using: .utf8),
                   let event = try? JSONDecoder().decode(StreamEvent.self, from: data) {
                    onEvent(event)
                }
            }
        }
    }
}

// MARK: - 3. Message Batches — POST /v1/messages/batches

extension ClaudeAPIClient {

    /// Submit a batch of message requests (processed async, 50% cheaper).
    public func createBatch(_ request: BatchCreateRequest) async throws -> Batch {
        let urlRequest = try self.request(
            method: "POST", path: "/v1/messages/batches", body: request)
        let (data, _) = try await session.data(for: urlRequest)
        return try decode(data)
    }

    /// List all batches (paginated).
    public func listBatches(
        beforeId: String? = nil,
        afterId: String? = nil,
        limit: Int = 20
    ) async throws -> BatchListResponse {
        var components = URLComponents(string: baseURL + "/v1/messages/batches")!
        var queryItems: [URLQueryItem] = [.init(name: "limit", value: "\(limit)")]
        if let b = beforeId { queryItems.append(.init(name: "before_id", value: b)) }
        if let a = afterId  { queryItems.append(.init(name: "after_id",  value: a)) }
        components.queryItems = queryItems

        var req = URLRequest(url: components.url!)
        req.httpMethod = "GET"
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")

        let (data, _) = try await session.data(for: req)
        return try decode(data)
    }

    /// Get the status of a specific batch.
    public func getBatch(id: String) async throws -> Batch {
        let urlRequest = try self.request(
            method: "GET", path: "/v1/messages/batches/\(id)")
        let (data, _) = try await session.data(for: urlRequest)
        return try decode(data)
    }

    /// Stream the JSONL results of a completed batch.
    /// Each line is a `BatchResult`. Only available when batch `processingStatus == .ended`.
    public func getBatchResults(
        id: String,
        onResult: @escaping (BatchResult) -> Void
    ) async throws {
        let urlRequest = try self.request(
            method: "GET", path: "/v1/messages/batches/\(id)/results")
        let (bytes, _) = try await session.bytes(for: urlRequest)

        var buffer = Data()
        for try await byte in bytes {
            buffer.append(byte)

            while let newlineIndex = buffer.firstIndex(of: 0x0A) {
                let lineData = buffer[..<newlineIndex]
                buffer.removeSubrange(buffer.startIndex...newlineIndex)

                guard let line = String(data: lineData, encoding: .utf8)?
                    .trimmingCharacters(in: .init(charactersIn: "\r")),
                      !line.isEmpty else { continue }

                if let data = line.data(using: .utf8),
                   let result = try? JSONDecoder().decode(BatchResult.self, from: data) {
                    onResult(result)
                }
            }
        }
    }

    /// Cancel a batch that is still in progress.
    public func cancelBatch(id: String) async throws -> Batch {
        let urlRequest = try self.request(
            method: "DELETE", path: "/v1/messages/batches/\(id)")
        let (data, _) = try await session.data(for: urlRequest)
        return try decode(data)
    }
}

// MARK: - 4. Models — GET /v1/models

extension ClaudeAPIClient {

    /// List all available models.
    public func listModels() async throws -> ModelListResponse {
        let urlRequest = try self.request(method: "GET", path: "/v1/models")
        let (data, _) = try await session.data(for: urlRequest)
        return try decode(data)
    }

    /// Get details for a specific model by ID.
    public func getModel(id: String) async throws -> Model {
        let urlRequest = try self.request(method: "GET", path: "/v1/models/\(id)")
        let (data, _) = try await session.data(for: urlRequest)
        return try decode(data)
    }
}

// MARK: - Request Models

public struct MessageRequest: Encodable {
    public let model: String
    public let maxTokens: Int
    public let messages: [Message]
    public let system: String?
    public let temperature: Double?
    public let topP: Double?
    public let topK: Int?
    public let stopSequences: [String]?
    public let tools: [MessageTool]?
    public var stream: Bool?

    public init(
        model: String = ClaudeModel.sonnet46,
        maxTokens: Int = 1024,
        messages: [Message],
        system: String? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        topK: Int? = nil,
        stopSequences: [String]? = nil,
        tools: [MessageTool]? = nil
    ) {
        self.model = model
        self.maxTokens = maxTokens
        self.messages = messages
        self.system = system
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.stopSequences = stopSequences
        self.tools = tools
        self.stream = nil
    }
}

public struct Message: Codable {
    public let role: Role
    private let contentValue: MessageContent

    public enum Role: String, Codable {
        case user, assistant
    }

    public init(role: Role, content: String) {
        self.role = role
        self.contentValue = .text(content)
    }

    public init(role: Role, blocks: [ContentBlockInput]) {
        self.role = role
        self.contentValue = .blocks(blocks)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decode(Role.self, forKey: .role)
        if let text = try? container.decode(String.self, forKey: .content) {
            contentValue = .text(text)
        } else {
            contentValue = .blocks(try container.decode([ContentBlockInput].self, forKey: .content))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        switch contentValue {
        case .text(let text):
            try container.encode(text, forKey: .content)
        case .blocks(let blocks):
            try container.encode(blocks, forKey: .content)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case role, content
    }
}

public enum MessageContent {
    case text(String)
    case blocks([ContentBlockInput])
}

public struct ContentBlockInput: Codable {
    public let type: String
    public let text: String?
    public let source: ImageSource?

    public static func text(_ text: String) -> ContentBlockInput {
        ContentBlockInput(type: "text", text: text, source: nil)
    }

    public static func image(base64Data: String, mediaType: String) -> ContentBlockInput {
        ContentBlockInput(
            type: "image",
            text: nil,
            source: ImageSource(mediaType: mediaType, data: base64Data)
        )
    }
}

public struct ImageSource: Codable {
    public let type: String
    public let mediaType: String
    public let data: String

    public init(mediaType: String, data: String, type: String = "base64") {
        self.type = type
        self.mediaType = mediaType
        self.data = data
    }
}

public enum MessageTool: Encodable {
    case custom(Tool)
    case webSearch(WebSearchTool)

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .custom(let tool):
            try tool.encode(to: encoder)
        case .webSearch(let tool):
            try tool.encode(to: encoder)
        }
    }
}

public struct Tool: Encodable {
    public let name: String
    public let description: String
    public let inputSchema: [String: AnyCodable]

    public init(name: String, description: String, inputSchema: [String: AnyCodable]) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
}

public struct WebSearchTool: Encodable {
    public let type: String
    public let name: String
    public let maxUses: Int?

    public init(
        type: String = "web_search_20250305",
        name: String = "web_search",
        maxUses: Int? = 5
    ) {
        self.type = type
        self.name = name
        self.maxUses = maxUses
    }
}

public struct BatchCreateRequest: Encodable {
    public let requests: [BatchRequestItem]

    public init(requests: [BatchRequestItem]) {
        self.requests = requests
    }
}

public struct BatchRequestItem: Encodable {
    public let customId: String
    public let params: MessageRequest

    public init(customId: String, params: MessageRequest) {
        self.customId = customId
        self.params = params
    }
}

// MARK: - Response Models

public struct MessageResponse: Decodable {
    public let id: String
    public let type: String
    public let role: String
    public let content: [ContentBlock]
    public let model: String
    public let stopReason: String?
    public let stopSequence: String?
    public let usage: Usage

    public var text: String {
        content.compactMap { $0.type == "text" ? $0.text : nil }.joined()
    }
}

public struct ContentBlock: Decodable {
    public let type: String
    public let text: String?
    public let id: String?
    public let name: String?
}

public struct Usage: Decodable {
    public let inputTokens: Int
    public let outputTokens: Int
}

public struct StreamEvent: Decodable {
    public let type: String
    public let index: Int?
    public let delta: StreamDelta?
    public let message: MessageResponse?
}

public struct StreamDelta: Decodable {
    public let type: String?
    public let text: String?
    public let stopReason: String?
}

public struct Batch: Decodable {
    public let id: String
    public let type: String
    public let processingStatus: ProcessingStatus
    public let requestCounts: RequestCounts
    public let endedAt: Date?
    public let createdAt: Date
    public let expiresAt: Date
    public let resultsUrl: String?

    public enum ProcessingStatus: String, Decodable {
        case inProgress = "in_progress"
        case canceling
        case ended
    }
}

public struct RequestCounts: Decodable {
    public let processing: Int
    public let succeeded: Int
    public let errored: Int
    public let canceled: Int
    public let expired: Int
}

public struct BatchListResponse: Decodable {
    public let data: [Batch]
    public let hasMore: Bool
    public let firstId: String?
    public let lastId: String?
}

public struct BatchResult: Decodable {
    public let customId: String
    public let result: BatchResultDetail
}

public struct BatchResultDetail: Decodable {
    public let type: String   // "succeeded" | "errored" | "canceled" | "expired"
    public let message: MessageResponse?
    public let error: APIError?
}

public struct Model: Decodable {
    public let id: String
    public let displayName: String
    public let createdAt: Date?
}

public struct ModelListResponse: Decodable {
    public let data: [Model]
    public let hasMore: Bool
    public let firstId: String?
    public let lastId: String?
}

// MARK: - Error Models

public struct APIErrorResponse: Decodable {
    public let type: String
    public let error: APIError
}

public struct APIError: Decodable {
    public let type: String
    public let message: String
}

public enum ClaudeError: Error, LocalizedError {
    case invalidURL
    case missingAPIKey
    case unexpectedStatusCode
    case apiError(APIError)
    case decodingError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:              return "Invalid API URL."
        case .missingAPIKey:           return "Anthropic API key is not loaded yet. Check your connection and try again."
        case .unexpectedStatusCode:    return "Unexpected HTTP status code."
        case .apiError(let e):         return "API error (\(e.type)): \(e.message)"
        case .decodingError(let e):    return "Decoding error: \(e.localizedDescription)"
        }
    }
}

// MARK: - Model ID Constants

public enum ClaudeModel {
    // Active — Opus class
    public static let opus48    = "claude-opus-4-8"
    public static let opus47    = "claude-opus-4-7"
    public static let opus46    = "claude-opus-4-6"

    // Active — Sonnet class
    public static let sonnet46  = "claude-sonnet-4-6"   // default
    public static let sonnet45  = "claude-sonnet-4-5"

    // Active — Haiku class
    public static let haiku45   = "claude-haiku-4-5-20251001"

    // Deprecated (still callable, migrate away)
    public static let opus41    = "claude-opus-4-1"     // retires 2026-08-05
    public static let opus40    = "claude-opus-4-0"
    public static let sonnet40  = "claude-sonnet-4-0"
}

// MARK: - AnyCodable helper (for Tool inputSchema)

public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) { self.value = value }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self)             { value = v }
        else if let v = try? container.decode(Int.self)         { value = v }
        else if let v = try? container.decode(Double.self)      { value = v }
        else if let v = try? container.decode(String.self)      { value = v }
        else if let v = try? container.decode([String: AnyCodable].self) { value = v }
        else if let v = try? container.decode([AnyCodable].self){ value = v }
        else { value = NSNull() }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Bool:                  try container.encode(v)
        case let v as Int:                   try container.encode(v)
        case let v as Double:               try container.encode(v)
        case let v as String:               try container.encode(v)
        case let v as [String: AnyCodable]: try container.encode(v)
        case let v as [AnyCodable]:         try container.encode(v)
        default:                            try container.encodeNil()
        }
    }
}

// MARK: - Usage Examples

/*

 // 1. Simple message
 Task {
     ClaudeAPIClient.shared.apiKey = "sk-ant-..."
     let response = try await ClaudeAPIClient.shared.sendMessage(
         MessageRequest(messages: [
             Message(role: .user, content: "Hello, Claude!")
         ])
     )
     print(response.text)
 }

 // 2. Streaming
 Task {
     try await ClaudeAPIClient.shared.streamMessage(
         MessageRequest(messages: [Message(role: .user, content: "Tell me a story")])
     ) { event in
         if event.type == "content_block_delta", let text = event.delta?.text {
             print(text, terminator: "")
         }
     }
 }

 // 3. Batch
 Task {
     let batch = try await ClaudeAPIClient.shared.createBatch(
         BatchCreateRequest(requests: [
             BatchRequestItem(
                 customId: "req-1",
                 params: MessageRequest(messages: [Message(role: .user, content: "Hi")])
             )
         ])
     )
     print("Batch created:", batch.id)
 }

 // 4. List models
 Task {
     let models = try await ClaudeAPIClient.shared.listModels()
     models.data.forEach { print($0.id, $0.displayName) }
 }

 */

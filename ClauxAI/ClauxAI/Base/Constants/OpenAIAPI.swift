//
//  OpenAIAPI.swift
//  CL.AI
//
//  OpenAI Chat Completions API (streaming) for dual-mode GPT responses.
//

import Foundation

enum OpenAIModel {
    /// Displayed in UI as GPT-5.0
    static let gpt5 = "gpt-4o"
}

struct OpenAIChatMessage: Codable {
    let role: String
    let content: OpenAIChatContent

    static func user(_ text: String) -> OpenAIChatMessage {
        OpenAIChatMessage(role: "user", content: .text(text))
    }

    static func assistant(_ text: String) -> OpenAIChatMessage {
        OpenAIChatMessage(role: "assistant", content: .text(text))
    }

    static func user(text: String, attachments: [ChatAttachment]) -> OpenAIChatMessage {
        var parts: [OpenAIContentPart] = []
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            parts.append(.text(trimmed))
        } else if !attachments.isEmpty {
            parts.append(.text("Please analyze the attached image(s)."))
        }

        for attachment in attachments {
            let base64 = attachment.data.base64EncodedString()
            parts.append(.image(base64: base64, mediaType: attachment.mediaType))
        }

        return OpenAIChatMessage(role: "user", content: .parts(parts))
    }
}

enum OpenAIChatContent: Codable {
    case text(String)
    case parts([OpenAIContentPart])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let value):
            try container.encode(value)
        case .parts(let parts):
            try container.encode(parts)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else {
            self = .parts(try container.decode([OpenAIContentPart].self))
        }
    }
}

enum OpenAIContentPart: Codable {
    case text(String)
    case image(base64: String, mediaType: String)

    enum CodingKeys: String, CodingKey {
        case type, text, imageURL = "image_url"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let value):
            try container.encode("text", forKey: .type)
            try container.encode(value, forKey: .text)
        case .image(let base64, let mediaType):
            try container.encode("image_url", forKey: .type)
            try container.encode(
                OpenAIImageURL(url: "data:\(mediaType);base64,\(base64)"),
                forKey: .imageURL
            )
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            self = .text(try container.decode(String.self, forKey: .text))
        case "image_url":
            let imageURL = try container.decode(OpenAIImageURL.self, forKey: .imageURL)
            self = .image(base64: "", mediaType: "image/png")
            _ = imageURL
        default:
            self = .text("")
        }
    }
}

private struct OpenAIImageURL: Codable {
    let url: String
}

private struct OpenAIChatRequest: Encodable {
    let model: String
    let messages: [OpenAIChatMessage]
    let temperature: Double?
    let maxTokens: Int?
    let stream: Bool

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature, stream
        case maxTokens = "max_tokens"
    }
}

private struct OpenAIStreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }
        let delta: Delta?
    }
    let choices: [Choice]?
}

private struct OpenAIErrorResponse: Decodable {
    struct Detail: Decodable {
        let message: String
    }
    let error: Detail
}

enum OpenAIError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case unexpectedStatusCode
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing."
        case .invalidURL:
            return "Invalid OpenAI API URL."
        case .unexpectedStatusCode:
            return "Unexpected response from OpenAI."
        case .apiError(let message):
            return message
        }
    }
}

final class OpenAIAPIClient {

    static let shared = OpenAIAPIClient()

    var apiKey: String = ""

    private let baseURL = "https://api.openai.com/v1"

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()

    private init() {}

    func streamChat(
        messages: [OpenAIChatMessage],
        model: String = OpenAIModel.gpt5,
        temperature: Double? = nil,
        maxTokens: Int? = nil,
        onToken: @escaping (String) -> Void
    ) async throws {
        guard !apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        guard let url = URL(string: baseURL + "/chat/completions") else {
            throw OpenAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = OpenAIChatRequest(
            model: model,
            messages: messages,
            temperature: temperature,
            maxTokens: maxTokens,
            stream: true
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(body)

        let (bytes, response) = try await session.bytes(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            var data = Data()
            for try await byte in bytes {
                data.append(byte)
            }
            if let apiError = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw OpenAIError.apiError(apiError.error.message)
            }
            throw OpenAIError.unexpectedStatusCode
        }

        var buffer = Data()
        for try await byte in bytes {
            buffer.append(byte)

            while let newlineIndex = buffer.firstIndex(of: 0x0A) {
                let lineData = buffer[..<newlineIndex]
                buffer.removeSubrange(buffer.startIndex...newlineIndex)

                guard let line = String(data: lineData, encoding: .utf8)?
                    .trimmingCharacters(in: .init(charactersIn: "\r")),
                      !line.isEmpty else {
                    continue
                }

                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6))
                if payload == "[DONE]" { return }

                guard let data = payload.data(using: .utf8),
                      let chunk = try? JSONDecoder().decode(OpenAIStreamChunk.self, from: data),
                      let token = chunk.choices?.first?.delta?.content else {
                    continue
                }

                onToken(token)
            }
        }
    }
}

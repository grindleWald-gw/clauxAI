//
//  ClauxAPIService.swift
//  ClauxAI
//
//  High-level API layer mapping app features to Claude /v1/messages.
//

import AppKit
import Foundation

// MARK: - Chat options (PromptView toggles + model picker)

struct ChatOptions: Equatable {
    var model: PromptModel
    var dualModeEnabled: Bool
    var webSearchEnabled: Bool
    var temperature: Double
    var maxTokens: Int

    static let `default` = ChatOptions(
        model: .sonnet,
        dualModeEnabled: false,
        webSearchEnabled: false,
        temperature: APIConfiguration.defaultTemperature,
        maxTokens: APIConfiguration.chatMaxTokens
    )
}

struct ChatTurn {
    let role: Message.Role
    let content: String
}

struct ChatAttachment: Equatable {
    let data: Data
    let mediaType: String

    init(data: Data, mediaType: String) {
        self.data = data
        self.mediaType = mediaType
    }

    init(image: NSImage, mediaType: String = "image/png") {
        self.data = image.tiffRepresentation.flatMap {
            NSBitmapImageRep(data: $0)?.representation(using: .png, properties: [:])
        } ?? Data()
        self.mediaType = mediaType
    }
}

// MARK: - Smart tool input payloads

struct LegalLetterInput {
    var legalIssue: String
    var userName: String
    var subject: String
    var letterType: String
}

struct PrivacyPolicyInput {
    var policyDescription: String
    var platformName: String
    var businessType: String
    var websiteURL: String
}

struct NDAInput {
    var businessDetails: String
    var companyName: String
    var confidentialInfo: String
    var duration: String
    var restrictions: String
}

struct ContractReviewInput {
    var contractDetails: String
    var contractType: String
    var reviewPreference: String
}

struct NotetakerInput {
    var topicDetails: String
    var studyLevel: String
}

struct ArticleWriterInput {
    var topicDetails: String
    var articleType: String
    var studyLevel: String
}

struct TextSummarizerInput {
    var inputText: String
    var summaryType: String
    var studyLevel: String
}

struct GrammarCheckerInput {
    var inputText: String
    var checkType: String
    var studyLevel: String
}

struct StartupAdvisorInput {
    var businessIdea: String
    var stage: String
    var focus: String
}

struct ProposalWriterInput {
    var businessIdea: String
    var clientInfo: String
    var timeline: String
    var budget: String
    var focusArea: String
}

struct EmailWriterInput {
    var emailDetails: String
    var userName: String
    var subject: String
    var tone: String
}

struct TaxHelperInput {
    var financialDetails: String
    var income: String
    var expenses: String
    var countryRegion: String
    var taxType: String
}

struct BugFixerInput {
    var prompt: String
    var attachments: [ChatAttachment]
    var options: ChatOptions
}

struct LearnTutorInput {
    var courseTitle: String
    var courseCategory: String
    var tabTitle: String
    var tabContentSummary: String
    var userQuestion: String?
}

struct PromptSubmission: Equatable {
    let message: String
    let options: ChatOptions
    let attachments: [ChatAttachment]

    init(
        message: String,
        options: ChatOptions,
        attachments: [ChatAttachment] = []
    ) {
        self.message = message
        self.options = options
        self.attachments = attachments
    }
}

// MARK: - Service

@MainActor
final class ClauxAPIService {

    static let shared = ClauxAPIService()

    private static let smartToolModel = PromptModel.sonnet

    private let client = ClaudeAPIClient.shared

    private init() {}

    // MARK: - Home chat / ResponseVC

    /// Non-streaming chat completion for home and response screens.
    func sendChat(
        message: String,
        history: [ChatTurn] = [],
        attachments: [ChatAttachment] = [],
        options: ChatOptions = .default
    ) async throws -> String {
        let request = buildMessageRequest(
            feature: .chat,
            userPrompt: message,
            history: history,
            attachments: attachments,
            options: options
        )
        let response = try await client.sendMessage(request)
        return response.text
    }

    /// Streaming chat — call `onToken` for each text delta.
    func streamChat(
        message: String,
        history: [ChatTurn] = [],
        attachments: [ChatAttachment] = [],
        options: ChatOptions = .default,
        onToken: @escaping (String) -> Void
    ) async throws {
        let request = buildMessageRequest(
            feature: .chat,
            userPrompt: message,
            history: history,
            attachments: attachments,
            options: options
        )

        try await client.streamMessage(request) { event in
            if event.type == "content_block_delta", let text = event.delta?.text {
                onToken(text)
            }
        }
    }

    /// Dual mode — stream Claude and GPT responses in parallel.
    func streamDualChat(
        message: String,
        claudeHistory: [ChatTurn] = [],
        gptHistory: [ChatTurn] = [],
        attachments: [ChatAttachment] = [],
        options: ChatOptions = .default,
        onClaudeToken: @escaping (String) -> Void,
        onGPTToken: @escaping (String) -> Void
    ) async throws {
        let claudeRequest = buildMessageRequest(
            feature: .chat,
            userPrompt: message,
            history: claudeHistory,
            attachments: attachments,
            options: options
        )

        let gptMessages = buildOpenAIMessages(
            userPrompt: message,
            history: gptHistory,
            attachments: attachments
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.client.streamMessage(claudeRequest) { event in
                    if event.type == "content_block_delta", let text = event.delta?.text {
                        onClaudeToken(text)
                    }
                }
            }

            group.addTask {
                try await OpenAIAPIClient.shared.streamChat(
                    messages: gptMessages,
                    temperature: options.temperature,
                    maxTokens: options.maxTokens,
                    onToken: onGPTToken
                )
            }

            try await group.waitForAll()
        }
    }

    // MARK: - Bug Fixer

    func fixBug(_ input: BugFixerInput) async throws -> String {
        var options = input.options
        options.maxTokens = APIConfiguration.bugFixerMaxTokens

        let request = buildMessageRequest(
            feature: .bugFixer,
            userPrompt: input.prompt,
            attachments: input.attachments,
            options: options
        )
        let response = try await client.sendMessage(request)
        return response.text
    }

    // MARK: - Smart Tools — typed entry points

    func generateLegalLetter(_ input: LegalLetterInput, model: PromptModel = .sonnet) async throws -> String {
        try await generateSmartTool(
            feature: .legalLetterWriter,
            model: model,
            userPrompt: formattedPrompt([
                ("Legal issue", input.legalIssue),
                ("Your name", input.userName),
                ("Subject", input.subject),
                ("Letter type", input.letterType)
            ], instruction: "Draft the complete legal letter.")
        )
    }

    func generatePrivacyPolicy(_ input: PrivacyPolicyInput, model: PromptModel = .sonnet) async throws -> String {
        try await generateSmartTool(
            feature: .privacyPolicyMaker,
            model: model,
            userPrompt: formattedPrompt([
                ("Description", input.policyDescription),
                ("Platform", input.platformName),
                ("Business type", input.businessType),
                ("Website URL", input.websiteURL)
            ], instruction: "Generate a complete privacy policy.")
        )
    }

    func generateNDA(_ input: NDAInput, model: PromptModel = .sonnet) async throws -> String {
        try await generateSmartTool(
            feature: .ndaGenerator,
            model: model,
            userPrompt: formattedPrompt([
                ("Business details", input.businessDetails),
                ("Company name", input.companyName),
                ("Confidential information", input.confidentialInfo),
                ("Duration", input.duration),
                ("Restrictions & terms", input.restrictions)
            ], instruction: "Generate a complete NDA document.")
        )
    }

    func generateContractReview(_ input: ContractReviewInput, model: PromptModel = .sonnet) async throws -> String {
        try await generateSmartTool(
            feature: .contractReviewer,
            model: model,
            userPrompt: formattedPrompt([
                ("Contract details", input.contractDetails),
                ("Contract type", input.contractType),
                ("Review preference", input.reviewPreference)
            ], instruction: "Review the contract and provide a structured analysis.")
        )
    }

    func generateNotes(_ input: NotetakerInput, model: PromptModel = .sonnet) async throws -> String {
        try await generateSmartTool(
            feature: .notetaker,
            model: model,
            userPrompt: formattedPrompt([
                ("Topic", input.topicDetails),
                ("Study level", input.studyLevel)
            ], instruction: "Create structured notes.")
        )
    }

    func generateArticle(_ input: ArticleWriterInput, model: PromptModel = .sonnet) async throws -> String {
        try await generateSmartTool(
            feature: .articleWriter,
            model: model,
            userPrompt: formattedPrompt([
                ("Topic", input.topicDetails),
                ("Article type", input.articleType),
                ("Study level", input.studyLevel)
            ], instruction: "Write the full article.")
        )
    }

    func summarizeText(_ input: TextSummarizerInput, model: PromptModel = .sonnet) async throws -> String {
        try await generateSmartTool(
            feature: .textSummarizer,
            model: model,
            userPrompt: formattedPrompt([
                ("Text to summarize", input.inputText),
                ("Summary type", input.summaryType),
                ("Study level", input.studyLevel)
            ], instruction: "Produce the summary.")
        )
    }

    func checkGrammar(_ input: GrammarCheckerInput, model: PromptModel = .sonnet) async throws -> String {
        try await generateSmartTool(
            feature: .grammarChecker,
            model: model,
            userPrompt: formattedPrompt([
                ("Text", input.inputText),
                ("Check type", input.checkType),
                ("Study level", input.studyLevel)
            ], instruction: "Return the corrected text followed by a brief list of changes.")
        )
    }

    func adviseStartup(_ input: StartupAdvisorInput, model: PromptModel = .sonnet) async throws -> String {
        try await generateSmartTool(
            feature: .startupAdvisor,
            model: model,
            userPrompt: formattedPrompt([
                ("Business idea", input.businessIdea),
                ("Stage", input.stage),
                ("Focus", input.focus)
            ], instruction: "Provide startup advice with actionable next steps.")
        )
    }

    func generateProposal(_ input: ProposalWriterInput, model: PromptModel = .sonnet) async throws -> String {
        try await generateSmartTool(
            feature: .proposalWriter,
            model: model,
            userPrompt: formattedPrompt([
                ("Business idea / scope", input.businessIdea),
                ("Client / company", input.clientInfo),
                ("Timeline", input.timeline),
                ("Budget", input.budget),
                ("Focus area", input.focusArea)
            ], instruction: "Write a complete business proposal.")
        )
    }

    func generateEmail(_ input: EmailWriterInput, model: PromptModel = .sonnet) async throws -> String {
        try await generateSmartTool(
            feature: .emailWriter,
            model: model,
            userPrompt: formattedPrompt([
                ("Email details", input.emailDetails),
                ("Your name", input.userName),
                ("Subject", input.subject),
                ("Tone", input.tone)
            ], instruction: "Write the complete email ready to send.")
        )
    }

    func helpWithTax(_ input: TaxHelperInput, model: PromptModel = .sonnet) async throws -> String {
        try await generateSmartTool(
            feature: .taxHelper,
            model: model,
            userPrompt: formattedPrompt([
                ("Financial details", input.financialDetails),
                ("Income", input.income),
                ("Expenses", input.expenses),
                ("Country / region", input.countryRegion),
                ("Tax type", input.taxType)
            ], instruction: "Explain tax implications and provide educational guidance.")
        )
    }

    // MARK: - Smart Tools — destination dispatch

    func generate(
        for destination: SmartToolDestination,
        input: SmartToolAPIInput,
        model: PromptModel = .sonnet
    ) async throws -> String {
        switch input {
        case .legalLetter(let payload):
            return try await generateLegalLetter(payload, model: model)
        case .privacyPolicy(let payload):
            return try await generatePrivacyPolicy(payload, model: model)
        case .nda(let payload):
            return try await generateNDA(payload, model: model)
        case .contractReview(let payload):
            return try await generateContractReview(payload, model: model)
        case .notetaker(let payload):
            return try await generateNotes(payload, model: model)
        case .articleWriter(let payload):
            return try await generateArticle(payload, model: model)
        case .textSummarizer(let payload):
            return try await summarizeText(payload, model: model)
        case .grammarChecker(let payload):
            return try await checkGrammar(payload, model: model)
        case .startupAdvisor(let payload):
            return try await adviseStartup(payload, model: model)
        case .proposalWriter(let payload):
            return try await generateProposal(payload, model: model)
        case .emailWriter(let payload):
            return try await generateEmail(payload, model: model)
        case .taxHelper(let payload):
            return try await helpWithTax(payload, model: model)
        }
    }

    // MARK: - Learn with Claux

    func tutorResponse(_ input: LearnTutorInput, model: PromptModel = .sonnet) async throws -> String {
        let prompt = formattedPrompt([
            ("Course", input.courseTitle),
            ("Category", input.courseCategory),
            ("Current tab", input.tabTitle),
            ("Tab content summary", input.tabContentSummary),
            ("Student question", input.userQuestion ?? "Explain this topic further with examples.")
        ], instruction: "Teach the student based on the course context.")

        return try await generateSmartTool(
            feature: .learnWithClaux,
            model: model,
            userPrompt: prompt
        )
    }

    // MARK: - Models endpoint

    func listAvailableModels() async throws -> [Model] {
        let response = try await client.listModels()
        return response.data
    }

    // MARK: - Batch (bulk smart-tool runs)

    func submitBatch(
        items: [(customId: String, feature: ClauxFeature, userPrompt: String)],
        model: PromptModel = .sonnet
    ) async throws -> Batch {
        let requests = items.map { item in
            BatchRequestItem(
                customId: item.customId,
                params: MessageRequest(
                    model: Self.smartToolModel.claudeModelID,
                    maxTokens: APIConfiguration.toolMaxTokens,
                    messages: [Message(role: .user, content: item.userPrompt)],
                    system: ClauxToolPrompts.systemPrompt(for: item.feature),
                    temperature: APIConfiguration.defaultTemperature
                )
            )
        }
        return try await client.createBatch(BatchCreateRequest(requests: requests))
    }

    // MARK: - Private helpers

    private func generateSmartTool(
        feature: ClauxFeature,
        model: PromptModel,
        userPrompt: String
    ) async throws -> String {
        await DatabaseManager.shared.ensureAPIKeysLoaded()

        let request = MessageRequest(
            model: Self.smartToolModel.claudeModelID,
            maxTokens: APIConfiguration.toolMaxTokens,
            messages: [Message(role: .user, content: userPrompt)],
            system: ClauxToolPrompts.systemPrompt(for: feature),
            temperature: APIConfiguration.defaultTemperature
        )
        let response = try await client.sendMessage(request)
        return response.text
    }

    private func buildMessageRequest(
        feature: ClauxFeature,
        userPrompt: String,
        history: [ChatTurn] = [],
        attachments: [ChatAttachment] = [],
        options: ChatOptions
    ) -> MessageRequest {
        var systemParts = [ClauxToolPrompts.systemPrompt(for: feature)]
        if options.webSearchEnabled {
            systemParts.append(ClauxToolPrompts.webSearchInstruction)
        }

        var messages: [Message] = history.map { Message(role: $0.role, content: $0.content) }

        if attachments.isEmpty {
            messages.append(Message(role: .user, content: userPrompt))
        } else {
            let prompt = userPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            let text = prompt.isEmpty
                ? "Please analyze the attached image(s)."
                : prompt
            var blocks: [ContentBlockInput] = [.text(text)]
            for attachment in attachments {
                let base64 = attachment.data.base64EncodedString()
                blocks.append(.image(base64Data: base64, mediaType: attachment.mediaType))
            }
            messages.append(Message(role: .user, blocks: blocks))
        }

        var tools: [MessageTool]?
        if options.webSearchEnabled {
            tools = [.webSearch(WebSearchTool())]
        }

        return MessageRequest(
            model: options.model.claudeModelID,
            maxTokens: options.maxTokens,
            messages: messages,
            system: systemParts.joined(separator: "\n\n"),
            temperature: options.temperature,
            tools: tools
        )
    }

    private func buildOpenAIMessages(
        userPrompt: String,
        history: [ChatTurn],
        attachments: [ChatAttachment]
    ) -> [OpenAIChatMessage] {
        var messages: [OpenAIChatMessage] = [
            OpenAIChatMessage(
                role: "system",
                content: .text(ClauxToolPrompts.systemPrompt(for: .chat))
            )
        ]

        for turn in history {
            switch turn.role {
            case .user:
                messages.append(.user(turn.content))
            case .assistant:
                messages.append(.assistant(turn.content))
            }
        }

        if attachments.isEmpty {
            messages.append(.user(userPrompt))
        } else {
            messages.append(.user(text: userPrompt, attachments: attachments))
        }

        return messages
    }

    private func formattedPrompt(
        _ fields: [(String, String)],
        instruction: String
    ) -> String {
        let body = fields
            .map { "**\($0.0):** \($0.1.trimmingCharacters(in: .whitespacesAndNewlines))" }
            .joined(separator: "\n")
        return "\(body)\n\n\(instruction)"
    }
}

// MARK: - Unified smart-tool input enum

enum SmartToolAPIInput {
    case legalLetter(LegalLetterInput)
    case privacyPolicy(PrivacyPolicyInput)
    case nda(NDAInput)
    case contractReview(ContractReviewInput)
    case notetaker(NotetakerInput)
    case articleWriter(ArticleWriterInput)
    case textSummarizer(TextSummarizerInput)
    case grammarChecker(GrammarCheckerInput)
    case startupAdvisor(StartupAdvisorInput)
    case proposalWriter(ProposalWriterInput)
    case emailWriter(EmailWriterInput)
    case taxHelper(TaxHelperInput)
}

extension SmartToolDestination {
    var defaultModel: PromptModel {
        .sonnet
    }
}

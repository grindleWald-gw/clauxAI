//
//  APIConstants.swift
//  ClauxAI
//
//  Created by Yasir Shah on 30/05/2026.
//

import Foundation

// MARK: - App API configuration

enum APIConfiguration {
    /// Paste your Anthropic key here for local dev, or set `ANTHROPIC_API_KEY` in the Xcode scheme.
    private static let localDevAPIKey = ""

    /// Load from Keychain or a backend proxy in production.
    static var apiKey: String {
        get { ClaudeAPIClient.shared.apiKey }
        set { ClaudeAPIClient.shared.apiKey = newValue }
    }

    static func bootstrap() {
        if apiKey.isEmpty, !localDevAPIKey.isEmpty {
            apiKey = localDevAPIKey
        }
    }

    static let defaultTemperature: Double = 0.7
    static let chatMaxTokens = 4096
    static let toolMaxTokens = 8192
    static let bugFixerMaxTokens = 8192
    static let learnMaxTokens = 4096
}

// MARK: - PromptModel → Claude API model IDs

extension PromptModel {
    var claudeModelID: String {
        switch self {
        case .opus:   return ClaudeModel.opus46
        case .sonnet: return ClaudeModel.sonnet46
        case .haiku:  return ClaudeModel.haiku45
        }
    }
}

// MARK: - Feature identifiers

enum ClauxFeature: String {
    case chat
    case bugFixer
    case legalLetterWriter
    case privacyPolicyMaker
    case ndaGenerator
    case contractReviewer
    case notetaker
    case articleWriter
    case textSummarizer
    case grammarChecker
    case startupAdvisor
    case proposalWriter
    case emailWriter
    case taxHelper
    case learnWithClaux
}

extension SmartToolDestination {
    var feature: ClauxFeature {
        switch self {
        case .legalLetterWriter:    return .legalLetterWriter
        case .privacyPolicyMaker:     return .privacyPolicyMaker
        case .ndaGenerator:           return .ndaGenerator
        case .contractReviewer:       return .contractReviewer
        case .notetaker:              return .notetaker
        case .articleWriter:          return .articleWriter
        case .textSummarizer:         return .textSummarizer
        case .grammarChecker:         return .grammarChecker
        case .startupAdvisor:         return .startupAdvisor
        case .proposalWriter:         return .proposalWriter
        case .emailWriter:            return .emailWriter
        case .taxHelper:              return .taxHelper
        }
    }
}

// MARK: - System prompts per tool

enum ClauxToolPrompts {

    static let chatBase = """
    You are Claux AI, a helpful assistant inside the Claux macOS app. \
    Be clear, accurate, and concise. Format responses with markdown when useful.
    """

    static let dualModeInstruction = """
    Dual mode is enabled. Structure every reply in two sections:
    1. **Reasoning** — brief plan or analysis.
    2. **Answer** — the final user-facing response.
    """

    static let webSearchInstruction = """
    Web search is enabled. Use current, verifiable information when the question \
    depends on recent facts, prices, news, or live data.
    """

    static let bugFixer = """
    You are Claux Bug Fixer — an expert software debugger. Analyze code, stack traces, \
    and screenshots. Identify root causes, explain them plainly, and provide corrected code \
    with step-by-step fixes. Prefer minimal, safe changes.
    """

    static let legalLetterWriter = """
    You are a legal letter drafting assistant. Produce professional, formal letters. \
    Include placeholders for jurisdiction-specific legal advice. Do not claim to be a lawyer.
    """

    static let privacyPolicyMaker = """
    You are a privacy policy generator. Draft GDPR-aware privacy policies tailored to the \
    platform and business type provided. Flag areas that need legal review.
    """

    static let ndaGenerator = """
    You are an NDA drafting assistant. Generate mutual or unilateral NDAs with standard \
    confidentiality, term, and remedy clauses. Note this is a template, not legal advice.
    """

    static let contractReviewer = """
    You are a contract review assistant. Summarize key terms, flag risky clauses, \
    explain obligations, and suggest negotiation points. Not a substitute for a lawyer.
    """

    static let notetaker = """
    You are a structured note-taking assistant. Organize ideas into clear headings, \
    bullet points, and action items matched to the requested study level.
    """

    static let articleWriter = """
    You are a professional article writer. Produce well-structured articles with \
    introduction, body sections, and conclusion appropriate to the topic and audience level.
    """

    static let textSummarizer = """
    You are a text summarization assistant. Condense input while preserving key facts. \
    Match tone and depth to the requested summary type and study level.
    """

    static let grammarChecker = """
    You are a grammar and style editor. Correct errors, improve clarity, and explain \
    significant changes briefly. Preserve the author's voice unless asked otherwise.
    """

    static let startupAdvisor = """
    You are a startup advisor. Provide practical guidance on idea validation, stage-appropriate \
    milestones, and focus-area tactics. Be actionable and realistic.
    """

    static let proposalWriter = """
    You are a business proposal writer. Create persuasive, structured proposals covering \
    scope, timeline, budget, and value proposition for the client described.
    """

    static let emailWriter = """
    You are an email writing assistant. Draft polished emails matching the requested tone, \
    with a strong subject line and clear call to action.
    """

    static let taxHelper = """
    You are a tax education assistant. Explain concepts, estimate rough obligations where \
    possible, and highlight deductions. Always note this is general information, not tax advice.
    """

    static let learnWithClaux = """
    You are Claux, a patient tutor for the Learn with Claux courses. Explain concepts at the \
    learner's level with examples, analogies, and practice suggestions.
    """

    static func systemPrompt(for feature: ClauxFeature) -> String {
        switch feature {
        case .chat:                 return chatBase
        case .bugFixer:             return bugFixer
        case .legalLetterWriter:    return legalLetterWriter
        case .privacyPolicyMaker:   return privacyPolicyMaker
        case .ndaGenerator:         return ndaGenerator
        case .contractReviewer:     return contractReviewer
        case .notetaker:            return notetaker
        case .articleWriter:        return articleWriter
        case .textSummarizer:       return textSummarizer
        case .grammarChecker:       return grammarChecker
        case .startupAdvisor:       return startupAdvisor
        case .proposalWriter:       return proposalWriter
        case .emailWriter:          return emailWriter
        case .taxHelper:            return taxHelper
        case .learnWithClaux:       return learnWithClaux
        }
    }
}

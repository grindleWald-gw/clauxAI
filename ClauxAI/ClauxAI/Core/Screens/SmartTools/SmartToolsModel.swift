//
//  SmartToolsModel.swift
//  CL.AI
//
//  Created by Yasir Shah on 09/06/2026.
//

import Foundation

enum SmartToolDestination: Equatable {
    case legalLetterWriter
    case privacyPolicyMaker
    case ndaGenerator
    case contractReviewer
    case startupAdvisor
    case proposalWriter
    case emailWriter
    case taxHelper
    case notetaker
    case articleWriter
    case textSummarizer
    case grammarChecker
}

struct SmartToolSection: Identifiable {
    let id = UUID()
    let title: String
    let tools: [SmartToolItem]
}

struct SmartToolItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let destination: SmartToolDestination?
}

enum SmartToolsData {
    static let sections: [SmartToolSection] = [
        SmartToolSection(
            title: "Legal & Compliance",
            tools: [
                SmartToolItem(
                    title: "Legal Letter Writer",
                    subtitle: "Write legal letters without a lawyer.",
                    icon: "iconLegalWriter",
                    destination: .legalLetterWriter
                ),
                SmartToolItem(
                    title: "Privacy Policy Maker",
                    subtitle: "Generate your policy in seconds.",
                    icon: "privacyPolicyMakerIcon",
                    destination: .privacyPolicyMaker
                ),
                SmartToolItem(
                    title: "NDA Generator",
                    subtitle: "Protect your ideas before sharing them",
                    icon: "ndaGeneratorIcon",
                    destination: .ndaGenerator
                ),
                SmartToolItem(
                    title: "Contract Reviewer",
                    subtitle: "Read every clause before you sign.",
                    icon: "contractReviewerIcon",
                    destination: .contractReviewer
                )
            ]
        ),
        SmartToolSection(
            title: "Writer's Desk",
            tools: [
                SmartToolItem(
                    title: "Notetaker",
                    subtitle: "Capture every idea before it disappears.",
                    icon: "notetakerIcon",
                    destination: .notetaker
                ),
                SmartToolItem(
                    title: "Article Writer",
                    subtitle: "Write professional articles in seconds.",
                    icon: "articleWriterIcon",
                    destination: .articleWriter
                ),
                SmartToolItem(
                    title: "Text Summarizer",
                    subtitle: "Long text short summary in seconds.",
                    icon: "textSummarizerIcon",
                    destination: .textSummarizer
                ),
                SmartToolItem(
                    title: "Grammar Checker",
                    subtitle: "Write without errors every single time.",
                    icon: "grammarCheckerIcon",
                    destination: .grammarChecker
                )
            ]
        ),
        SmartToolSection(
            title: "Business Hub",
            tools: [
                SmartToolItem(
                    title: "Startup Advisor",
                    subtitle: "Turn your idea into a business.",
                    icon: "startupAdvisorIcon",
                    destination: .startupAdvisor
                ),
                SmartToolItem(
                    title: "Proposal Writer",
                    subtitle: "Write proposals that actually win deals.",
                    icon: "proposalWriterIcon",
                    destination: .proposalWriter
                ),
                SmartToolItem(
                    title: "Email Writer",
                    subtitle: "Emails that get opened and replied.",
                    icon: "emailWriterIcon",
                    destination: .emailWriter
                ),
                SmartToolItem(
                    title: "Tax Helper",
                    subtitle: "Understand your taxes without confusion.",
                    icon: "taxHelperIcon",
                    destination: .taxHelper
                )
            ]
        )
    ]
}

//
//  ProposalWriter.swift
//  ClauxAI
//
//  Created by Yasir Shah on 21/06/2026.
//

import SwiftUI

enum ProposalFocusArea: String, CaseIterable, Identifiable {
    case business = "Business Proposal"
    case freelancing = "Freelancing Proposal"
    case investment = "Investment Proposal"
    case partnership = "Partnership Proposal"

    var id: String { rawValue }
}

struct ProposalWriter: View {

    var onBack: () -> Void = {}

    @State private var businessIdea = ""
    @State private var clientInfo = ""
    @State private var timeline = ""
    @State private var budget = ""
    @State private var selectedFocus: ProposalFocusArea = .business
    @State private var outputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 0) {
            SmartToolScreenHeader(title: "Proposal Writer", onBack: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SmartToolDescriptionField(
                        text: $businessIdea,
                        placeholder: "Enter your business idea here...",
                        onSubmit: generate
                    )
                    SmartToolLabeledField(
                        title: "Client/Company Info",
                        placeholder: "Enter client or company details here",
                        text: $clientInfo
                    )
                    SmartToolLabeledField(
                        title: "Timeline",
                        placeholder: "Start date -> end date",
                        text: $timeline
                    )
                    SmartToolLabeledField(
                        title: "Budget",
                        placeholder: "Enter your estimated budget here",
                        text: $budget
                    )
                    SmartToolChipSection(
                        title: "Focus Area",
                        options: ProposalFocusArea.allCases,
                        selection: selectedFocus,
                        onSelect: { selectedFocus = $0 }
                    )

                    if let errorMessage {
                        SmartToolErrorBanner(message: errorMessage)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }

            SmartToolGenerateButton(isLoading: isLoading, action: generate)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appMainbg)
        .smartToolResultSheet(
            isPresented: $showResult,
            resultText: outputText,
            downloadFileName: "proposal"
        )
    }

    private func generate() {
        guard !businessIdea.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        SmartToolGeneration.run(
            isLoading: $isLoading,
            output: $outputText,
            errorMessage: $errorMessage,
            showResult: $showResult
        ) {
            try await ClauxAPIService.shared.generateProposal(
                ProposalWriterInput(
                    businessIdea: businessIdea,
                    clientInfo: clientInfo,
                    timeline: timeline,
                    budget: budget,
                    focusArea: selectedFocus.rawValue
                )
            )
        }
    }
}

#Preview {
    ProposalWriter()
        .frame(width: 900, height: 780)
}

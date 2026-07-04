//
//  StartupAdvisor.swift
//  ClauxAI
//
//  Created by Yasir Shah on 21/06/2026.
//

import SwiftUI

enum StartupStage: String, CaseIterable, Identifiable {
    case idea = "Idea Stage"
    case early = "Early Stage"
    case growth = "Growth Stage"
    case scaling = "Scalling Stage"

    var id: String { rawValue }
}

enum StartupFocusArea: String, CaseIterable, Identifiable {
    case branding = "Branding & Positioning"
    case funding = "Funding & Investment"
    case marketing = "Marketing Strategy"
    case product = "Product Development"

    var id: String { rawValue }
}

struct StartupAdvisor: View {

    var onBack: () -> Void = {}

    @State private var businessIdea = ""
    @State private var selectedStage: StartupStage = .idea
    @State private var selectedFocus: StartupFocusArea = .branding
    @State private var outputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 0) {
            SmartToolScreenHeader(title: "Startup Advisor", onBack: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SmartToolDescriptionField(
                        text: $businessIdea,
                        placeholder: "Enter your business idea here...",
                        onSubmit: generate
                    )
                    SmartToolChipSection(
                        title: "Startup Stage",
                        options: StartupStage.allCases,
                        selection: selectedStage,
                        onSelect: { selectedStage = $0 }
                    )
                    SmartToolChipSection(
                        title: "Focus Area",
                        options: StartupFocusArea.allCases,
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
            downloadFileName: "startup-advice"
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
            try await ClauxAPIService.shared.adviseStartup(
                StartupAdvisorInput(
                    businessIdea: businessIdea,
                    stage: selectedStage.rawValue,
                    focus: selectedFocus.rawValue
                )
            )
        }
    }
}

#Preview {
    StartupAdvisor()
        .frame(width: 900, height: 780)
}

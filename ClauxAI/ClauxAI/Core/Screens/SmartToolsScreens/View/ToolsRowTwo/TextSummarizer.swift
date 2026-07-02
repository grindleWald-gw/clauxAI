//
//  TextSummarizer.swift
//  ClauxAI
//
//  Created by Yasir Shah on 21/06/2026.
//

import SwiftUI

enum SummaryType: String, CaseIterable, Identifiable {
    case short = "Short Summary"
    case detailed = "Detailed Summary"
    case keyInsights = "Key Insights"
    case executive = "Executive Summary"

    var id: String { rawValue }
}

struct TextSummarizer: View {

    var onBack: () -> Void = {}

    @State private var inputText = ""
    @State private var selectedSummaryType: SummaryType = .short
    @State private var selectedStudyLevel: StudyLevel = .beginner
    @State private var outputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 0) {
            SmartToolScreenHeader(title: "Text Summarizer", onBack: onBack)
                .frame(height: 66)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SmartToolDescriptionField(
                        text: $inputText,
                        placeholder: "Paste or Enter text here...",
                        onSubmit: generate
                    )
                    SmartToolChipSection(
                        title: "Summary Type",
                        options: SummaryType.allCases,
                        selection: selectedSummaryType,
                        onSelect: { selectedSummaryType = $0 }
                    )
                    SmartToolChipSection(
                        title: "Study Level",
                        options: StudyLevel.allCases,
                        selection: selectedStudyLevel,
                        onSelect: { selectedStudyLevel = $0 }
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
            downloadFileName: "summary"
        )
    }

    private func generate() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        SmartToolGeneration.run(
            isLoading: $isLoading,
            output: $outputText,
            errorMessage: $errorMessage,
            showResult: $showResult
        ) {
            try await ClauxAPIService.shared.summarizeText(
                TextSummarizerInput(
                    inputText: inputText,
                    summaryType: selectedSummaryType.rawValue,
                    studyLevel: selectedStudyLevel.rawValue
                )
            )
        }
    }
}

#Preview {
    TextSummarizer()
        .frame(width: 900, height: 780)
}

//
//  GrammarChecker.swift
//  CL.AI
//
//  Created by Yasir Shah on 21/06/2026.
//

import SwiftUI

enum GrammarCheckType: String, CaseIterable, Identifiable {
    case grammarFix = "Grammar Fix"
    case spelling = "Spelling Correction"
    case sentence = "Sentence Improvement"
    case professional = "Professional Rewrite"

    var id: String { rawValue }
}

struct GrammarChecker: View {

    var onBack: () -> Void = {}

    @State private var inputText = ""
    @State private var selectedCheckType: GrammarCheckType = .grammarFix
    @State private var selectedStudyLevel: StudyLevel = .beginner
    @State private var outputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 0) {
            SmartToolScreenHeader(title: "Grammar Checker", onBack: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SmartToolDescriptionField(
                        text: $inputText,
                        placeholder: "Paste or Enter text here...",
                        onSubmit: generate
                    )
                    SmartToolChipSection(
                        title: "Check Type",
                        options: GrammarCheckType.allCases,
                        selection: selectedCheckType,
                        onSelect: { selectedCheckType = $0 }
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
            downloadFileName: "grammar-check"
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
            try await ClauxAPIService.shared.checkGrammar(
                GrammarCheckerInput(
                    inputText: inputText,
                    checkType: selectedCheckType.rawValue,
                    studyLevel: selectedStudyLevel.rawValue
                )
            )
        }
    }
}

#Preview {
    GrammarChecker()
        .frame(width: 900, height: 780)
}

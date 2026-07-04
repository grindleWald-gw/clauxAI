//
//  NoteTakerView.swift
//  ClauxAI
//
//  Created by Yasir Shah on 21/06/2026.
//

import SwiftUI

struct NoteTakerView: View {

    var onBack: () -> Void = {}

    @State private var topicDetails = ""
    @State private var selectedStudyLevel: StudyLevel = .beginner
    @State private var outputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 0) {
            SmartToolScreenHeader(title: "Notetaker", onBack: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SmartToolDescriptionField(
                        text: $topicDetails,
                        placeholder: "Enter Topic details here",
                        onSubmit: generate
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
            downloadFileName: "notes"
        )
    }

    private func generate() {
        guard !topicDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        SmartToolGeneration.run(
            isLoading: $isLoading,
            output: $outputText,
            errorMessage: $errorMessage,
            showResult: $showResult
        ) {
            try await ClauxAPIService.shared.generateNotes(
                NotetakerInput(
                    topicDetails: topicDetails,
                    studyLevel: selectedStudyLevel.rawValue
                )
            )
        }
    }
}

#Preview {
    NoteTakerView()
        .frame(width: 900, height: 780)
}

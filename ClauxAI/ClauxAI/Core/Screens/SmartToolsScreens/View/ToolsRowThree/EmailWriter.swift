//
//  EmailWriter.swift
//  ClauxAI
//
//  Created by Yasir Shah on 21/06/2026.
//

import SwiftUI

enum EmailTone: String, CaseIterable, Identifiable {
    case formal = "Formal"
    case friendly = "Friendly"
    case confident = "Confident"
    case professional = "Professional"

    var id: String { rawValue }
}

struct EmailWriter: View {

    var onBack: () -> Void = {}

    @State private var emailDetails = ""
    @State private var userName = ""
    @State private var subject = ""
    @State private var selectedTone: EmailTone = .formal
    @State private var outputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 0) {
            SmartToolScreenHeader(title: "Email Writer", onBack: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SmartToolDescriptionField(
                        text: $emailDetails,
                        placeholder: "Enter your email details here...",
                        onSubmit: generate
                    )
                    SmartToolLabeledField(
                        title: "Your Name",
                        placeholder: "Enter your name here",
                        text: $userName
                    )
                    SmartToolLabeledField(
                        title: "Subject",
                        placeholder: "Enter your subject here",
                        text: $subject
                    )
                    SmartToolChipSection(
                        title: "Email Tone",
                        options: EmailTone.allCases,
                        selection: selectedTone,
                        onSelect: { selectedTone = $0 }
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
            downloadFileName: "email"
        )
    }

    private func generate() {
        guard !emailDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        SmartToolGeneration.run(
            isLoading: $isLoading,
            output: $outputText,
            errorMessage: $errorMessage,
            showResult: $showResult
        ) {
            try await ClauxAPIService.shared.generateEmail(
                EmailWriterInput(
                    emailDetails: emailDetails,
                    userName: userName,
                    subject: subject,
                    tone: selectedTone.rawValue
                )
            )
        }
    }
}

#Preview {
    EmailWriter()
        .frame(width: 900, height: 780)
}

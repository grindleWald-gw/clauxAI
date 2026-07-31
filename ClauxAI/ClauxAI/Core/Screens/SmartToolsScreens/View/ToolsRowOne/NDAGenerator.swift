//
//  NDAGenerator.swift
//  CL.AI
//
//  Created by Yasir Shah on 21/06/2026.
//

import SwiftUI

struct NDAGenerator: View {

    var onBack: () -> Void = {}

    @State private var businessDetails = ""
    @State private var companyName = ""
    @State private var confidentialInfo = ""
    @State private var duration = ""
    @State private var restrictions = ""
    @State private var outputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 0) {
            SmartToolScreenHeader(title: "NDA Generator", onBack: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    descriptionField
                    labeledField(
                        title: "Company Name",
                        placeholder: "Enter your company name here",
                        text: $companyName
                    )
                    labeledField(
                        title: "Confidential Information",
                        placeholder: "Enter your confidential info here",
                        text: $confidentialInfo
                    )
                    labeledField(
                        title: "Duration",
                        placeholder: "Enter NDA duration here",
                        text: $duration
                    )
                    labeledField(
                        title: "Restrictions & Terms",
                        placeholder: "Enter restricted details here",
                        text: $restrictions
                    )

                    if let errorMessage {
                        SmartToolErrorBanner(message: errorMessage)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }

            generateButton
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appMainbg)
        .smartToolResultSheet(
            isPresented: $showResult,
            resultText: outputText,
            downloadFileName: "nda"
        )
    }
}

// MARK: - Form fields

private extension NDAGenerator {

    var descriptionField: some View {
        ZStack(alignment: .topLeading) {
            ChatInputView(text: $businessDetails, onSend: generateNDA)
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)

            if businessDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Enter business and confidentiality details here...")
                    .font(.sfProDisplayRegular(16))
                    .foregroundStyle(Color.tetxGray)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .allowsHitTesting(false)
            }
        }
        .background(Color(hex: "#2B2B2B"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func labeledField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.sfProDisplaySemiBold(16))
                .foregroundStyle(Color.textWhite)

            TextField("", text: text, prompt: Text(placeholder).foregroundColor(Color.tetxGray))
                .textFieldStyle(.plain)
                .font(.sfProDisplayRegular(16))
                .foregroundStyle(Color.textWhite)
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(Color(hex: "#2B2B2B"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    var generateButton: some View {
        Button(action: generateNDA) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color.textWhite)
                }
                Text(isLoading ? "Generating…" : "Generate now")
                    .font(.sfProDisplaySemiBold(18))
                    .foregroundStyle(Color.textWhite)
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 14)
            .background(Color.appOrange)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading || businessDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(isLoading ? 0.7 : 1)
        .frame(maxWidth: .infinity)
    }

    func generateNDA() {
        guard !businessDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        SmartToolGeneration.run(
            isLoading: $isLoading,
            output: $outputText,
            errorMessage: $errorMessage,
            showResult: $showResult
        ) {
            try await ClauxAPIService.shared.generateNDA(
                NDAInput(
                    businessDetails: businessDetails,
                    companyName: companyName,
                    confidentialInfo: confidentialInfo,
                    duration: duration,
                    restrictions: restrictions
                )
            )
        }
    }
}

#Preview {
    NDAGenerator()
        .frame(width: 900, height: 780)
}

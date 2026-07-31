//
//  PolicyMaker.swift
//  CL.AI
//
//  Created by Yasir Shah on 21/06/2026.
//

import SwiftUI

struct PolicyMaker: View {

    var onBack: () -> Void = {}

    @State private var policyDescription = ""
    @State private var platformName = ""
    @State private var businessType = ""
    @State private var websiteURL = ""
    @State private var outputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 0) {
            SmartToolScreenHeader(title: "Privacy Policy Maker", onBack: onBack)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    descriptionField
                    labeledField(
                        title: "App / Website Name",
                        placeholder: "Enter your platform name here",
                        text: $platformName
                    )
                    labeledField(
                        title: "Business Type",
                        placeholder: "Enter your business niche here",
                        text: $businessType
                    )
                    labeledField(
                        title: "Website URL",
                        placeholder: "https://",
                        text: $websiteURL
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
            downloadFileName: "privacy-policy"
        )
    }
}

// MARK: - Form fields

private extension PolicyMaker {

    var descriptionField: some View {
        ZStack(alignment: .topLeading) {
            ChatInputView(text: $policyDescription, onSend: generatePolicy)
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)

            if policyDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Describe your policies here...")
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
        Button(action: generatePolicy) {
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
        .disabled(isLoading || policyDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(isLoading ? 0.7 : 1)
        .frame(maxWidth: .infinity)
    }

    func generatePolicy() {
        guard !policyDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        SmartToolGeneration.run(
            isLoading: $isLoading,
            output: $outputText,
            errorMessage: $errorMessage,
            showResult: $showResult
        ) {
            try await ClauxAPIService.shared.generatePrivacyPolicy(
                PrivacyPolicyInput(
                    policyDescription: policyDescription,
                    platformName: platformName,
                    businessType: businessType,
                    websiteURL: websiteURL
                )
            )
        }
    }
}

#Preview {
    PolicyMaker()
        .frame(width: 900, height: 780)
}

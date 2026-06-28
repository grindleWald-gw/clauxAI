//
//  PolicyMaker.swift
//  ClauxAI
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

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: 66)

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
                    if !outputText.isEmpty {
                        SmartToolOutputSection(text: outputText)
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
    }
}

// MARK: - Header

private extension PolicyMaker {

    var header: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textWhite)
                    .frame(width: 38, height: 38)
                    .background(Color(hex: "#1C1C1C"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.appStroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Text("Privacy Policy Maker")
                .font(.sfProDisplaySemiBold(20))
                .foregroundStyle(Color.textWhite)

            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .background(Color.appSecondarybg)
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
                        .tint(Color(hex: "#D4D4D4"))
                }
                Text(isLoading ? "Generating…" : "Generate now")
                    .font(.sfProDisplaySemiBold(18))
                    .foregroundStyle(Color(hex: "#D4D4D4"))
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 14)
            .background(Color(hex: "#8F6B4F"))
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
            errorMessage: $errorMessage
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

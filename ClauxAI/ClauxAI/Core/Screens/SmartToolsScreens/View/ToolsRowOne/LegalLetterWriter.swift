//
//  LegalLetterWriter.swift
//  ClauxAI
//
//  Created by Yasir Shah on 21/06/2026.
//

import SwiftUI

enum LetterType: String, CaseIterable, Identifiable {
    case complaint = "Complaint Letter"
    case notice = "Notice Letter"
    case agreement = "Agreement"
    case demand = "Demand Letter"
    case employment = "Employment Letter"
    case other = "Other"

    var id: String { rawValue }
}

struct LegalLetterWriter: View {

    var onBack: () -> Void = {}

    @State private var legalIssue = ""
    @State private var userName = ""
    @State private var subject = ""
    @State private var selectedLetterType: LetterType = .complaint
    @State private var outputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showResult = false

    var body: some View {
        VStack(spacing: 0) {
            header
                .frame(height: 66)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    descriptionField
                    labeledField(
                        title: "You Name",
                        placeholder: "Enter your name here",
                        text: $userName
                    )
                    labeledField(
                        title: "Subject",
                        placeholder: "Enter your subject here",
                        text: $subject
                    )
                    letterTypeSection

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
            downloadFileName: "legal-letter"
        )
    }
}

// MARK: - Header

private extension LegalLetterWriter {

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

            Text("Legal Letter Writer")
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

private extension LegalLetterWriter {

    var descriptionField: some View {
        ZStack(alignment: .topLeading) {
            ChatInputView(text: $legalIssue, onSend: generateLetter)
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)

            if legalIssue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Describe your legal issue...")
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

    var letterTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Letter Type")
                .font(.sfProDisplaySemiBold(16))
                .foregroundStyle(Color.textWhite)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(LetterType.allCases) { type in
                        letterTypeChip(type)
                    }
                }
            }
        }
    }

    func letterTypeChip(_ type: LetterType) -> some View {
        Button {
            selectedLetterType = type
        } label: {
            Text(type.rawValue)
                .font(.sfProDisplayMedium(14))
                .foregroundStyle(Color.textWhite)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(Color(hex: "#1C1C1C"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            selectedLetterType == type ? Color.tetxGray : Color.appStroke,
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    var generateButton: some View {
        Button(action: generateLetter) {
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
        .disabled(isLoading || legalIssue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(isLoading ? 0.7 : 1)
        .frame(maxWidth: .infinity)
    }

    func generateLetter() {
        guard !legalIssue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        SmartToolGeneration.run(
            isLoading: $isLoading,
            output: $outputText,
            errorMessage: $errorMessage,
            showResult: $showResult
        ) {
            try await ClauxAPIService.shared.generateLegalLetter(
                LegalLetterInput(
                    legalIssue: legalIssue,
                    userName: userName,
                    subject: subject,
                    letterType: selectedLetterType.rawValue
                )
            )
        }
    }
}

#Preview {
    LegalLetterWriter()
        .frame(width: 900, height: 780)
}

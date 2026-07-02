//
//  ContractReviewer.swift
//  ClauxAI
//
//  Created by Yasir Shah on 21/06/2026.
//

import SwiftUI

enum ContractType: String, CaseIterable, Identifiable {
    case employment = "Employment Contract"
    case nda = "NDA"
    case serviceAgreement = "Service Agreement"
    case rentalAgreement = "Rental Agreement"

    var id: String { rawValue }
}

enum ReviewPreference: String, CaseIterable, Identifiable {
    case riskAnalysis = "Risk Analysis"
    case importantClauses = "Important Clauses"
    case missingTerms = "Missing Terms"
    case paymentLiability = "Payment & Liability Checks"

    var id: String { rawValue }
}

struct ContractReviewer: View {

    var onBack: () -> Void = {}

    @State private var contractDetails = ""
    @State private var selectedContractType: ContractType = .employment
    @State private var selectedReviewPreference: ReviewPreference = .riskAnalysis
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
                    chipSection(
                        title: "Contract Type",
                        options: ContractType.allCases,
                        selection: selectedContractType,
                        onSelect: { selectedContractType = $0 }
                    )
                    chipSection(
                        title: "Review Preferences",
                        options: ReviewPreference.allCases,
                        selection: selectedReviewPreference,
                        onSelect: { selectedReviewPreference = $0 }
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
            downloadFileName: "contract-review"
        )
    }
}

// MARK: - Header

private extension ContractReviewer {

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

            Text("Contract Reviewer")
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

private extension ContractReviewer {

    var descriptionField: some View {
        ZStack(alignment: .topLeading) {
            ChatInputView(text: $contractDetails, onSend: generateReview)
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)

            if contractDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Enter contract details here...")
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

    func chipSection<T: Identifiable & RawRepresentable & Hashable>(
        title: String,
        options: [T],
        selection: T,
        onSelect: @escaping (T) -> Void
    ) -> some View where T.RawValue == String {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.sfProDisplaySemiBold(16))
                .foregroundStyle(Color.textWhite)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(options) { option in
                        selectionChip(
                            title: option.rawValue,
                            isSelected: selection.id == option.id,
                            action: { onSelect(option) }
                        )
                    }
                }
            }
        }
    }

    func selectionChip(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.sfProDisplayMedium(14))
                .foregroundStyle(Color.textWhite)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(Color(hex: "#1C1C1C"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isSelected ? Color.tetxGray : Color.appStroke,
                            lineWidth: 1
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    var generateButton: some View {
        Button(action: generateReview) {
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
        .disabled(isLoading || contractDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity(isLoading ? 0.7 : 1)
        .frame(maxWidth: .infinity)
    }

    func generateReview() {
        guard !contractDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        SmartToolGeneration.run(
            isLoading: $isLoading,
            output: $outputText,
            errorMessage: $errorMessage,
            showResult: $showResult
        ) {
            try await ClauxAPIService.shared.generateContractReview(
                ContractReviewInput(
                    contractDetails: contractDetails,
                    contractType: selectedContractType.rawValue,
                    reviewPreference: selectedReviewPreference.rawValue
                )
            )
        }
    }
}

#Preview {
    ContractReviewer()
        .frame(width: 900, height: 780)
}

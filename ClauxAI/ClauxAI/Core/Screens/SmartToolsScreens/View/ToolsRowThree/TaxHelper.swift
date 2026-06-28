//
//  TaxHelper.swift
//  ClauxAI
//
//  Created by Yasir Shah on 21/06/2026.
//

import SwiftUI

enum TaxType: String, CaseIterable, Identifiable {
    case income = "Income Tax"
    case business = "Business Tax"
    case freelance = "Freelance Income"
    case sales = "Sales Tax"

    var id: String { rawValue }
}

struct TaxHelper: View {

    var onBack: () -> Void = {}

    @State private var financialDetails = ""
    @State private var income = ""
    @State private var expenses = ""
    @State private var countryRegion = ""
    @State private var selectedTaxType: TaxType = .income
    @State private var outputText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            SmartToolScreenHeader(title: "Tax Helper", onBack: onBack)
                .frame(height: 66)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SmartToolDescriptionField(
                        text: $financialDetails,
                        placeholder: "Enter your financial details here...",
                        onSubmit: generate
                    )
                    SmartToolLabeledField(
                        title: "Income",
                        placeholder: "Enter your income here",
                        text: $income
                    )
                    SmartToolLabeledField(
                        title: "Expenses",
                        placeholder: "Enter your expenses here",
                        text: $expenses
                    )
                    SmartToolLabeledField(
                        title: "Country / Region",
                        placeholder: "Enter your country or region name here",
                        text: $countryRegion
                    )
                    SmartToolChipSection(
                        title: "Tax Type",
                        options: TaxType.allCases,
                        selection: selectedTaxType,
                        onSelect: { selectedTaxType = $0 }
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

            SmartToolGenerateButton(isLoading: isLoading, action: generate)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appMainbg)
    }

    private func generate() {
        guard !financialDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        SmartToolGeneration.run(
            isLoading: $isLoading,
            output: $outputText,
            errorMessage: $errorMessage
        ) {
            try await ClauxAPIService.shared.helpWithTax(
                TaxHelperInput(
                    financialDetails: financialDetails,
                    income: income,
                    expenses: expenses,
                    countryRegion: countryRegion,
                    taxType: selectedTaxType.rawValue
                )
            )
        }
    }
}

#Preview {
    TaxHelper()
        .frame(width: 900, height: 780)
}

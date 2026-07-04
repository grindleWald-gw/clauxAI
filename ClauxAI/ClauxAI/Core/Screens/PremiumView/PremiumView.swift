//
//  PremiumView.swift
//  ClauxAI
//
//  Created by Yasir Shah on 28/06/2026.
//

import AppKit
import StoreKit
import SwiftUI

private enum PremiumColors {
    static let background = Color(hex: "#121212")
    static let planBackground = Color(hex: "#202020")
    static let selectedPlanBackground = Color(hex: "#21160F")
    static let orange = Color(hex: "#E97D2B")
    static let purple = Color(hex: "#B52BEF")
    static let red = Color(hex: "#F2383B")
    static let grayBadge = Color(hex: "#4D4D4D")
    static let mutedText = Color(hex: "#8E8E8E")
    static let restoreBackground = Color(hex: "#202022")
    static let borderGray = Color(hex: "#3A3A3A")
    static let oldPrice = Color(hex: "#8A8A8A")
}

struct PremiumView: View {

    @State private var purchaseManager = PurchaseManager.shared
    @State private var selectedPlan: ProductsCore = .monthly
    @State private var purchaseError: String?

    @Environment(\.dismiss) private var dismiss

    private let featureCards: [PremiumFeature] = [
        PremiumFeature(image: .iconSmartAssistant, discription: "Smart AI Assistant"),
        PremiumFeature(image: .iconCodeDebugger, discription: "Code Debugger"),
        PremiumFeature(image: .iconAI, discription: "Smart Ai Toolkit"),
        PremiumFeature(image: .iconToolKit, discription: "Learn to Code")
    ]

    var body: some View {
        ZStack {
            PremiumColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                restoreButtonRow
                    .padding(.top, 16)
                    .padding(.horizontal, 18)

                VStack(spacing: 0) {
                    titleSection
                        .padding(.top, 2)

                    featureCardsRow
                        .padding(.top, 28)

                    paymentCardsRow
                        .padding(.top, 44)

                    trialText
                        .padding(.top, 40)

                    continueButton
                        .padding(.top, 12)

                    securedText
                        .padding(.top, 18)

                    footerLinks
                        .padding(.top, 18)
                }
                .padding(.horizontal, 70)
                .padding(.bottom, 18)
            }
        }
        .frame(width: 1008, height: 640)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .alert("Purchase", isPresented: errorAlertBinding) {
            Button("OK") {
                purchaseError = nil
            }
        } message: {
            Text(purchaseError ?? "")
        }
    }
}

// MARK: - Header

private extension PremiumView {

    var restoreButtonRow: some View {
        HStack {
            Spacer()

            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text("Restore Purchase")
                    .font(.sfProDisplayMedium(12))
                    .foregroundStyle(Color.textWhite)
                    .padding(.horizontal, 18)
                    .frame(height: 32)
                    .background(PremiumColors.restoreBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(purchaseManager.isLoading || purchaseManager.purchaseInProgress)
        }
    }

    var titleSection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Text("Claux Ai")
                    .font(.sfProDisplayBold(36))
                    .foregroundStyle(Color.textWhite)

                Text("PRO")
                    .font(.sfProDisplayHeavy(24))
                    .foregroundStyle(Color.textWhite)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(PremiumColors.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
            }

            Text("Unlock full access to features today.")
                .font(.sfProDisplayRegular(17))
                .foregroundStyle(PremiumColors.mutedText)
        }
    }
}

// MARK: - Feature Cards

private extension PremiumView {

    var featureCardsRow: some View {
        HStack(spacing: 14) {
            ForEach(featureCards) { feature in
                PremiumFeatureCard(feature: feature)
            }
        }
    }
}

private struct PremiumFeature: Identifiable {
    let id = UUID()
    let image: ImageResource
    let discription: String
}

private struct PremiumFeatureCard: View {

    let feature: PremiumFeature

    var body: some View {
        
        HStack {
            Image(feature.image)
                .resizable()
                .frame(width: 36, height: 36 , alignment: .center)
            
            Text(feature.discription)
                .font(.sfProDisplayMedium(14))
                .foregroundStyle(Color.white)
        }
        .frame(width: 174, height: 72)
        .background(PremiumColors.restoreBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(PremiumColors.borderGray, lineWidth: 1)
                )
    }
}

// MARK: - Payment Cards

private extension PremiumView {

    var paymentCardsRow: some View {
        HStack(spacing: 14) {
            ForEach(purchaseManager.sortedPlans) { plan in
                PremiumPaymentCard(
                    plan: plan,
                    product: purchaseManager.product(for: plan),
                    isSelected: selectedPlan == plan,
                    isLoading: purchaseManager.isLoading,
                    purchaseManager: purchaseManager
                ) {
                    selectedPlan = plan
                }
            }
        }
    }
}

private struct PremiumPaymentCard: View {

    let plan: ProductsCore
    let product: Product?
    let isSelected: Bool
    let isLoading: Bool
    let purchaseManager: PurchaseManager
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                Text(badgeText)
                    .font(.sfProDisplayMedium(14))
                    .foregroundStyle(Color.textWhite)
                    .frame(width: 116, height: 36)
                    .background(badgeColor)
                    .clipShape(Capsule())
                    .padding(12)

                Text(plan.title)
                    .font(.sfProDisplayRegular(18))
                    .foregroundStyle(Color.textWhite)
                    .padding(.top, 20)

                if isLoading && product == nil {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.top, 12)
                } else {
                    Text(product?.displayPrice ?? "—")
                        .font(.sfProDisplayBold(30))
                        .foregroundStyle(Color.textWhite)
                        .padding(.top, 6)

                    if let secondaryLine = purchaseManager.secondaryPriceLine(for: plan),
                       plan != .lifetime {
                        Text(secondaryLine)
                            .font(.sfProDisplayRegular(13))
                            .foregroundStyle(PremiumColors.mutedText)
                            .padding(.top, 18)
                    }
                }

                if let footer = purchaseManager.footerLabel(for: plan) {
                    Text(footer)
                        .font(.sfProDisplayRegular(12))
                        .foregroundStyle(PremiumColors.mutedText)
                        .strikethrough(true, color: PremiumColors.red)
                        .padding(.top, 15)
                } else if plan == .lifetime,
                          let secondaryLine = purchaseManager.secondaryPriceLine(for: plan) {
                    Text(secondaryLine)
                        .font(.sfProDisplayRegular(12))
                        .foregroundStyle(PremiumColors.mutedText)
                        .padding(.top, 15)
                }

                Spacer(minLength: 0)
            }
            .frame(width: 208, height: 176)
            .background(isSelected ? PremiumColors.selectedPlanBackground : PremiumColors.planBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? PremiumColors.orange : PremiumColors.borderGray,
                        lineWidth: isSelected ? 2 : 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var badgeText: String {
        if purchaseManager.showFreeTrialBadge(for: plan) {
            return "Free Trail"
        }
        return plan.badge
    }

    private var badgeColor: Color {
        switch plan {
        case .weekly: PremiumColors.grayBadge
        case .monthly: PremiumColors.orange
        case .yearly: PremiumColors.purple
        case .lifetime: PremiumColors.red
        }
    }
}

// MARK: - CTA

private extension PremiumView {

    var trialText: some View {
        Text(purchaseManager.trialSubtitle(for: selectedPlan))
            .font(.sfProDisplayMedium(16))
            .foregroundStyle(Color.textWhite)
            .multilineTextAlignment(.center)
    }

    var continueButton: some View {
        Button {
            Task {
                await purchaseSelectedPlan()
            }
        } label: {
            Group {
                if purchaseManager.purchaseInProgress {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.white)
                } else {
                    Text(purchaseManager.continueButtonTitle(for: selectedPlan))
                        .font(.sfProDisplayBold(28))
                }
            }
            .foregroundStyle(Color.textWhite)
            .frame(width: 354, height: 62)
            .background(PremiumColors.orange)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(purchaseManager.purchaseInProgress || purchaseManager.product(for: selectedPlan) == nil)
    }

    var securedText: some View {
        (
            Text("Secured by Apple  ")
            + Text(Image(systemName: "apple.logo"))
            + Text(", Cancel anytime")
        )
            .font(.sfProDisplayRegular(13))
            .foregroundStyle(PremiumColors.mutedText)
    }

    var footerLinks: some View {
        HStack(spacing: 44) {
            Button("Privacy Policy") {
                openExternalLink(Constants.privacyPolicy)
            }
            .buttonStyle(.plain)

            Button("Continue with Free Plan") {
                dismiss()
            }
            .buttonStyle(.plain)

            Button("Terms of Use") {
                openExternalLink(Constants.termsOfUse)
            }
            .buttonStyle(.plain)
        }
        .font(.sfProDisplayRegular(13))
        .foregroundStyle(PremiumColors.mutedText)
    }

    func openExternalLink(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - StoreKit Actions

private extension PremiumView {

    func restorePurchases() async {
        do {
            try await purchaseManager.restorePurchases()
            if !purchaseManager.hasActiveSubscription {
                purchaseError = "No previous purchases were found."
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    func purchaseSelectedPlan() async {
        guard let product = purchaseManager.product(for: selectedPlan) else {
            purchaseError = "Unable to load this plan from the App Store."
            return
        }

        do {
            try await purchaseManager.purchase(product)
            if purchaseManager.hasActiveSubscription {
                dismiss()
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { purchaseError != nil },
            set: { isPresented in
                if !isPresented {
                    purchaseError = nil
                }
            }
        )
    }
}

#Preview {
    PremiumView()
}

//
//  AIConsentView.swift
//  ClauxAI
//
//  Created by Yasir Shah on 04/07/2026.
//

import AppKit
import SwiftUI

private enum AIConsentColors {
    static let background = Color(hex: "#121212")
    static let cardBackground = Color(hex: "#1C1C1C")
    static let mutedText = Color(hex: "#8E8E8E")
}

struct AIConsentView: View {

    var onAgree: () -> Void
    var onClose: () -> Void

    var body: some View {
        ZStack {
            AIConsentColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.bottom, 24)

                consentCard
                    .padding(.bottom, 24)

                agreeButton
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 32)
        }
        .frame(width: 520)
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Header

private extension AIConsentView {

    var header: some View {
        ZStack {
            Text("AI Data Consent")
                .font(.sfProDisplaySemiBold(20))
                .foregroundStyle(Color.textWhite)

            HStack {
                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textWhite)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Content

private extension AIConsentView {

    var consentCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Before you continue")
                .font(.sfProDisplaySemiBold(18))
                .foregroundStyle(Color.textWhite)

            Text(
                "Claux AI sends your prompts, attachments, and generated content to third-party AI providers (such as Anthropic and OpenAI) to power chat, smart tools, and other AI features."
            )
            .font(.sfProDisplayRegular(15))
            .foregroundStyle(AIConsentColors.mutedText)
            .fixedSize(horizontal: false, vertical: true)

            Text(
                "You must agree before using chat, smart tools, or other AI features. If you close this dialog, you will be asked again the next time you try."
            )
            .font(.sfProDisplayRegular(15))
            .foregroundStyle(AIConsentColors.mutedText)
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 20) {
                Button("Privacy Policy") {
                    openLink(Constants.privacyPolicy)
                }
                .buttonStyle(.plain)

                Button("Terms of Use") {
                    openLink(Constants.termsOfUse)
                }
                .buttonStyle(.plain)
            }
            .font(.sfProDisplayMedium(14))
            .foregroundStyle(Color.appOrange)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AIConsentColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var agreeButton: some View {
        Button(action: onAgree) {
            Text("Agree & Continue")
                .font(.sfProDisplaySemiBold(18))
                .foregroundStyle(Color.textWhite)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.appOrange)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    func openLink(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}

#Preview {
    AIConsentView(onAgree: {}, onClose: {})
}

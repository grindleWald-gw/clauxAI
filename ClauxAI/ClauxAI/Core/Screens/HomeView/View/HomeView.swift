//
//  HomeView.swift
//  CL.AI
//
//  Created by Yasir Shah on 18/05/2026.
//

import SwiftUI

struct HomeView: View {

    var onSubmit: (PromptSubmission) -> Void = { _ in }
    var onSettings: () -> Void = {}

    @State private var promptQuery = ""
    @State private var chatOptions = ChatOptions.default

    private let suggestions: [HomeSuggestion] = [
        HomeSuggestion(
            prompt: "Suggest color palette for brand identity.",
            icon: .designIcon
        ),
        HomeSuggestion(
            prompt: "Build marketing strategy for my shopify store.",
            icon: .businessIcon
        ),
        HomeSuggestion(
            prompt: "Build REST API for web application.",
            icon: .codeIcon
        ),
        HomeSuggestion(
            prompt: "Automate my daily workflow tasks.",
            icon: .taskIcon
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(
                text: "Claux AI / Home",
                showsNewChatButton: true,
                onNewChat: startNewChat,
                onSettings: onSettings
            )

            Spacer(minLength: 0)

            homeHeroContent

            Spacer(minLength: 0)

            PromptView(
                query: $promptQuery,
                chatOptions: $chatOptions,
                onSubmit: onSubmit
            )
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appMainbg)
    }

    private func startNewChat() {
        promptQuery = ""
        chatOptions = ChatOptions.default
    }
}

// MARK: - Hero content

private extension HomeView {

    var homeHeroContent: some View {
        VStack(spacing: 0) {
            homeHeroLogo

            homeTitle
                .padding(.bottom, 12)

            homeSubtitle
                .padding(.bottom, 32)

            homeSuggestionCards
        }
        .frame(width: 693)
    }

    var homeHeroLogo: some View {
        Image(.homeHeroLogo)
            .resizable()
            .scaledToFit()
            .frame(width: 160, height: 160)
    }

    var homeTitle: some View {
        (
            Text("Meet ")
                .foregroundStyle(Color.textWhite)
            + Text("Claux AI,")
                .foregroundStyle(Color.appOrange)
            + Text(" Your Everyday Helper!")
                .foregroundStyle(Color.textWhite)
        )
        .frame(width: 382)
        .font(.sfProDisplayBold(32))
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    var homeSubtitle: some View {
        Text("AI-powered support for developers and engineers.")
            .font(.sfProDisplayRegular(16))
            .foregroundStyle(Color.tetxGray)
            .multilineTextAlignment(.center)
    }

    var homeSuggestionCards: some View {
        HStack(spacing: 12) {
            ForEach(suggestions) { suggestion in
                HomeSuggestionCard(suggestion: suggestion) {
                    promptQuery = suggestion.prompt
                }
            }
        }
    }
}

// MARK: - Models

private struct HomeSuggestion: Identifiable {
    let id = UUID()
    let prompt: String
    let icon: ImageResource
}

// MARK: - Suggestion card

private struct HomeSuggestionCard: View {

    let suggestion: HomeSuggestion
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text(suggestion.prompt)
                .font(.sfProDisplayMedium(14))
                .foregroundStyle(Color.textWhite)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Image(suggestion.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .padding(14)
        .frame(width: 164, height: 108)
        .background(Color(hex: "#1C1C1C"))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture(perform: onTap)
    }
}

#Preview {
    HomeView()
        .frame(width: 900, height: 700)
}

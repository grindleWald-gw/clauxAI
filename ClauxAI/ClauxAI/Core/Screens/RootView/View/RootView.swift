//
//  RootView.swift
//  CL.AI
//
//  Created by Yasir Shah on 18/05/2026.
//

import StoreKit
import SwiftUI

struct RootView: View {

    @Environment(\.requestReview) private var requestReview
    @Bindable private var consentPresenter = AIConsentPresenter.shared
    @State private var sidebarSelection: SidebarDestination = .home
    @State private var screen: AppScreen = .home
    @State private var showPremium = false
    @State private var showSettings = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            SidebarView(
                selectedItem: $sidebarSelection,
                onSelect: handleSidebarSelection,
                onUpgrade: { showPremium = true }
            )

            Divider()

            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.appMainbg)
        .onAppear {
            CreditManager.shared.onRequirePro = { showPremium = true }
            ReviewPromptManager.shared.requestReview = { requestReview() }
            ReviewPromptManager.shared.maybeRequestReviewForLaunch()
        }
        .sheet(isPresented: $showPremium) {
            PremiumView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView {
                showSettings = false
                showPremium = true
            }
        }
        .sheet(item: $consentPresenter.activeRequest) { _ in
            AIConsentView(
                onAgree: { consentPresenter.agreeAndContinue() },
                onClose: { consentPresenter.cancelPresentation() }
            )
            .interactiveDismissDisabled(true)
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        switch screen {
        case .home:
            HomeView(
                onSubmit: { submission in
                    consentPresenter.runAfterConsentIfNeeded {
                        guard CreditManager.shared.requireAccess(to: .chat) else { return }
                        CreditManager.shared.recordChatPrompt()
                        screen = .response(submission)
                    }
                },
                onSettings: { showSettings = true }
            )

        case .bugFixer:
            BugFixerView(onSettings: { showSettings = true })

        case .smartTools:
            SmartToolsView(
                onToolSelect: { destination in
                switch destination {
                case .legalLetterWriter:
                    screen = .legalLetterWriter
                case .privacyPolicyMaker:
                    screen = .privacyPolicyMaker
                case .ndaGenerator:
                    screen = .ndaGenerator
                case .contractReviewer:
                    screen = .contractReviewer
                case .startupAdvisor:
                    screen = .startupAdvisor
                case .proposalWriter:
                    screen = .proposalWriter
                case .emailWriter:
                    screen = .emailWriter
                case .taxHelper:
                    screen = .taxHelper
                case .notetaker:
                    screen = .notetaker
                case .articleWriter:
                    screen = .articleWriter
                case .textSummarizer:
                    screen = .textSummarizer
                case .grammarChecker:
                    screen = .grammarChecker
                }
            },
            onSettings: { showSettings = true }
            )

        case .legalLetterWriter:
            LegalLetterWriter {
                screen = .smartTools
            }

        case .privacyPolicyMaker:
            PolicyMaker {
                screen = .smartTools
            }

        case .ndaGenerator:
            NDAGenerator {
                screen = .smartTools
            }

        case .contractReviewer:
            ContractReviewer {
                screen = .smartTools
            }

        case .startupAdvisor:
            StartupAdvisor {
                screen = .smartTools
            }

        case .proposalWriter:
            ProposalWriter {
                screen = .smartTools
            }

        case .emailWriter:
            EmailWriter {
                screen = .smartTools
            }

        case .taxHelper:
            TaxHelper {
                screen = .smartTools
            }

        case .notetaker:
            NoteTakerView {
                screen = .smartTools
            }

        case .articleWriter:
            ArticleWriter {
                screen = .smartTools
            }

        case .textSummarizer:
            TextSummarizer {
                screen = .smartTools
            }

        case .grammarChecker:
            GrammarChecker {
                screen = .smartTools
            }

        case .learnWithClaux:
            LearnWithClaux(onSettings: { showSettings = true })

        case .response(let submission):
            ResponseVC(
                submission: submission,
                onSettings: { showSettings = true },
                onNewChat: {
                    sidebarSelection = .home
                    screen = .home
                }
            )
        }
    }

    private func handleSidebarSelection(_ destination: SidebarDestination) {
        switch destination {
        case .home:
            screen = .home
        case .bugFixer:
            screen = .bugFixer
        case .smartTools:
            screen = .smartTools
        case .learnWithClaux:
            screen = .learnWithClaux
        }
    }
}

#Preview {
    RootView()
}

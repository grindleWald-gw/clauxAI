//
//  RootView.swift
//  ClauxAI
//
//  Created by Yasir Shah on 18/05/2026.
//

import SwiftUI

struct RootView: View {

    @State private var sidebarSelection: SidebarDestination = .home
    @State private var screen: AppScreen = .home

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            SidebarView(
                selectedItem: $sidebarSelection,
                onSelect: handleSidebarSelection
            )

            Divider()

            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color.appMainbg)
    }

    @ViewBuilder
    private var detailContent: some View {
        switch screen {
        case .home:
            HomeView { submission in
                screen = .response(submission)
            }

        case .bugFixer:
            BugFixerView()

        case .smartTools:
            SmartToolsView { destination in
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
            }

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
            LearnWithClaux()

        case .response(let submission):
            ResponseVC(submission: submission)
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

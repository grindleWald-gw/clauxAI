//
//  AppScreen.swift
//  CL.AI
//
//  Created by Yasir Shah on 31/05/2026.
//

import Foundation

/// Which main content screen is shown in the detail area (right of the sidebar).
enum AppScreen: Equatable {
    case home
    case bugFixer
    case smartTools
    case legalLetterWriter
    case privacyPolicyMaker
    case ndaGenerator
    case contractReviewer
    case startupAdvisor
    case proposalWriter
    case emailWriter
    case taxHelper
    case notetaker
    case articleWriter
    case textSummarizer
    case grammarChecker
    case learnWithClaux
    case response(PromptSubmission)
}

//
//  Model.swift
//  CL.AI
//
//  Created by Yasir Shah on 18/05/2026.
//

import Foundation

import SwiftUI

// MARK: - Sidebar Destination
enum SidebarDestination: String, CaseIterable, Identifiable {

    case home
    case bugFixer
    case smartTools
    case learnWithClaux
  

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home:
            return "Home"

        case .bugFixer:
            return "Bug Fixer"

        case .smartTools:
            return "Smart Tools"

        case .learnWithClaux:
            return "Learn With Claux"

     
        }
    }

    var icon: String {
        switch self {
        case .home:
            return "homeIcon"

        case .bugFixer:
            return "bugFixerIcon"

        case .smartTools:
            return "smartToolsIcon"

        case .learnWithClaux:
            return "learnIcon"

        }
    }
}

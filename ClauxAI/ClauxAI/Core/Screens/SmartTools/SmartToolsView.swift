//
//  SmartToolsView.swift
//  CL.AI
//
//  Created by Yasir Shah on 09/06/2026.
//

import AppKit
import SwiftUI

struct SmartToolsView: View {

    var onToolSelect: (SmartToolDestination) -> Void = { _ in }
    var onSettings: () -> Void = {}

    private let sections = SmartToolsData.sections

    var body: some View {
        VStack(spacing: 0) {
            smartToolsHeader

            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    ForEach(sections) { section in
                        SmartToolSectionView(section: section, onToolSelect: onToolSelect)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appMainbg)
    }

    private var smartToolsHeader: some View {
        HStack(alignment: .center) {
            HStack(spacing: 0) {
                Text("Claux AI")
                Text(" / Smart Tools")
            }
            .font(.sfProDisplaySemiBold(20))
            .foregroundStyle(Color.textWhite)
            Spacer()

            Button(action: onSettings) {
                Image(.settingIcon)
                    .resizable()
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .padding(.horizontal)
        .background(
            Color.appSecondarybg
                .ignoresSafeArea(edges: .top)
        )
    }
}

// MARK: - Section

private struct SmartToolSectionView: View {

    let section: SmartToolSection
    let onToolSelect: (SmartToolDestination) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(section.title)
                .font(.sfProDisplaySemiBold(20))
                .foregroundStyle(Color.textWhite)

            HStack(alignment: .top, spacing: 16) {
                ForEach(section.tools) { tool in
                    SmartToolCard(tool: tool) {
                        guard let destination = tool.destination else { return }
                        onToolSelect(destination)
                    }
                }
            }
        }
    }
}

// MARK: - Card

private struct SmartToolCard: View {

    let tool: SmartToolItem
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            SmartToolIconView(name: tool.icon)
                .frame(width: 38, height: 38)

            Text(tool.title)
                .font(.sfProDisplayBold(18))
                .foregroundStyle(Color.textWhite)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(tool.subtitle)
                .font(.sfProDisplayRegular(14))
                .foregroundStyle(Color.tetxGray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .frame(height: 166)
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

// MARK: - Icon

private struct SmartToolIconView: View {

    let name: String

    var body: some View {
        Group {
            if NSImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: fallbackSymbol)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Color.appOrange)
            }
        }
    }

    private var fallbackSymbol: String {
        switch name {
        case "legalLetterWriterIcon": return "hammer.fill"
        case "privacyPolicyMakerIcon": return "shield.lefthalf.filled"
        case "ndaGeneratorIcon": return "doc.text.fill"
        case "contractReviewerIcon": return "doc.text.magnifyingglass"
        case "notetakerIcon": return "note.text"
        case "articleWriterIcon": return "newspaper.fill"
        case "textSummarizerIcon": return "text.alignleft"
        case "grammarCheckerIcon": return "character.book.closed.fill"
        case "startupAdvisorIcon": return "briefcase.fill"
        case "proposalWriterIcon": return "doc.richtext.fill"
        case "emailWriterIcon": return "envelope.fill"
        case "taxHelperIcon": return "dollarsign.circle.fill"
        default: return "sparkles"
        }
    }
}

#Preview {
    SmartToolsView()
        .frame(width: 1150, height: 900)
}

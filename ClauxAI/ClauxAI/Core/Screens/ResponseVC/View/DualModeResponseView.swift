//
//  DualModeResponseView.swift
//  ClauxAI
//
//  Side-by-side Claude + GPT response panels for dual mode.
//

import AppKit
import SwiftUI

enum DualModelProvider {
    case claude
    case gpt

    var title: String {
        switch self {
        case .claude: "Claude-3.0"
        case .gpt: "GPT-5.0"
        }
    }

    var subtitle: String {
        "Thoughtful, careful and built to reason deep."
    }
}

struct DualModeResponseRow: View {

    let claudeText: String
    let gptText: String
    let claudeStreaming: Bool
    let gptStreaming: Bool
    var onCopyClaude: () -> Void = {}
    var onShareClaude: () -> Void = {}
    var onCopyGPT: () -> Void = {}
    var onShareGPT: () -> Void = {}

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            DualModeModelPanel(
                provider: .claude,
                text: claudeText,
                isStreaming: claudeStreaming,
                onCopy: onCopyClaude,
                onShare: onShareClaude
            )

            DualModeModelPanel(
                provider: .gpt,
                text: gptText,
                isStreaming: gptStreaming,
                onCopy: onCopyGPT,
                onShare: onShareGPT
            )
        }
    }
}

struct DualModeModelPanel: View {

    let provider: DualModelProvider
    let text: String
    let isStreaming: Bool
    var onCopy: () -> Void = {}
    var onShare: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 14)

            Rectangle()
                .fill(Color(hex: "#2E2E2E"))
                .frame(height: 1)
                .padding(.horizontal, 18)

            content
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, minHeight: 280, alignment: .topLeading)
        .background(Color(hex: "#171717"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#333333"), lineWidth: 1)
        )
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(provider.title)
                    .font(.sfProDisplayRegular(13))
                    .foregroundStyle(Color.tetxGray)

                Text(provider.subtitle)
                    .font(.sfProDisplayRegular(15))
                    .foregroundStyle(Color.textWhite)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                DualModeIconButton(systemImage: "doc.on.doc", action: onCopy)
                DualModeIconButton(systemImage: "square.and.arrow.up", action: onShare)
            }
        }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 12) {
            providerAvatar

            Group {
                if text.isEmpty && isStreaming {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color.textWhite)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    MarkdownContentView(text: text, fontSize: 15, lineSpacing: 5, textColor: .textWhite)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var providerAvatar: some View {
        switch provider {
        case .claude:
            Image(.sidebarIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .padding(8)
                .background(Color.appOrange)
                .clipShape(Circle())
        case .gpt:
            ZStack {
                Circle()
                    .fill(Color(hex: "#1C1C1C"))

                Image(systemName: "circle.hexagongrid.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.textWhite)
            }
            .frame(width: 44, height: 44)
        }
    }
}

private struct DualModeIconButton: View {

    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.tetxGray)
                .frame(width: 34, height: 34)
                .background(Color(hex: "#1C1C1C"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "#3A3A3A"), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

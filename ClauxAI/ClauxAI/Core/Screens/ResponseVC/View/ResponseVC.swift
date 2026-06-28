//
//  ResponseVC.swift
//  ClauxAI
//
//  Created by Yasir Shah on 31/05/2026.
//

import AppKit
import SwiftUI

struct ResponseVC: View {

    private struct ChatEntry: Identifiable {
        let id = UUID()
        let role: Message.Role
        var text: String
        var isStreaming: Bool = false
    }

    @State private var promptQuery = ""
    @State private var chatOptions: ChatOptions
    @State private var entries: [ChatEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let initialSubmission: PromptSubmission

    init(submission: PromptSubmission) {
        initialSubmission = submission
        _chatOptions = State(initialValue: submission.options)
    }

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(text: "Claux AI / Response", action: {})

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        ForEach(entries) { entry in
                            switch entry.role {
                            case .user:
                                UserMessageBubble(text: entry.text)
                                    .id(entry.id)
                            case .assistant:
                                AssistantMessageBubble(
                                    text: entry.text,
                                    isStreaming: entry.isStreaming,
                                    onCopy: { copyToClipboard(entry.text) },
                                    onShare: { shareText(entry.text) }
                                )
                                .id(entry.id)
                            }
                        }

                        if let errorMessage {
                            SmartToolErrorBanner(message: errorMessage)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)
                    .padding(.top, 28)
                    .padding(.bottom, 24)
                }
                .onChange(of: entries.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: entries.last?.text) { _, _ in
                    scrollToBottom(proxy)
                }
            }

            PromptView(
                query: $promptQuery,
                chatOptions: $chatOptions,
                isLoading: isLoading,
                onSubmit: sendFollowUp
            )
                .padding(.horizontal, 32)
                .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appMainbg)
        .task {
            await sendInitialMessage()
        }
    }

    private func sendInitialMessage() async {
        guard entries.isEmpty else { return }
        await streamMessage(initialSubmission)
    }

    private func sendFollowUp(_ submission: PromptSubmission) {
        chatOptions = submission.options
        Task { await streamMessage(submission) }
    }

    @MainActor
    private func streamMessage(_ submission: PromptSubmission) async {
        let trimmed = submission.message.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasAttachments = !submission.attachments.isEmpty
        guard (!trimmed.isEmpty || hasAttachments), !isLoading else { return }

        errorMessage = nil
        isLoading = true

        let displayMessage = trimmed.isEmpty ? "Sent \(submission.attachments.count) image(s)" : trimmed
        entries.append(ChatEntry(role: .user, text: displayMessage))
        let assistantIndex = entries.count
        entries.append(ChatEntry(role: .assistant, text: "", isStreaming: true))

        let history = entries
            .dropLast(2)
            .filter { !$0.isStreaming && !$0.text.isEmpty }
            .map { ChatTurn(role: $0.role, content: $0.text) }

        do {
            try await ClauxAPIService.shared.streamChat(
                message: submission.message,
                history: history,
                attachments: submission.attachments,
                options: submission.options
            ) { token in
                Task { @MainActor in
                    guard assistantIndex < entries.count else { return }
                    entries[assistantIndex].text += token
                }
            }

            if assistantIndex < entries.count {
                entries[assistantIndex].isStreaming = false
                if entries[assistantIndex].text.isEmpty {
                    entries[assistantIndex].text = "No response received."
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            if assistantIndex < entries.count {
                entries.remove(at: assistantIndex)
            }
        }

        isLoading = false
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let lastID = entries.last?.id else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func shareText(_ text: String) {
        let picker = NSSharingServicePicker(items: [text])
        if let window = NSApp.keyWindow, let contentView = window.contentView {
            picker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
        }
    }
}

// MARK: - User bubble

private struct UserMessageBubble: View {

    let text: String

    var body: some View {
        HStack {
            Spacer(minLength: 80)

            Text(text)
                .font(.sfProDisplayRegular(16))
                .foregroundStyle(Color.textWhite)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Color(hex: "#2B2B2B"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Assistant bubble

private struct AssistantMessageBubble: View {

    let text: String
    var isStreaming: Bool = false
    var onCopy: () -> Void = {}
    var onShare: () -> Void = {}

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            assistantAvatar

            VStack(alignment: .leading, spacing: 18) {
                assistantText

                if !isStreaming, !text.isEmpty {
                    HStack(spacing: 10) {
                        MessageActionButton(
                            title: "Copy",
                            systemImage: "doc.on.doc",
                            action: onCopy
                        )
                        MessageActionButton(
                            title: "Share",
                            systemImage: "square.and.arrow.up",
                            action: onShare
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var assistantAvatar: some View {
        Image(.sidebarIcon)
            .resizable()
            .scaledToFit()
            .frame(width: 36, height: 36)
            .padding(6)
            .background(Color.appOrange)
            .clipShape(Circle())
    }

    @ViewBuilder
    private var assistantText: some View {
        if text.isEmpty && isStreaming {
            ProgressView()
                .controlSize(.small)
                .tint(Color.textWhite)
        } else if let attributed = try? AttributedString(markdown: text) {
            Text(attributed)
                .font(.sfProDisplayRegular(16))
                .foregroundStyle(Color.textWhite)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
        } else {
            Text(text)
                .font(.sfProDisplayRegular(16))
                .foregroundStyle(Color.textWhite)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
        }
    }
}

// MARK: - Message actions

private struct MessageActionButton: View {

    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.tetxGray)

                Text(title)
                    .font(.sfProDisplayMedium(14))
                    .foregroundStyle(Color.tetxGray)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(hex: "#1C1C1C"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ResponseVC(submission: PromptSubmission(
        message: "What do you know about programming?",
        options: .default
    ))
    .frame(width: 900, height: 820)
}

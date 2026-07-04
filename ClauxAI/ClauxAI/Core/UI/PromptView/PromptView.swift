//
//  PromptView.swift
//  ClauxAI
//
//  Created by Yasir Shah on 30/05/2026.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

enum PromptModel: String, CaseIterable, Identifiable {
    case opus = "Opus 4.5"
    case sonnet = "Sonnet 4.6"
    case haiku = "Haiku 4.5"

    var id: String { rawValue }

    var selectorTitle: String {
        switch self {
        case .opus: return "4.5 Opus"
        case .sonnet: return "4.6 Sonnet"
        case .haiku: return "4.5 Haiku"
        }
    }
}

struct PromptView: View {

    @Binding var query: String
    @Binding var chatOptions: ChatOptions
    var isLoading: Bool = false
    var onSubmit: (PromptSubmission) -> Void = { _ in }

    @State private var isModelMenuOpen = false
    @State private var attachments: [PromptAttachment] = []
    @State private var isFilePickerPresented = false
    @State private var textLineCount = 1

    private enum Layout {
        static let baseHeight: CGFloat = 150
        static let lineHeight: CGFloat = 22
        static let maxExtraLines = 3
        static let attachmentStripExtra: CGFloat = 42
        static let thumbnailSize: CGFloat = 32
    }

    private var promptHeight: CGFloat {
        if showsPlaceholder {
            return Layout.baseHeight
        }

        let extraLines = min(max(0, textLineCount - 1), Layout.maxExtraLines)
        let attachmentExtra = attachments.isEmpty ? 0 : Layout.attachmentStripExtra
        return Layout.baseHeight + CGFloat(extraLines) * Layout.lineHeight + attachmentExtra
    }

    var body: some View {
        VStack(spacing: 0) {
            textInputSection
            toolbarSection
        }
        .frame(height: promptHeight)
        .animation(.easeOut(duration: 0.15), value: promptHeight)
        .background(Color.appSecondarybg)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.appStroke, lineWidth: 1)
        )
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { handleFileSelection($0) }
        .onChange(of: query) { _, newValue in
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                textLineCount = 1
            }
        }
    }
}

// MARK: - Text input

private extension PromptView {

    private var showsPlaceholder: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && attachments.isEmpty
    }

    var textInputSection: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 10) {
                ChatInputView(text: $query, lineCount: $textLineCount, onSend: submitQuery)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if !attachments.isEmpty {
                    attachmentStrip
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)

            if showsPlaceholder {
                Text("Enter your query here...")
                    .font(.sfProDisplayRegular(16))
                    .foregroundStyle(Color.tetxGray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 10)
                    .allowsHitTesting(false)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(hex: "#2B2B2B"))
    }

    var attachmentStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(attachments) { attachment in
                    attachmentThumbnail(attachment)
                }
            }
        }
    }

    func attachmentThumbnail(_ attachment: PromptAttachment) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: attachment.image)
                .resizable()
                .scaledToFill()
                .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                removeAttachment(attachment)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.textWhite)
                    .frame(width: 18, height: 18)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .offset(x: 6, y: -6)
        }
    }
}

// MARK: - Toolbar

private extension PromptView {

    var toolbarSection: some View {
        HStack(spacing: 10) {
            borderedIconButton(icon: .fileUploadIcon) {
                isFilePickerPresented = true
            }

            togglePill(
                title: "Dual Mode",
                icon: .dualModeIcon,
                isOn: $chatOptions.dualModeEnabled
            )

            togglePill(
                title: "Web Search",
                icon: .websearchIcon,
                isOn: $chatOptions.webSearchEnabled
            )

            Spacer(minLength: 12)

            modelSelector

           // borderedIconButton(icon: .homeMicIcon) {}

            submitButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.appSecondarybg)
    }

    var modelSelector: some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                isModelMenuOpen.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Text(chatOptions.model.selectorTitle)
                    .font(.sfProDisplayMedium(14))
                    .foregroundStyle(Color.textWhite)

                Image(.chevronDownIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
            }
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(Color(hex: "#1C1C1C"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .background(alignment: .top) {
            if isModelMenuOpen {
                modelPickerMenu
                    .offset(y: -modelPickerMenuHeight )
            }
        }
    }

    var modelPickerMenu: some View {
        VStack(spacing: 0) {
            ForEach(PromptModel.allCases) { model in
                Button {
                    chatOptions.model = model
                    isModelMenuOpen = false
                } label: {
                    Text(model.rawValue)
                        .font(.sfProDisplayMedium(14))
                        .foregroundStyle(Color.textWhite)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 196)
        .background(Color(hex: "#1E1E1E"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
    }

    private var modelPickerMenuHeight: CGFloat {
        CGFloat(PromptModel.allCases.count) * 34
    }

    var submitButton: some View {
        Button(action: submitQuery) {
            Text("Submit")
                .font(.sfProDisplaySemiBold(16))
                .foregroundStyle(Color.textWhite)
                .padding(.horizontal, 22)
                .frame(height: 40)
                .background(Color.appOrange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(isSubmitDisabled)
        .opacity(isSubmitDisabled ? 0.5 : 1)
    }

    private var isSubmitDisabled: Bool {
        isLoading || (query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && attachments.isEmpty)
    }

    func borderedIconButton(icon: ImageResource, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(icon)
                .resizable()
                .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .background(Color(hex: "#1C1C1C"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func togglePill(
        title: String,
        icon: ImageResource,
        isOn: Binding<Bool>
    ) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundStyle(isOn.wrappedValue ? Color(hex: "#FFFFFF") : Color(hex: "#A1A1A1"))
                                     
                Text(title)
                    .font(.sfProDisplayMedium(14))
                    .foregroundStyle(isOn.wrappedValue ? Color(hex: "#FFFFFF") : Color(hex: "#A1A1A1"))
            }
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(isOn.wrappedValue ? Color(hex: "#333333") : Color(hex: "#1C1C1C"))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isOn.wrappedValue ? Color.white : Color.appStroke,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    func submitQuery() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isSubmitDisabled else { return }

        let attachmentPayload = attachments.map { ChatAttachment(image: $0.image) }
        let message = trimmed.isEmpty ? "Please analyze the attached image(s)." : trimmed

        onSubmit(PromptSubmission(
            message: message,
            options: chatOptions,
            attachments: attachmentPayload
        ))

        query = ""
        attachments = []
        textLineCount = 1
    }

    func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }

                if let image = NSImage(contentsOf: url) {
                    attachments.append(PromptAttachment(image: image))
                }
            }
        case .failure:
            break
        }
    }

    func removeAttachment(_ attachment: PromptAttachment) {
        attachments.removeAll { $0.id == attachment.id }
    }
}

// MARK: - Models

private struct PromptAttachment: Identifiable {
    let id = UUID()
    let image: NSImage
}

#Preview {
    ZStack {
        Color.appMainbg.ignoresSafeArea()
        PromptView(
            query: .constant(""),
            chatOptions: .constant(.default)
        )
        .padding(32)
    }
    .frame(width: 900, height: 200)
}

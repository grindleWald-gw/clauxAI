//
//  BugFixerView.swift
//  ClauxAI
//
//  Created by Yasir Shah on 31/05/2026.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct BugFixerView: View {

    var onSettings: () -> Void = {}

    @State private var purchaseManager = PurchaseManager.shared

    private enum Layout {
        static let inputHeight: CGFloat = 217
        static let outputHeight: CGFloat = 317
        static let thumbnailSize: CGFloat = 72
        static let attachButtonSize: CGFloat = 32
        static let inputPadding: CGFloat = 16
    }

    @State private var promptText = ""
    @State private var responseText = ""
    @State private var attachments: [BugFixerAttachment] = []
    @State private var isImagePickerPresented = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            AppHeaderView(text: "Claux AI / Bug Fixer", onSettings: onSettings)

            VStack(spacing: 20) {
                if !purchaseManager.hasActiveSubscription {
                    SmartToolErrorBanner(
                        message: CreditManager.shared.proRequiredMessage(for: .bugFixer)
                    )
                }

                inputSection
                    .frame(height: Layout.inputHeight)

                outputSection
                    .frame(height: Layout.outputHeight)

                Spacer(minLength: 0)

                generateButton
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appMainbg)
        .fileImporter(
            isPresented: $isImagePickerPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { handleImageSelection($0) }
    }
}

// MARK: - Sections

private extension BugFixerView {

    var inputSection: some View {
        ZStack(alignment: .topLeading) {
            ChatInputView(text: $promptText, onSend: generateResponse)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 4)
                .padding(.horizontal, 4)
                .padding(.bottom, Layout.attachButtonSize + Layout.inputPadding + 8)

            if promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Paste error logs here...")
                    .font(.sfProDisplayRegular(16))
                    .foregroundStyle(Color.tetxGray)
                    .padding(.horizontal, Layout.inputPadding)
                    .padding(.top, Layout.inputPadding + 2)
                    .allowsHitTesting(false)
            }

            VStack {
                Spacer(minLength: 0)

                HStack(alignment: .bottom, spacing: 12) {
                    uploadImageButton

                    if !attachments.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(attachments) { attachment in
                                    attachmentThumbnail(attachment)
                                }
                            }
                        }
                    }
                }
                .padding(Layout.inputPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#2B2B2B"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    var uploadImageButton: some View {
        Button {
            isImagePickerPresented = true
        } label: {
            Image(.fileUploadIcon)
                .resizable()
                .foregroundStyle(Color.tetxGray)
                .frame(width: Layout.attachButtonSize, height: Layout.attachButtonSize)
                .background(Color(hex: "#1C1C1C"))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.appStroke, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .help("Upload image")
    }

    func attachmentThumbnail(_ attachment: BugFixerAttachment) -> some View {
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

    var outputSection: some View {
        ScrollView {
            Group {
                if isLoading && responseText.isEmpty {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Color.textWhite)
                        Text("Analyzing…")
                            .font(.sfProDisplayRegular(16))
                            .foregroundStyle(Color.tetxGray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if let errorMessage, responseText.isEmpty {
                    SmartToolErrorBanner(message: errorMessage)
                } else if responseText.isEmpty {
                    Text("Response will appear here.")
                        .font(.sfProDisplayRegular(16))
                        .foregroundStyle(Color.tetxGray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Group {
                        if let attributed = try? AttributedString(markdown: responseText) {
                            Text(attributed)
                        } else {
                            Text(responseText)
                        }
                    }
                    .font(.sfProDisplayRegular(16))
                    .foregroundStyle(Color.textWhite)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appStroke, lineWidth: 1)
        )
    }

    var generateButton: some View {
        Button(action: generateResponse) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color.textWhite)
                }
                Text(isLoading ? "Generating…" : "Generate now")
                    .font(.sfProDisplaySemiBold(18))
                    .foregroundStyle(Color.textWhite)
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 14)
            .background(Color.appOrange)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(
            isLoading
                || promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !CreditManager.shared.canAccess(.bugFixer)
        )
        .opacity(isLoading ? 0.7 : 1)
        .frame(maxWidth: .infinity)
    }

    func generateResponse() {
        let trimmed = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isLoading else { return }

        AIConsentPresenter.shared.runAfterConsentIfNeeded {
            guard CreditManager.shared.requireAccess(to: .bugFixer) else { return }

            isLoading = true
            errorMessage = nil
            responseText = ""

            let imageAttachments = attachments.map { ChatAttachment(image: $0.image) }

            Task {
                do {
                    responseText = try await ClauxAPIService.shared.fixBug(
                        BugFixerInput(
                            prompt: trimmed,
                            attachments: imageAttachments,
                            options: ChatOptions(
                                model: .sonnet,
                                dualModeEnabled: false,
                                webSearchEnabled: false,
                                temperature: APIConfiguration.defaultTemperature,
                                maxTokens: APIConfiguration.bugFixerMaxTokens
                            )
                        )
                    )
                } catch {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        }
    }

    func handleImageSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }

                if let image = NSImage(contentsOf: url) {
                    attachments.append(BugFixerAttachment(image: image))
                }
            }
        case .failure:
            break
        }
    }

    func removeAttachment(_ attachment: BugFixerAttachment) {
        attachments.removeAll { $0.id == attachment.id }
    }
}

// MARK: - Models

private struct BugFixerAttachment: Identifiable {
    let id = UUID()
    let image: NSImage
}

#Preview {
    BugFixerView()
        .frame(width: 900, height: 780)
}

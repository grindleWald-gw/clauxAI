//
//  ResultView.swift
//  CL.AI
//
//  Created by Yasir Shah on 02/07/2026.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

private enum ResultColors {
    static let background = Color(hex: "#121212")
    static let contentBackground = Color(hex: "#1C1C1C")
    static let copyButton = Color(hex: "#2B2B2B")
    static let downloadButton = Color.appOrange
}

struct ResultView: View {

    let resultText: String
    var downloadFileName: String = "claux-result"

    @Environment(\.dismiss) private var dismiss
    @State private var didCopy = false
    @State private var isExporting = false

    var body: some View {
        ZStack {
            ResultColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                titleRow
                    .padding(.top, 28)
                    .padding(.horizontal, 28)

                resultContent
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                actionButtons
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .frame(width: 800, height: 680)
        .fileExporter(
            isPresented: $isExporting,
            document: PlainTextDocument(text: resultText),
            contentType: .plainText,
            defaultFilename: downloadFileName
        ) { _ in }
    }
}

// MARK: - Header

private extension ResultView {

    var titleRow: some View {
        ZStack {
            Text("Here is the result!")
                .font(.sfProDisplaySemiBold(22))
                .foregroundStyle(Color.textWhite)

            HStack {
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textWhite)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Content

private extension ResultView {

    var resultContent: some View {
        ScrollView(showsIndicators: true) {
            resultTextView
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(ResultColors.contentBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var resultTextView: some View {
        MarkdownContentView(text: resultText, fontSize: 16, lineSpacing: 6, textColor: .textWhite)
    }
}

// MARK: - Actions

private extension ResultView {

    var actionButtons: some View {
        HStack(spacing: 16) {
            Button(action: copyText) {
                Text(didCopy ? "Copied!" : "Copy Text")
                    .font(.sfProDisplaySemiBold(18))
                    .foregroundStyle(Color.textWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(ResultColors.copyButton)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                isExporting = true
            } label: {
                Text("Download")
                    .font(.sfProDisplaySemiBold(18))
                    .foregroundStyle(Color.textWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.appOrange)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    func copyText() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(resultText, forType: .string)
        didCopy = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            didCopy = false
        }
    }
}

// MARK: - Export document

private struct PlainTextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            text = string
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

#Preview {
    ResultView(
        resultText: """
        Subject: Complaint Regarding Late Salary Payment

        Dear HR Manager,

        I am writing to formally raise a concern regarding the delay in my salary payment for the month of March 2026. As per company policy and my employment contract, salaries are due on the 5th of each month.

        Despite multiple follow-ups, I have not received my payment or any clear explanation for the delay. This has caused financial inconvenience and uncertainty.

        I kindly request that my salary be processed immediately and that I receive confirmation of the payment date. I would also appreciate clarification on the reason for this delay to prevent recurrence.

        Thank you for your attention to this matter.

        Sincerely,
        Ahmed Khan
        """,
        downloadFileName: "legal-letter"
    )
}

//
//  MarkdownContentView.swift
//  CL.AI
//
//  Renders AI responses (chat, bug fixer, smart tools) as proper block-level
//  markdown — headings, lists, code blocks, quotes — instead of raw text.
//

import AppKit
import SwiftUI

struct MarkdownContentView: View {

    let text: String
    var fontSize: CGFloat = 16
    var lineSpacing: CGFloat = 5
    var textColor: Color = .textWhite
    var secondaryColor: Color = .tetxGray
    var accentColor: Color = .appOrange
    var blockSpacing: CGFloat = 14

    var body: some View {
        VStack(alignment: .leading, spacing: blockSpacing) {
            ForEach(Array(MarkdownParser.parse(text).enumerated()), id: \.offset) { _, block in
                blockView(for: block)
            }
        }
    }

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let content):
            inlineText(content, font: headingFont(for: level))
                .padding(.top, level <= 2 ? 4 : 0)

        case .paragraph(let content):
            inlineText(content, font: .sfProDisplayRegular(fontSize))

        case .bulletItem(let content):
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 5, height: 5)
                    .padding(.top, fontSize * 0.45)
                inlineText(content, font: .sfProDisplayRegular(fontSize))
            }

        case .numberedItem(let number, let content):
            HStack(alignment: .top, spacing: 10) {
                Text("\(number).")
                    .font(.sfProDisplaySemiBold(fontSize))
                    .foregroundStyle(accentColor)
                    .frame(minWidth: fontSize * 1.4, alignment: .trailing)
                inlineText(content, font: .sfProDisplayRegular(fontSize))
            }

        case .blockquote(let content):
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(accentColor.opacity(0.55))
                    .frame(width: 3)
                inlineText(content, font: .sfProDisplayRegular(fontSize))
                    .foregroundStyle(secondaryColor)
            }

        case .codeBlock(let language, let code):
            MarkdownCodeBlockView(language: language, code: code, fontSize: fontSize)

        case .rule:
            Rectangle()
                .fill(secondaryColor.opacity(0.3))
                .frame(height: 1)
        }
    }

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1:  return .sfProDisplaySemiBold(fontSize + 8)
        case 2:  return .sfProDisplaySemiBold(fontSize + 5)
        case 3:  return .sfProDisplaySemiBold(fontSize + 3)
        default: return .sfProDisplaySemiBold(fontSize + 1)
        }
    }

    @ViewBuilder
    private func inlineText(_ raw: String, font: Font) -> some View {
        inlineAttributedText(raw)
            .font(font)
            .foregroundStyle(textColor)
            .multilineTextAlignment(.leading)
            .lineSpacing(lineSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func inlineAttributedText(_ raw: String) -> Text {
        if let attributed = try? AttributedString(
            markdown: raw,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attributed)
        }
        return Text(raw)
    }
}

// MARK: - Code block

private struct MarkdownCodeBlockView: View {

    let language: String?
    let code: String
    var fontSize: CGFloat

    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Rectangle()
                .fill(Color.appStroke)
                .frame(height: 1)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: max(fontSize - 1, 12), design: .monospaced))
                    .foregroundStyle(Color.textWhite)
                    .padding(14)
            }
        }
        .background(Color(hex: "#111111"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var header: some View {
        HStack {
            Text((language?.isEmpty == false ? language! : "code").uppercased())
                .font(.sfProDisplayMedium(11))
                .foregroundStyle(Color.tetxGray)
                .tracking(0.5)

            Spacer(minLength: 8)

            Button(action: copy) {
                HStack(spacing: 5) {
                    Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                    Text(didCopy ? "Copied" : "Copy")
                        .font(.sfProDisplayMedium(11))
                }
                .foregroundStyle(Color.tetxGray)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(hex: "#1A1A1A"))
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        didCopy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { didCopy = false }
    }
}

// MARK: - Block model

private enum MarkdownBlock {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case bulletItem(text: String)
    case numberedItem(number: Int, text: String)
    case blockquote(text: String)
    case codeBlock(language: String?, code: String)
    case rule
}

// MARK: - Parser

private enum MarkdownParser {

    static func parse(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = text.components(separatedBy: "\n")
        var i = 0
        var paragraphBuffer: [String] = []

        func flushParagraph() {
            guard !paragraphBuffer.isEmpty else { return }
            let joined = paragraphBuffer.joined(separator: "\n")
            if !joined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                blocks.append(.paragraph(text: joined))
            }
            paragraphBuffer.removeAll()
        }

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                flushParagraph()
                let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                i += 1
                var codeLines: [String] = []
                while i < lines.count, !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                if i < lines.count { i += 1 }
                blocks.append(.codeBlock(language: language.isEmpty ? nil : language, code: codeLines.joined(separator: "\n")))
                continue
            }

            if isHorizontalRule(trimmed) {
                flushParagraph()
                blocks.append(.rule)
                i += 1
                continue
            }

            if let (level, headingText) = parseHeading(trimmed) {
                flushParagraph()
                blocks.append(.heading(level: level, text: headingText))
                i += 1
                continue
            }

            if trimmed.hasPrefix(">") {
                flushParagraph()
                var quoteLines: [String] = []
                while i < lines.count, lines[i].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                    let stripped = lines[i].trimmingCharacters(in: .whitespaces).dropFirst()
                    quoteLines.append(String(stripped).trimmingCharacters(in: .whitespaces))
                    i += 1
                }
                blocks.append(.blockquote(text: quoteLines.joined(separator: " ")))
                continue
            }

            if let bulletText = parseBullet(trimmed) {
                flushParagraph()
                blocks.append(.bulletItem(text: bulletText))
                i += 1
                continue
            }

            if let (number, itemText) = parseNumbered(trimmed) {
                flushParagraph()
                blocks.append(.numberedItem(number: number, text: itemText))
                i += 1
                continue
            }

            if trimmed.isEmpty {
                flushParagraph()
                i += 1
                continue
            }

            paragraphBuffer.append(line)
            i += 1
        }

        flushParagraph()
        return blocks
    }

    private static func parseHeading(_ line: String) -> (Int, String)? {
        guard line.hasPrefix("#") else { return nil }
        var level = 0
        var idx = line.startIndex
        while idx < line.endIndex, line[idx] == "#", level < 6 {
            level += 1
            idx = line.index(after: idx)
        }
        guard idx < line.endIndex, line[idx] == " " else { return nil }
        let text = String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        return (level, text)
    }

    private static func parseBullet(_ line: String) -> String? {
        for marker in ["- ", "* ", "+ "] {
            if line.hasPrefix(marker) {
                return String(line.dropFirst(marker.count))
            }
        }
        return nil
    }

    private static func parseNumbered(_ line: String) -> (Int, String)? {
        guard let separatorRange = line.range(of: ". ") ?? line.range(of: ") ") else { return nil }
        let numberPart = line[line.startIndex..<separatorRange.lowerBound]
        guard !numberPart.isEmpty, numberPart.allSatisfy(\.isNumber), let number = Int(numberPart) else { return nil }
        let text = String(line[separatorRange.upperBound...])
        return (number, text)
    }

    private static func isHorizontalRule(_ line: String) -> Bool {
        let stripped = line.replacingOccurrences(of: " ", with: "")
        guard stripped.count >= 3 else { return false }
        return stripped.allSatisfy { $0 == "-" }
            || stripped.allSatisfy { $0 == "*" }
            || stripped.allSatisfy { $0 == "_" }
    }
}

#Preview {
    ScrollView {
        MarkdownContentView(text: """
        # Heading One
        A short intro paragraph that wraps across multiple lines to check leading alignment and line spacing behave nicely inside the bubble.

        ## Section Two
        - First bullet point with **bold** and *italic* text
        - Second bullet with `inline code`
        - Third bullet

        1. Step one
        2. Step two
        3. Step three

        > A blockquote worth noting.

        ```swift
        func greet(name: String) -> String {
            "Hello, \\(name)!"
        }
        ```

        ---

        Final paragraph after a divider.
        """)
        .padding(24)
    }
    .frame(width: 640, height: 760)
    .background(Color.appMainbg)
}

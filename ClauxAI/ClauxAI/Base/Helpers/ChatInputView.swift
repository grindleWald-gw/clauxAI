//
//  ChatInputView.swift
//  CL.AI
//
//  Created by Yasir Shah on 13/05/2026.
//

import SwiftUI
import AppKit

struct ChatInputView: NSViewRepresentable {

    @Binding var text: String
    var lineCount: Binding<Int>?
    var onSend: () -> Void

    init(text: Binding<String>, lineCount: Binding<Int>? = nil, onSend: @escaping () -> Void) {
        _text = text
        self.lineCount = lineCount
        self.onSend = onSend
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = CustomTextView()
        textView.delegate = context.coordinator
        textView.onSend = onSend

        configure(textView)

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView

        context.coordinator.textView = textView
        context.coordinator.scrollView = scrollView

        textView.string = text
        ChatInputStyle.apply(to: textView)

        DispatchQueue.main.async {
            context.coordinator.reportLineCount()
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        guard let textView = context.coordinator.textView else { return }

        context.coordinator.resizeTextViewIfNeeded()
        ChatInputStyle.apply(to: textView)

        guard text != context.coordinator.syncedText else { return }

        if textView.string != text {
            textView.string = text
            ChatInputStyle.apply(to: textView)
        }

        context.coordinator.syncedText = text
        context.coordinator.reportLineCount()
    }

    private func configure(_ textView: NSTextView) {
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.font = ChatInputStyle.font
        textView.textContainerInset = NSSize(width: 4, height: 6)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ChatInputView
        weak var textView: NSTextView?
        weak var scrollView: NSScrollView?
        var syncedText = ""

        init(_ parent: ChatInputView) {
            self.parent = parent
            self.syncedText = parent.text
        }

        func resizeTextViewIfNeeded() {
            guard let scrollView, let textView else { return }

            let width = scrollView.contentSize.width
            guard width > 0 else { return }

            if abs(textView.frame.width - width) > 0.5 {
                var frame = textView.frame
                frame.size.width = width
                textView.frame = frame
            }

            reportLineCount()
        }

        func reportLineCount() {
            guard let textView else { return }

            let count = Self.lineCount(in: textView)
            if let lineCount = parent.lineCount, lineCount.wrappedValue != count {
                lineCount.wrappedValue = count
            }
        }

        static func lineCount(in textView: NSTextView) -> Int {
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else {
                return 1
            }

            layoutManager.ensureLayout(for: textContainer)

            var count = 0
            var glyphIndex = 0
            let numberOfGlyphs = layoutManager.numberOfGlyphs

            while glyphIndex < numberOfGlyphs {
                var lineRange = NSRange()
                layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineRange)
                count += 1
                glyphIndex = NSMaxRange(lineRange)
            }

            return max(1, count)
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            ChatInputStyle.apply(to: textView)

            let newText = textView.string
            syncedText = newText

            if parent.text != newText {
                parent.text = newText
            }

            reportLineCount()
        }
    }
}

// MARK: - Text styling

private enum ChatInputStyle {
    static let textColor = NSColor.white
    static let font = NSFont.systemFont(ofSize: 16)

    static func apply(to textView: NSTextView) {
        textView.textColor = textColor
        textView.insertionPointColor = textColor
        textView.font = font
        textView.typingAttributes = [
            .foregroundColor: textColor,
            .font: font
        ]

        guard let storage = textView.textStorage, storage.length > 0 else { return }

        storage.addAttributes(
            [
                .foregroundColor: textColor,
                .font: font
            ],
            range: NSRange(location: 0, length: storage.length)
        )
    }
}

// MARK: - Custom text view

final class CustomTextView: NSTextView {

    var onSend: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        ChatInputStyle.apply(to: self)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 {
            if event.modifierFlags.contains(.shift) {
                super.keyDown(with: event)
                return
            }

            onSend?()
            return
        }

        super.keyDown(with: event)
    }
}

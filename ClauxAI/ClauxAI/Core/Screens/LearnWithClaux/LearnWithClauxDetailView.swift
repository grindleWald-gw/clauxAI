//
//  LearnWithClauxDetailView.swift
//  CL.AI
//
//  Created by Yasir Shah on 21/06/2026.
//

import AppKit
import SwiftUI

struct SharingAnchorView: NSViewRepresentable {
    @Binding var anchor: NSView?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { anchor = view }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { anchor = nsView }
    }
}

enum SharingPresenter {
    static func show(
        items: [Any],
        relativeTo anchor: NSView?,
        preferredEdge: NSRectEdge = .maxY
    ) {
        let picker = NSSharingServicePicker(items: items)

        if let anchor {
            picker.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: preferredEdge)
            return
        }

        if let contentView = NSApp.keyWindow?.contentView {
            picker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: preferredEdge)
        }
    }
}


struct LearnWithClauxDetailView: View {

    let course: LearnCourse
    var onBack: () -> Void = {}

    @State private var selectedTabID: String
    @State private var shareAnchorView: NSView?

    init(course: LearnCourse, onBack: @escaping () -> Void = {}) {
        self.course = course
        self.onBack = onBack
        _selectedTabID = State(initialValue: course.detail.tabs.first?.id ?? "")
    }

    private var selectedTab: LearnCourseTab? {
        course.detail.tabs.first { $0.id == selectedTabID }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            tabBar
                .padding(.horizontal, 32)
                .padding(.top, 20)

            contentPanel
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appMainbg)
    }
}

// MARK: - Header

private extension LearnWithClauxDetailView {

    var header: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textWhite)
                    .frame(width: 38, height: 38)
                    .background(Color(hex: "#1C1C1C"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.appStroke, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            Text(course.title)
                .font(.sfProDisplaySemiBold(20))
                .foregroundStyle(Color.textWhite)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, minHeight: 66, maxHeight: 66, alignment: .leading)
        .background(
            Color.appSecondarybg
                .ignoresSafeArea(edges: .top)
        )
    }
}

// MARK: - Tabs

private extension LearnWithClauxDetailView {

    var tabBar: some View {
        HStack(spacing: 12) {
            ForEach(course.detail.tabs) { tab in
                Button {
                    selectedTabID = tab.id
                } label: {
                    Text(tab.title)
                        .font(.sfProDisplayMedium(14))
                        .foregroundStyle(Color.textWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color(hex: "#1C1C1C"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    selectedTabID == tab.id ? Color.textWhite : Color.clear,
                                    lineWidth: 1
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Content

private extension LearnWithClauxDetailView {

    var contentPanel: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let tab = selectedTab {
                        ForEach(tab.sections) { section in
                            sectionView(section)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .padding(.bottom, 56)
            }

            HStack(spacing: 10) {
                actionButton(title: "Copy", systemImage: "doc.on.doc") {
                    copyContent()
                }

                shareButton
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#1E1E1E"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    func sectionView(_ section: LearnContentSection) -> some View {
        switch section.kind {
        case .heading:
            VStack(alignment: .leading, spacing: 8) {
                if let title = section.title {
                    Text(title)
                        .font(.sfProDisplaySemiBold(16))
                        .foregroundStyle(Color.textWhite)
                }

                if let text = section.text {
                    Text(text)
                        .font(.sfProDisplayRegular(15))
                        .foregroundStyle(Color.textWhite)
                        .lineSpacing(4)
                }

                if let items = section.items {
                    bulletList(items)
                }
            }

        case .paragraph:
            if let text = section.text {
                Text(text)
                    .font(.sfProDisplayRegular(15))
                    .foregroundStyle(Color.textWhite)
                    .lineSpacing(4)
            }

        case .bulletList:
            if let items = section.items {
                bulletList(items)
            }
        }
    }

    func bulletList(_ items: [LearnBulletItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.sfProDisplayRegular(15))
                        .foregroundStyle(Color.textWhite)

                    (
                        Text(item.term)
                            .font(.sfProDisplaySemiBold(15))
                            .foregroundStyle(Color.textWhite)
                        + Text(" — \(item.definition)")
                            .font(.sfProDisplayRegular(15))
                            .foregroundStyle(Color.textWhite)
                    )
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    var shareButton: some View {
        Button(action: shareContent) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.tetxGray)

                Text("Share")
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
        .overlay {
            SharingAnchorView(anchor: $shareAnchorView)
                .allowsHitTesting(false)
        }
    }

    func actionButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
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

    func copyContent() {
        guard let text = selectedTabContent() else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    func shareContent() {
        guard let text = selectedTabContent() else { return }

        SharingPresenter.show(
            items: [text],
            relativeTo: shareAnchorView,
            preferredEdge: .maxY
        )
    }

    func selectedTabContent() -> String? {
        guard let tab = selectedTab else { return nil }

        return tab.sections
            .map { section in
                var parts: [String] = []
                if let title = section.title { parts.append(title) }
                if let text = section.text { parts.append(text) }
                if let items = section.items {
                    parts.append(
                        items.map { "• \($0.term) — \($0.definition)" }.joined(separator: "\n")
                    )
                }
                return parts.joined(separator: "\n")
            }
            .joined(separator: "\n\n")
    }
}

#Preview {
    LearnWithClauxDetailView(
        course: LearnWithClauxData.courses.first { $0.id == "python" }!
    )
    .frame(width: 900, height: 780)
}

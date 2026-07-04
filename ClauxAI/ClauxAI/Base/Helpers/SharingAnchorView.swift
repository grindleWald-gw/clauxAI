//
//  SharingAnchorView.swift
//  ClauxAI
//
//  Created by Yasir Shah on 04/07/2026.
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

//
//  Constants.swift
//  ClauxAI
//
//  Created by Yasir Shah on 18/05/2026.
//

import SwiftUI
import AppKit

func printAllFonts() {

    for family in NSFontManager.shared.availableFontFamilies.sorted() {

        print("======== \(family) ========")

        let members = NSFontManager.shared.availableMembers(ofFontFamily: family) ?? []

        for member in members {

            if let fontName = member.first as? String {
                print(fontName)
            }
        }

        print("\n")
    }
}

//
//  Constants.swift
//  CL.AI
//
//  Created by Yasir Shah on 18/05/2026.
//

import SwiftUI
import AppKit


struct Constants {
    static let privacyPolicy = "https://sites.google.com/view/nexaapps/privacy-policy"
    static let termsOfUse = "https://sites.google.com/view/nexaapps/terms-of-use"
    static let contantUS = "nasiryahya68@gmail.com"
    static let appID = "6785600074"
    static let appSecret = "5cb1ebacccd9437aa0b40e31b4e22a83"
}

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

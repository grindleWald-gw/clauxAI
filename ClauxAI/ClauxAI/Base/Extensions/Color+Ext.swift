//
//  Color+Ext.swift
//  ClauxAI
//
//  Created by Yasir Shah on 18/05/2026.
//

import Foundation
import SwiftUI


extension Color {

    static let appWhite  = Color(hex: "#FFFFFF")
    static let textWhite = Color(hex: "#FFFFFF")

    static let appBlack  = Color(hex: "#000000")
    static let textBlack = Color(hex: "#000000")
    
    static let appOrange = Color(hex: "#E37D2F")
    static let tetxGray = Color(hex: "#A1A1A1")
    
    static let appStroke = Color(hex: "#3D3D3D")
    static let appMainbg = Color(hex: "#161616")
    static let appSecondarybg = Color(hex: "#232323")
}

extension Color {

    init(hex: String) {

        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64

        switch hex.count {

        case 3:
            // RGB (12-bit)
            (a, r, g, b) = (
                255,
                (int >> 8) * 17,
                (int >> 4 & 0xF) * 17,
                (int & 0xF) * 17
            )

        case 6:
            // RGB (24-bit)
            (a, r, g, b) = (
                255,
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF
            )

        case 8:
            // ARGB (32-bit)
            (a, r, g, b) = (
                int >> 24,
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )

        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

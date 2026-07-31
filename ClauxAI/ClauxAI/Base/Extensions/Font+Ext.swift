//
//  Font+Ext.swift
//  CL.AI
//
//  Created by Yasir Shah on 18/05/2026.
//

import Foundation

import SwiftUI

extension Font {

    static func sfProDisplayRegular(_ size: CGFloat) -> Font {
        .custom("SFProDisplay-Regular", size: size)
    }

    static func sfProDisplayMedium(_ size: CGFloat) -> Font {
        .custom("SFProDisplay-Medium", size: size)
    }

    static func sfProDisplaySemiBold(_ size: CGFloat) -> Font {
        .custom("SFProDisplay-Semibold", size: size)
    }

    static func sfProDisplayBold(_ size: CGFloat) -> Font {
        .custom("SFProDisplay-Bold", size: size)
    }

    static func sfProDisplayHeavy(_ size: CGFloat) -> Font {
        .custom("SFProDisplay-Heavy", size: size)
    }

}



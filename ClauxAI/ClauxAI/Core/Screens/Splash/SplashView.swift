//
//  SplashView.swift
//  CL.AI
//
//  Created by Yasir Shah on 04/07/2026.
//

import SwiftUI

struct AppLaunchView: View {

    @State private var isActive = false

    private enum Timing {
        static let minimumDisplay: Duration = .seconds(2)
        static let transition: Double = 0.45
    }

    var body: some View {
        Group {
            if isActive {
                RootView()
                    .frame(minWidth: 1150, minHeight: 790)
            } else {
                SplashView()
                    .frame(minWidth: 1150, minHeight: 790)
            }
        }
        .animation(.easeInOut(duration: Timing.transition), value: isActive)
        .task {
            async let keysLoaded: Void = DatabaseManager.shared.loadAPIKeys()
            async let minimumDelay: Void = {
                try? await Task.sleep(for: Timing.minimumDisplay)
            }()

            _ = await (keysLoaded, minimumDelay)
            APIConfiguration.bootstrap()
            isActive = true
        }
    }
}

struct SplashView: View {

    var body: some View {
        ZStack {
            Color.appMainbg.ignoresSafeArea()

            VStack(spacing: 18) {
                Image(.iconSplash)
                    .resizable()
                    .frame(width: 150, height: 150)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Splash") {
    SplashView()
        .frame(width: 1150, height: 790)
}

#Preview("Launch Flow") {
    AppLaunchView()
        .frame(width: 1150, height: 790)
}

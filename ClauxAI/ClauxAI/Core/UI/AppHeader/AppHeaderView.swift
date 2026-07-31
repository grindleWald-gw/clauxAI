//
//  AppHeaderView.swift
//  CL.AI
//
//  Created by Yasir Shah on 30/05/2026.
//

import SwiftUI

struct AppHeaderView: View {
    let text: String
    var showsNewChatButton: Bool = false
    var onNewChat: (() -> Void)? = nil
    let onSettings: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(text)
                .foregroundStyle(Color.textWhite)
                .font(.sfProDisplaySemiBold(20))

            Spacer(minLength: 12)

            if showsNewChatButton, let onNewChat {
                NewChatHeaderButton(action: onNewChat)
            }

            Button(action: onSettings) {
                Image(.settingIcon)
                    .resizable()
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
        .background(Color.appSecondarybg)
    }
}

struct NewChatHeaderButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .medium))

                Text("New Chat")
                    .font(.sfProDisplayMedium(14))
            }
            .foregroundStyle(Color.textWhite)
            .padding(.horizontal, 16)
            .frame(height: 38)
            .background(Color.black)
            .overlay(
                Capsule()
                    .stroke(Color.textWhite, lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AppHeaderView(
        text: "CL.AI / Home",
        showsNewChatButton: true,
        onNewChat: {},
        onSettings: {}
    )
}

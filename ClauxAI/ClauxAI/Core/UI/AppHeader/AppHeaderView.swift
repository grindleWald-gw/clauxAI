//
//  AppHeaderView.swift
//  ClauxAI
//
//  Created by Yasir Shah on 30/05/2026.
//

import SwiftUI

struct AppHeaderView: View {
    let text: String
    let action : () -> Void
    
    var body: some View {
        HStack(alignment: .center){
            Text(text)
                .foregroundStyle(Color.textWhite)
                .font(.sfProDisplaySemiBold(20))
            Spacer()
            
            Button {
                action()
            } label: {
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

#Preview {
    AppHeaderView(text: "Claux AI", action: {})
}

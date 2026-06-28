//
//  SidebarView.swift
//  ClauxAI
//
//  Created by Yasir Shah on 18/05/2026.
//

import SwiftUI

struct SidebarView: View {

    @Binding var selectedItem: SidebarDestination
    var onSelect: ((SidebarDestination) -> Void)? = nil

    var body: some View {

        VStack(alignment: .leading) {

            AppBrandView
              

             navigationMenu
                .padding(.top, 24)

            Spacer()

            UpgradeCard()
        }
        .frame(width: 240)
        .padding(24)
        .background(Color.appSecondarybg)
    }

}


//MARK: - AppBrand View
extension SidebarView {
    var AppBrandView: some View {
        HStack(alignment: .center) {
            Image(.sidebarIcon)
                .resizable()
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading){
                Text("Claux AI")
                    .font(.sfProDisplayBold(20))
                    .foregroundStyle(Color.textWhite)
                
                Text("Creative Writing studio.")
                    .font(.sfProDisplayRegular(14))
                    .foregroundStyle(Color.tetxGray)
            }
        }
    }
}

//MARK: - SideBar Navigation View
extension SidebarView {

    var navigationMenu: some View {

        VStack(alignment : .leading,spacing: 12) {
            
            Text("Developer Studio")
                .font(.sfProDisplayMedium(12))
                .foregroundStyle(Color.tetxGray)

            ForEach(SidebarDestination.allCases) { item in

                SidebarItem(
                    title: item.title,
                    icon: item.icon,
                    isSelected: selectedItem == item
                )
                .onTapGesture {
                    selectedItem = item
                    onSelect?(item)
                }
                .contentShape(Rectangle())
            }
        }
    }
}

//MARK: - SidebarItem
struct SidebarItem: View {

    let title: String
    let icon: String
    let isSelected: Bool

    var body: some View {

        HStack(spacing: 14) {

            Image( icon)
                .resizable()
                .frame(width: 24 ,height: 24)

            Text(title)
                .font(.sfProDisplayMedium(16))
            Spacer()
        }
        .padding()
        .background(
            isSelected ? Color.white : Color.clear
        )
        .foregroundStyle(
            isSelected ? .black : .white
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

//MARK: - Upgrade card view


struct UpgradeCard: View {

    var body: some View {

        VStack(alignment: .leading, spacing: 10) {

            // MARK: - Icon
            Image(.coinIcon)
                .resizable()
                .frame(width: 47, height: 47)
            

            // MARK: - Text
            VStack(alignment: .leading, spacing: 8) {

                Text("Free Plan")
                    .font(.sfProDisplaySemiBold(20))
                    .foregroundStyle(Color.textWhite)

                Text("Get full access now.")
                    .font(.sfProDisplayRegular(16))
                    .foregroundStyle(Color.textWhite)
            }

            // MARK: - Button
            Button {

            } label: {

                Text("Upgrade to PRO")
                    .font(.sfProDisplayMedium(18))
                    .foregroundStyle(Color.textWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hex: "#2F80FF"),
                                Color(hex: "#11C5FF")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            .buttonStyle(.plain)
        }
        .padding(28)
        .frame(width: 196,height: 184)
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 34)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: "#1E90FF"),
                            Color(hex: "#00BFFF")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 34))
    }
}


#Preview {
    SidebarView(selectedItem: .constant(.home))
}

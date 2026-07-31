//
//  SidebarView.swift
//  CL.AI
//
//  Created by Yasir Shah on 18/05/2026.
//

import SwiftUI

struct SidebarView: View {

    @Binding var selectedItem: SidebarDestination
    var onSelect: ((SidebarDestination) -> Void)? = nil
    var onUpgrade: (() -> Void)? = nil

    @State private var purchaseManager = PurchaseManager.shared

    var body: some View {

        VStack(alignment: .leading) {

            AppBrandView


             navigationMenu
                .padding(.top, 24)

            Spacer()

            if !purchaseManager.hasActiveSubscription {
                UpgradeCard(onUpgrade: onUpgrade)
                    .frame(maxWidth: .infinity)
                    .frame(height: 184)
            }
        }
        .frame(width: 240)
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
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
                Text("CL.AI Chatbot")
                    .font(.sfProDisplayBold(20))
                    .foregroundStyle(Color.textWhite)
                
                Text("AI Developers Workspace")
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
                ) {
                    selectedItem = item
                    onSelect?(item)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

//MARK: - SidebarItem
struct SidebarItem: View {

    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {

        Button(action: action) {
            HStack(spacing: 14) {

                Image(icon)
                    .resizable()
                    .frame(width: 24 ,height: 24)

                Text(title)
                    .font(.sfProDisplayMedium(16))

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? Color.white : Color.clear
            )
            .foregroundStyle(
                isSelected ? .black : .white
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

//MARK: - Upgrade card view


struct UpgradeCard: View {

    var onUpgrade: (() -> Void)? = nil

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
                onUpgrade?()
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
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 184, maxHeight: 184, alignment: .topLeading)
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

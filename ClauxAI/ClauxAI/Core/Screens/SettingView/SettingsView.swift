//
//  SettingsView.swift
//  ClauxAI
//
//  Created by Yasir Shah on 04/07/2026.
//

import AppKit
import SwiftUI

private enum SettingsColors {
    static let background = Color(hex: "#121212")
    static let listBackground = Color(hex: "#1C1C1C")
    static let iconBackground = Color(hex: "#2B2B2B")
    static let divider = Color(hex: "#2A2A2A")
}

private enum SettingsItem: CaseIterable, Identifiable {
    case upgradeToPro
    case restorePurchase
    case rateUs
    case shareApp
    case support
    case privacyPolicy
    case termsOfUse

    var id: Self { self }

    var title: String {
        switch self {
        case .upgradeToPro: return "Upgrade to pro"
        case .restorePurchase: return "Restore purchase"
        case .rateUs: return "Rate us"
        case .shareApp: return "Share app"
        case .support: return "Support"
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfUse: return "Terms of use"
        }
    }

    var icon: String {
        switch self {
        case .upgradeToPro: return "crown"
        case .restorePurchase: return "arrow.clockwise"
        case .rateUs: return "star"
        case .shareApp: return "square.and.arrow.up"
        case .support: return "phone.badge.checkmark"
        case .privacyPolicy: return "doc.text"
        case .termsOfUse: return "doc.text.fill"
        }
    }
}

struct SettingsView: View {

    var onUpgrade: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @State private var purchaseManager = PurchaseManager.shared
    @State private var alertMessage: String?

    private var visibleItems: [SettingsItem] {
        SettingsItem.allCases.filter { item in
            guard purchaseManager.hasActiveSubscription else { return true }
            return item != .upgradeToPro && item != .restorePurchase
        }
    }

    var body: some View {
        ZStack {
            SettingsColors.background.ignoresSafeArea()

            VStack(spacing: 24) {
                header
                settingsList
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 32)
        }
        .frame(width: 610)
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .task {
            await purchaseManager.refreshPurchasedProducts()
        }
        .alert("Settings", isPresented: alertBinding) {
            Button("OK") {
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
    }
}

// MARK: - Header

private extension SettingsView {

    var header: some View {
        ZStack {
            Text("Settings")
                .font(.sfProDisplaySemiBold(20))
                .foregroundStyle(Color.textWhite)

            HStack {
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textWhite)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - List

private extension SettingsView {

    var settingsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                settingsRow(item)

                if index < visibleItems.count - 1 {
                    SettingsColors.divider
                        .frame(height: 1)
                        .padding(.leading, 72)
                }
            }
        }
        .background(SettingsColors.listBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    func settingsRow(_ item: SettingsItem) -> some View {
        Button {
            handleSelection(item)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(SettingsColors.iconBackground)
                        .frame(width: 40, height: 40)

                    settingsIcon(for: item)
                }

                Text(item.title)
                    .font(.sfProDisplayMedium(16))
                    .foregroundStyle(Color.textWhite)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func settingsIcon(for item: SettingsItem) -> some View {
        switch item {
        case .support:
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "phone")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.textWhite)

                Text("24")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Color.textWhite)
                    .padding(3)
                    .background(Circle().fill(SettingsColors.iconBackground))
                    .overlay(Circle().stroke(Color.textWhite.opacity(0.35), lineWidth: 1))
                    .offset(x: 8, y: 4)
            }
            .frame(width: 24, height: 24)
        case .termsOfUse:
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "doc")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.textWhite)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.textWhite)
                    .offset(x: 6, y: 4)
            }
            .frame(width: 24, height: 24)
        case .privacyPolicy:
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "doc")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.textWhite)

                Image(systemName: "seal.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.textWhite)
                    .offset(x: 6, y: 4)
            }
            .frame(width: 24, height: 24)
        default:
            Image(systemName: item.icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color.textWhite)
                .frame(width: 24, height: 24)
        }
    }
}

// MARK: - Actions

private extension SettingsView {

    func handleSelection(_ item: SettingsItem) {
        switch item {
        case .upgradeToPro:
            dismiss()
            onUpgrade()

        case .restorePurchase:
            Task {
                await restorePurchases()
            }

        case .rateUs:
            openExternalLink("https://apps.apple.com/app/id\(Constants.appID)?action=write-review")

        case .shareApp:
            shareApp()

        case .support:
            openExternalLink("mailto:\(Constants.contantUS)")

        case .privacyPolicy:
            openExternalLink(Constants.privacyPolicy)

        case .termsOfUse:
            openExternalLink(Constants.termsOfUse)
        }
    }

    func restorePurchases() async {
        do {
            try await purchaseManager.restorePurchases()
            if purchaseManager.hasActiveSubscription {
                alertMessage = "Your purchases were restored successfully."
            } else {
                alertMessage = "No previous purchases were found."
            }
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func shareApp() {
        let url = URL(string: "https://apps.apple.com/app/id\(Constants.appID)")!
        guard let contentView = NSApp.keyWindow?.contentView else { return }
        let picker = NSSharingServicePicker(items: [url])
        picker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
    }

    func openExternalLink(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    alertMessage = nil
                }
            }
        )
    }
}

#Preview {
    SettingsView()
}

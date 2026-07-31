//
//  PurchaseManager.swift
//  CL.AI
//
//  Created by Yasir Shah on 21/01/2026.
//

import Foundation
import StoreKit
import Observation

enum ProductsCore: String, CaseIterable, Identifiable {
    case weekly = "com.clauxaichat.subscription.weekly"
    case monthly = "com.clauxaichat.subscription.monthly"
    case yearly = "com.clauxaichat.subscription.yearly"
    case lifetime = "com.clauxaichat.subscription.lifetimeplan"

    var id: String { rawValue }

    var sortOrder: Int {
        switch self {
        case .weekly: 0
        case .monthly: 1
        case .yearly: 2
        case .lifetime: 3
        }
    }

    var title: String {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        case .lifetime: "Lifetime"
        }
    }

    var badge: String {
        switch self {
        case .weekly: "Basic"
        case .monthly: "Free Trail"
        case .yearly: "60% Off"
        case .lifetime: "Forever"
        }
    }
}

enum PurchaseError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Transaction verification failed."
        }
    }
}

@MainActor
@Observable
final class PurchaseManager {

    static let shared = PurchaseManager()

    // MARK: - Published State

    private(set) var products: [Product] = []

    private(set) var purchasedProductIDs: Set<String> = []

    var isLoading = false

    var purchaseInProgress = false

    var hasActiveSubscription: Bool {
   
      !purchasedProductIDs.isEmpty
    }

    // MARK: - Private
    private init() {

        listenForTransactions()

        Task {
            await initialize()
        }
    }
}

//MARK: - Initilization
extension PurchaseManager {

    func initialize() async {

        isLoading = true

        await loadProducts()

        await refreshPurchasedProducts()

        isLoading = false
    }
}

//MARK: - Products
extension PurchaseManager {

    private var productIDs: [String] {
        ProductsCore.allCases.map(\.rawValue)
    }

    func loadProducts() async {

        do {

            let storeProducts = try await Product.products(for: productIDs)

            products = storeProducts.sorted {
                productIDs.firstIndex(of: $0.id)! <
                productIDs.firstIndex(of: $1.id)!
            }

        } catch {
            print("Failed loading StoreKit products")
            print(error)
        }
    }
}

//MARK: - Purchase
extension PurchaseManager {

    func purchase(_ product: Product) async throws {

        purchaseInProgress = true
        defer { purchaseInProgress = false }

        let result = try await product.purchase()

        switch result {

        case .success(let verification):

            let transaction = try checkVerified(verification)

            await transaction.finish()

            await refreshPurchasedProducts()

        case .pending:

            print("Purchase pending approval.")

        case .userCancelled:

            return

        @unknown default:

            return
        }
    }
}

//MARK: - Restore
extension PurchaseManager {

    func restorePurchases() async throws {

        try await AppStore.sync()

        await refreshPurchasedProducts()
    }
}

//MARK: - Refresh Entitlements
extension PurchaseManager {

    func refreshPurchasedProducts() async {

        var purchased = Set<String>()

        for await result in Transaction.currentEntitlements {

            guard let transaction = try? checkVerified(result) else {
                continue
            }

            if transaction.revocationDate == nil {
                purchased.insert(transaction.productID)
            }
        }

        purchasedProductIDs = purchased
    }
}

//MARK: - Transaction listener
extension PurchaseManager {

    private func listenForTransactions() {

        Task.detached(priority: .background) {

            for await result in Transaction.updates {

                do {

                    let transaction = try await self.checkVerified(result)

                    await transaction.finish()

                    await MainActor.run {
                        Task {
                            await self.refreshPurchasedProducts()
                        }
                    }

                } catch {
                    print(error)
                }
            }
        }
    }
}

//MARK: - Verification
extension PurchaseManager {

    func checkVerified<T>(
        _ result: VerificationResult<T>
    ) throws -> T {

        switch result {

        case .verified(let value):
            return value

        case .unverified:
            throw PurchaseError.verificationFailed
        }
    }
}

//MARK: - Convenience Helpers
extension PurchaseManager {

    var weeklyProduct: Product? {
        products.first { $0.id == ProductsCore.weekly.rawValue }
    }

    var monthlyProduct: Product? {
        products.first { $0.id == ProductsCore.monthly.rawValue }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == ProductsCore.yearly.rawValue }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == ProductsCore.lifetime.rawValue }
    }

    func product(for plan: ProductsCore) -> Product? {
        products.first { $0.id == plan.rawValue }
    }

    var sortedPlans: [ProductsCore] {
        ProductsCore.allCases.sorted { $0.sortOrder < $1.sortOrder }
    }

    func displayPrice(for plan: ProductsCore) -> String {
        product(for: plan)?.displayPrice ?? "—"
    }

    func periodLabel(for product: Product?) -> String? {
        guard let unit = product?.subscription?.subscriptionPeriod.unit else {
            return nil
        }

        switch unit {
        case .day: return "/ Day"
        case .week: return "/ Week"
        case .month: return "/ month"
        case .year: return "/ year"
        @unknown default: return nil
        }
    }

    func secondaryPriceLine(for plan: ProductsCore) -> String? {
        switch plan {
        case .weekly, .monthly, .yearly:
            return nil
        case .lifetime:
            return "Pay once, enjoy for life!"
        }
    }

    func footerLabel(for plan: ProductsCore) -> String? {
        guard let weekly = weeklyProduct else { return nil }

        switch plan {
        case .monthly:
            let amount = weekly.price * Self.monthlyMultiplier
            return "\(amount.formatted(weekly.priceFormatStyle)) / month"
        case .yearly:
            let amount = weekly.price * Self.yearlyMultiplier
            return "\(amount.formatted(weekly.priceFormatStyle)) / year"
        default:
            return nil
        }
    }

    func hasFreeTrial(for product: Product?) -> Bool {
        guard let offer = product?.subscription?.introductoryOffer else { return false }
        return offer.paymentMode == .freeTrial
    }

    func trialSubtitle(for plan: ProductsCore) -> String {
        guard let product = product(for: plan) else {
            return "Loading plan details..."
        }

        if let intro = product.subscription?.introductoryOffer,
           intro.paymentMode == .freeTrial {
            let trialDuration = formattedPeriod(intro.period)
            let billingPrice = product.displayPrice
            let billingSuffix = billingPeriodLabel(for: plan)
            return "Try Free for \(trialDuration), then \(billingPrice)\(billingSuffix)"
        }

        if plan == .lifetime {
            return "One-time purchase for \(product.displayPrice)"
        }

        let billingPrice = product.displayPrice
        let billingSuffix = billingPeriodLabel(for: plan)
        return "Subscribe for \(billingPrice)\(billingSuffix)"
    }

    func billingPeriodLabel(for plan: ProductsCore) -> String {
        switch plan {
        case .weekly: return ""
        case .monthly: return "/ month"
        case .yearly: return "/ year"
        case .lifetime: return ""
        }
    }

    func continueButtonTitle(for plan: ProductsCore) -> String {
        guard let product = product(for: plan) else { return "Continue" }
        return hasFreeTrial(for: product) ? "Continue for Free" : "Continue"
    }

    func showFreeTrialBadge(for plan: ProductsCore) -> Bool {
        plan == .monthly && hasFreeTrial(for: product(for: plan))
    }

    private static let monthlyMultiplier = Decimal(string: "4.125")!
    private static let yearlyMultiplier = Decimal(52)

    private func formattedPeriod(_ period: Product.SubscriptionPeriod) -> String {
        let value = period.value
        switch period.unit {
        case .day:
            return value == 1 ? "1 Day" : "\(value) Days"
        case .week:
            return value == 1 ? "1 Week" : "\(value) Weeks"
        case .month:
            return value == 1 ? "1 Month" : "\(value) Months"
        case .year:
            return value == 1 ? "1 Year" : "\(value) Years"
        @unknown default:
            return "\(value) days"
        }
    }
}

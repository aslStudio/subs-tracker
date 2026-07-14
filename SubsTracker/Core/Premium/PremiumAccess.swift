import Foundation
import StoreKit

@MainActor
@Observable
final class PremiumAccess {
    static let freeSubscriptionLimit = 5
    static let freeCategoryLimit = 2
    static let productIDs = [
        "premium.month",
        "premium.3month",
        "premium.6month",
        "premium.year"
    ]

    var isPremium = false
    var products: [Product] = []
    var isLoadingProducts = false
    var isPurchasing = false
    var errorMessage: String?

    private var hasStarted = false
    private var transactionUpdatesTask: Task<Void, Never>?

    func start() async {
        guard !hasStarted else {
            return
        }

        hasStarted = true
        await refreshSubscriptionStatus()
        await loadProducts()
        observeTransactionUpdates()
    }

    func canCreateSubscription(currentCount: Int) -> Bool {
        isPremium || currentCount < Self.freeSubscriptionLimit
    }

    func canCreateCategory(currentCount: Int) -> Bool {
        isPremium || currentCount < Self.freeCategoryLimit
    }

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    func loadProducts() async {
        guard products.isEmpty else {
            return
        }

        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            products = try await Product.products(for: Self.productIDs)
        } catch {
            errorMessage = "Could not load plans. Please try again later."
        }
    }

    func purchase(productID: String) async {
        guard let product = product(for: productID) else {
            errorMessage = "This plan is unavailable. Please try again later."
            return
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                await transaction.finish()
                await refreshSubscriptionStatus()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "Could not complete the subscription. Please try again."
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshSubscriptionStatus()
        } catch {
            errorMessage = "Could not restore purchases. Please try again later."
        }
    }

    func refreshSubscriptionStatus() async {
        var hasActivePremium = false

        for await result in Transaction.currentEntitlements {
            guard
                let transaction = try? verified(result),
                Self.productIDs.contains(transaction.productID),
                transaction.revocationDate == nil
            else {
                continue
            }

            if let expirationDate = transaction.expirationDate {
                if expirationDate > .now {
                    hasActivePremium = true
                    break
                }
            } else {
                hasActivePremium = true
                break
            }
        }

        isPremium = hasActivePremium

        if !hasActivePremium {
            await SubscriptionReminderScheduler.cancelAllReminders()
        }
    }

    private func observeTransactionUpdates() {
        transactionUpdatesTask?.cancel()
        transactionUpdatesTask = Task {
            for await result in Transaction.updates {
                guard let transaction = try? self.verified(result) else {
                    continue
                }

                await transaction.finish()
                await self.refreshSubscriptionStatus()
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            value
        case .unverified:
            throw StoreKitError.failedVerification
        }
    }
}

private enum StoreKitError: Error {
    case failedVerification
}

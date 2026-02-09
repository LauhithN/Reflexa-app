import StoreKit
import SwiftUI

/// StoreKit 2 service for one-time IAP unlock.
/// Uses Transaction.currentEntitlements + UserDefaults backup.
@Observable
final class StoreService {
    static let shared = StoreService()

    private(set) var product: Product?
    private(set) var isLoading = false
    private(set) var purchaseError: String?

    @ObservationIgnored
    @AppStorage(Constants.hasPurchasedUnlockKey) private var hasPurchasedBackup = false

    var isUnlocked: Bool {
        hasPurchasedBackup
    }

    private var transactionListener: Task<Void, Never>?

    private init() {
        // Listen for transaction updates (e.g., ask-to-buy approval, restore)
        transactionListener = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    if transaction.productID == Constants.productID {
                        self?.hasPurchasedBackup = true
                    }
                    await transaction.finish()
                }
            }
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    /// Load the product from the App Store
    @MainActor
    func loadProduct() async {
        isLoading = true
        do {
            let products = try await Product.products(for: [Constants.productID])
            product = products.first
        } catch {
            purchaseError = "Failed to load product"
        }
        isLoading = false
    }

    /// Purchase the unlock
    @MainActor
    func purchase() async -> Bool {
        guard let product else {
            purchaseError = "Product not available"
            return false
        }

        isLoading = true
        purchaseError = nil

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    hasPurchasedBackup = true
                    await transaction.finish()
                    isLoading = false
                    return true
                }
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Purchase pending approval"
            @unknown default:
                break
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
        }

        isLoading = false
        return false
    }

    /// Restore purchases by checking current entitlements
    @MainActor
    func restorePurchases() async {
        isLoading = true
        purchaseError = nil

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Constants.productID {
                    hasPurchasedBackup = true
                    isLoading = false
                    return
                }
            }
        }

        purchaseError = "No purchases to restore"
        isLoading = false
    }

    /// Check entitlements on launch
    @MainActor
    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == Constants.productID {
                    hasPurchasedBackup = true
                    return
                }
            }
        }
    }
}

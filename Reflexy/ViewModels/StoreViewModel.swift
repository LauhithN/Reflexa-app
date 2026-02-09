import Foundation

/// ViewModel for the store/unlock paywall view
@Observable
final class StoreViewModel {
    private let store = StoreService.shared

    var isUnlocked: Bool { store.isUnlocked }
    var isLoading: Bool { store.isLoading }
    var errorMessage: String? { store.purchaseError }
    var priceString: String {
        store.product?.displayPrice ?? Constants.unlockPrice
    }

    func loadProduct() async {
        await store.loadProduct()
    }

    func purchase() async -> Bool {
        await store.purchase()
    }

    func restorePurchases() async {
        await store.restorePurchases()
    }
}

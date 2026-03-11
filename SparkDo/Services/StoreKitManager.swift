import StoreKit

@Observable
final class StoreKitManager {
    static let premiumProductID = "com.sparkdo.premium"

    private(set) var product: Product?
    private(set) var isPurchased = false
    private(set) var isLoading = false

    private var transactionListener: Task<Void, Error>?

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProduct()
            await checkPurchaseStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Product

    func loadProduct() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: [Self.premiumProductID])
            product = products.first
        } catch {
            // Product loading failed — will show unavailable state
        }
    }

    // MARK: - Purchase

    func purchase() async throws -> Bool {
        guard let product else { return false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            isPurchased = true
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    func restore() async {
        try? await AppStore.sync()
        await checkPurchaseStatus()
    }

    // MARK: - Check Status

    func checkPurchaseStatus() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.premiumProductID {
                isPurchased = true
                return
            }
        }
        isPurchased = false
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? self?.checkVerified(result),
                   transaction.productID == StoreKitManager.premiumProductID {
                    await MainActor.run {
                        self?.isPurchased = true
                    }
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.unverified
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case unverified
}

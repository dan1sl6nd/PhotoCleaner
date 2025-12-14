//
//  SubscriptionManager.swift
//  PhotoCleaner
//
//  Created by Dan Mukashev on 2025-12-12.
//

import Foundation
import Observation
import StoreKit

@Observable
@MainActor
class SubscriptionManager {
    var hasActiveSubscription: Bool = false
    var isProcessingPurchase: Bool = false
    var purchaseError: String?

    // Store products fetched from App Store Connect
    var products: [Product] = []
    var isLoadingProducts: Bool = false

    // For development/testing - simulate subscription
    var isDevelopmentMode: Bool = false

    // Transaction listener
    private var transactionListener: Task<Void, Error>?

    // MARK: - Initialization

    init() {
        // Start listening for transaction updates
        transactionListener = listenForTransactions()

        Task { @MainActor in
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task { @MainActor [weak self] in
            guard let self = self else { return }
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    // Handle the transaction update
                    await self.handleTransaction(transaction)
                }
            }
        }
    }

    private func handleTransaction(_ transaction: Transaction) async {
        // Update subscription status based on transaction
        if transaction.revocationDate == nil {
            hasActiveSubscription = true
            UserDefaults.standard.set(true, forKey: "hasActiveSubscription")
        }

        // Finish the transaction
        await transaction.finish()
    }

    // MARK: - Product Loading

    func loadProducts() async {
        isLoadingProducts = true

        do {
            // Fetch products from App Store Connect
            let productIdentifiers = SubscriptionPlan.allCases.map { $0.rawValue }
            let fetchedProducts = try await Product.products(for: productIdentifiers)

            // Sort products to match our plan order
            products = fetchedProducts.sorted { product1, product2 in
                if product1.id == SubscriptionPlan.weekly.rawValue {
                    return true
                } else if product2.id == SubscriptionPlan.weekly.rawValue {
                    return false
                } else {
                    return false
                }
            }

            isLoadingProducts = false
        } catch {
            print("Failed to load products: \(error)")
            isLoadingProducts = false
            // Products remain empty - app can handle this gracefully
        }
    }

    // MARK: - Product Helper

    func product(for plan: SubscriptionPlan) -> Product? {
        return products.first(where: { $0.id == plan.rawValue })
    }

    // MARK: - Subscription Status

    func checkSubscriptionStatus() async {
        // Check for active transactions
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    hasActiveSubscription = true
                    return
                }
            }
        }

        // Fallback to UserDefaults for development
        hasActiveSubscription = UserDefaults.standard.bool(forKey: "hasActiveSubscription") || isDevelopmentMode
    }

    // MARK: - Purchase

    func purchase(plan: SubscriptionPlan) async throws {
        isProcessingPurchase = true
        purchaseError = nil

        do {
            // Get the product for this plan
            guard let product = product(for: plan) else {
                throw SubscriptionError.productNotFound
            }

            // Purchase the product
            let result = try await product.purchase()

            // Handle the purchase result
            switch result {
            case .success(let verification):
                // Verify the transaction
                switch verification {
                case .verified(let transaction):
                    // Transaction is verified - grant access
                    hasActiveSubscription = true
                    UserDefaults.standard.set(true, forKey: "hasActiveSubscription")

                    // Finish the transaction
                    await transaction.finish()

                    isProcessingPurchase = false

                case .unverified(_, let error):
                    // Transaction failed verification
                    purchaseError = "Purchase verification failed"
                    isProcessingPurchase = false
                    throw error
                }

            case .userCancelled:
                // User cancelled the purchase
                isProcessingPurchase = false
                throw SubscriptionError.userCancelled

            case .pending:
                // Purchase is pending (e.g., parental approval)
                purchaseError = "Purchase is pending approval"
                isProcessingPurchase = false
                throw SubscriptionError.purchasePending

            @unknown default:
                isProcessingPurchase = false
                throw SubscriptionError.purchaseFailed
            }
        } catch {
            purchaseError = error.localizedDescription
            isProcessingPurchase = false
            throw error
        }
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        isProcessingPurchase = true
        purchaseError = nil

        do {
            // Sync with App Store
            try await AppStore.sync()

            // Check for active entitlements
            var foundSubscription = false

            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if transaction.revocationDate == nil {
                        foundSubscription = true
                        hasActiveSubscription = true
                        UserDefaults.standard.set(true, forKey: "hasActiveSubscription")
                        await transaction.finish()
                    }
                }
            }

            isProcessingPurchase = false

            if !foundSubscription {
                // Check UserDefaults fallback for development
                if UserDefaults.standard.bool(forKey: "hasActiveSubscription") {
                    hasActiveSubscription = true
                } else {
                    throw SubscriptionError.noPurchasesToRestore
                }
            }
        } catch {
            purchaseError = error.localizedDescription
            isProcessingPurchase = false
            throw error
        }
    }
}

enum SubscriptionError: LocalizedError {
    case noPurchasesToRestore
    case purchaseFailed
    case productNotFound
    case userCancelled
    case purchasePending

    var errorDescription: String? {
        switch self {
        case .noPurchasesToRestore:
            return "No previous purchases found"
        case .purchaseFailed:
            return "Purchase failed. Please try again."
        case .productNotFound:
            return "Product not available. Please try again later."
        case .userCancelled:
            return "Purchase cancelled"
        case .purchasePending:
            return "Purchase is pending approval"
        }
    }
}

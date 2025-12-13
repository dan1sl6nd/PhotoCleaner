//
//  SubscriptionPlan.swift
//  PhotoCleaner
//
//  Created by Dan Mukashev on 2025-12-12.
//

import Foundation
import SwiftUI
import StoreKit

enum SubscriptionPlan: String, CaseIterable {
    case weekly = "com.photocleaner.weekly"
    case yearly = "com.photocleaner.yearly"

    var displayName: String {
        switch self {
        case .weekly:
            return "Weekly"
        case .yearly:
            return "Yearly"
        }
    }

    var price: String {
        switch self {
        case .weekly:
            return "$4.99"
        case .yearly:
            return "$29.99"
        }
    }

    var priceValue: Double {
        switch self {
        case .weekly:
            return 4.99
        case .yearly:
            return 29.99
        }
    }

    var period: String {
        switch self {
        case .weekly:
            return "week"
        case .yearly:
            return "year"
        }
    }

    var hasTrial: Bool {
        switch self {
        case .weekly:
            return true
        case .yearly:
            return false
        }
    }

    var trialDuration: String {
        switch self {
        case .weekly:
            return "3 days"
        case .yearly:
            return ""
        }
    }

    var savings: String? {
        switch self {
        case .weekly:
            return nil
        case .yearly:
            // Weekly is $4.99, so yearly would be $259.48, saving $229.49
            let weeklyCost = 4.99 * 52
            let savings = weeklyCost - priceValue
            return "Save $\(Int(savings))"
        }
    }

    var badge: String? {
        switch self {
        case .weekly:
            return nil
        case .yearly:
            return "BEST VALUE"
        }
    }

    var gradient: [Color] {
        switch self {
        case .weekly:
            return [Color.purple, Color.blue]
        case .yearly:
            return [Color.orange, Color.pink]
        }
    }

    // MARK: - Dynamic Pricing Methods

    /// Get the formatted price from the StoreKit product
    func formattedPrice(from product: Product?) -> String {
        guard let product = product else {
            return price // Fallback to hardcoded price
        }
        return product.displayPrice
    }

    /// Get the subscription period from the StoreKit product
    func subscriptionPeriod(from product: Product?) -> String {
        guard let product = product,
              let subscription = product.subscription else {
            return period // Fallback to hardcoded period
        }

        let unit = subscription.subscriptionPeriod.unit
        switch unit {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        @unknown default:
            return period
        }
    }

    /// Get the trial period from the StoreKit product
    func trialPeriod(from product: Product?) -> String? {
        guard let product = product,
              let subscription = product.subscription,
              let introOffer = subscription.introductoryOffer else {
            return hasTrial ? trialDuration : nil
        }

        let period = introOffer.period
        let value = period.value
        let unit = period.unit

        switch unit {
        case .day:
            return "\(value) day\(value > 1 ? "s" : "")"
        case .week:
            return "\(value) week\(value > 1 ? "s" : "")"
        case .month:
            return "\(value) month\(value > 1 ? "s" : "")"
        case .year:
            return "\(value) year\(value > 1 ? "s" : "")"
        @unknown default:
            return hasTrial ? trialDuration : nil
        }
    }

    /// Check if product has a trial offer
    func hasTrialOffer(from product: Product?) -> Bool {
        guard let product = product,
              let subscription = product.subscription else {
            return hasTrial
        }
        return subscription.introductoryOffer != nil
    }

    /// Calculate savings for yearly plan
    func calculateSavings(weeklyProduct: Product?, yearlyProduct: Product?) -> String? {
        guard self == .yearly,
              let weeklyProduct = weeklyProduct,
              let yearlyProduct = yearlyProduct else {
            return savings
        }

        let weeklyCost = weeklyProduct.price
        let yearlyCost = yearlyProduct.price

        let annualWeeklyCost = weeklyCost * Decimal(52)
        let savingsAmount = annualWeeklyCost - yearlyCost

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearlyProduct.priceFormatStyle.locale

        if let formattedSavings = formatter.string(from: savingsAmount as NSDecimalNumber) {
            // Remove decimal if it's .00
            let cleaned = formattedSavings.replacingOccurrences(of: ".00", with: "")
            return "Save \(cleaned)"
        }

        return savings
    }
}

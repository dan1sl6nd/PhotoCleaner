//
//  FacebookAnalyticsService.swift
//  PhotoCleaner
//
//  Created by Dan Mukashev on 2025-12-14.
//

import Foundation
import FacebookCore
import AppTrackingTransparency
import UIKit

/// Service for tracking app events and conversions with Facebook Analytics
/// Uses Facebook SDK for client-side event tracking
@MainActor
class FacebookAnalyticsService {
    static let shared = FacebookAnalyticsService()

    private init() {}

    // MARK: - Advertiser Tracking (ATT)

    /// Keep Facebook SDK tracking flag in sync with ATT status.
    func configureAdvertiserTracking() {
        Settings.shared.isAdvertiserTrackingEnabled = ATTrackingManager.trackingAuthorizationStatus == .authorized
    }

    // MARK: - Configuration

    // MARK: - Private Helper Methods

    /// Track event using Facebook SDK
    private func trackEvent(
        eventName: AppEvents.Name,
        valueToSum: Double? = nil,
        parameters: [AppEvents.ParameterName: Any]? = nil
    ) {
        // Track with Facebook SDK
        if let valueToSum = valueToSum {
            AppEvents.shared.logEvent(eventName, valueToSum: valueToSum, parameters: parameters)
            #if DEBUG
            print("📊 Facebook Event: \(eventName.rawValue) (value: \(valueToSum))")
            #endif
        } else {
            AppEvents.shared.logEvent(eventName, parameters: parameters)
            #if DEBUG
            print("📊 Facebook Event: \(eventName.rawValue)")
            #endif
        }

        // Log parameters if present
        if let parameters = parameters, !parameters.isEmpty {
            #if DEBUG
            print("   Parameters: \(parameters.map { "\($0.key.rawValue): \($0.value)" }.joined(separator: ", "))")
            #endif
        }
    }

    // MARK: - App Lifecycle Events

    /// Call this when app becomes active
    func activateApp() {
        #if DEBUG
        print("📊 Facebook: App activated")
        #endif
        AppEvents.shared.activateApp()
    }

    // MARK: - App Tracking Transparency

    /// Request tracking permission
    /// Note: SDK v17+ automatically reads ATTrackingManager status
    func requestTrackingPermission(completion: ((Bool) -> Void)? = nil, retryCount: Int = 0) {
        // Limit retries to prevent poor UX (3 retries = 1.5 seconds max wait)
        let maxRetries = 3
        guard retryCount < maxRetries else {
            #if DEBUG
            print("⚠️ ATT permission request exceeded max retries, app may not be active")
            #endif
            completion?(false)
            return
        }

        // Check app state (already on main thread due to @MainActor)
        let appState = UIApplication.shared.applicationState
        guard appState == .active else {
            #if DEBUG
            print("⚠️ App not active (state: \(appState.rawValue)), retrying ATT request...")
            #endif
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.requestTrackingPermission(completion: completion, retryCount: retryCount + 1)
            }
            return
        }

        // Request permission
        ATTrackingManager.requestTrackingAuthorization { status in
            // ATTrackingManager completion is already on main thread
            let granted = status == .authorized
            Settings.shared.isAdvertiserTrackingEnabled = granted
            completion?(granted)
        }
    }

    // MARK: - Standard Events

    /// Track app install (first launch)
    func trackAppInstall() {
        trackEvent(eventName: .completedRegistration)
    }

    /// Track subscription purchase
    func trackPurchase(value: Double, currency: String = "USD", productId: String? = nil) {
        var parameters: [AppEvents.ParameterName: Any] = [
            .currency: currency
        ]
        if let productId = productId {
            parameters[.contentID] = productId
        }

        trackEvent(
            eventName: .purchased,
            valueToSum: value,
            parameters: parameters
        )
    }

    /// Track subscription start
    func trackSubscriptionStarted(value: Double, currency: String = "USD", tier: String) {
        trackEvent(
            eventName: .subscribe,
            valueToSum: value,
            parameters: [
                .currency: currency,
                .level: tier
            ]
        )
    }

    /// Track trial start
    func trackTrialStarted(value: Double, currency: String = "USD") {
        trackEvent(
            eventName: .startTrial,
            valueToSum: value,
            parameters: [.currency: currency]
        )
    }

    // MARK: - PhotoCleaner Specific Events

    /// Track onboarding completion
    func trackOnboardingCompleted(painPoints: [String]) {
        trackEvent(
            eventName: AppEvents.Name(rawValue: "OnboardingCompleted"),
            parameters: [
                AppEvents.ParameterName(rawValue: "pain_points"): painPoints.joined(separator: ","),
                AppEvents.ParameterName(rawValue: "pain_point_count"): painPoints.count
            ]
        )
    }

    /// Track paywall view
    func trackPaywallViewed() {
        trackEvent(eventName: AppEvents.Name(rawValue: "PaywallViewed"))
    }

    /// Track photo cleaning session started
    func trackCleaningSessionStarted(albumType: String, photoCount: Int) {
        trackEvent(
            eventName: AppEvents.Name(rawValue: "CleaningSessionStarted"),
            parameters: [
                AppEvents.ParameterName(rawValue: "album_type"): albumType,
                AppEvents.ParameterName(rawValue: "photo_count"): photoCount
            ]
        )
    }

    /// Track cleaning session completed
    func trackCleaningSessionCompleted(photosDeleted: Int, spaceFreed: Int64) {
        let spaceMB = Double(spaceFreed) / 1_048_576.0 // Convert to MB
        trackEvent(
            eventName: AppEvents.Name(rawValue: "CleaningSessionCompleted"),
            parameters: [
                AppEvents.ParameterName(rawValue: "photos_deleted"): photosDeleted,
                AppEvents.ParameterName(rawValue: "space_freed_mb"): String(format: "%.1f", spaceMB)
            ]
        )
    }

    // MARK: - Custom Events

    /// Track custom event with optional parameters
    func trackCustomEvent(_ eventName: String, parameters: [String: Any]? = nil) {
        // Convert string dict to AppEvents parameters
        var fbParameters: [AppEvents.ParameterName: Any]?
        if let parameters = parameters {
            fbParameters = [:]
            for (key, value) in parameters {
                let parameterName = AppEvents.ParameterName(rawValue: key)
                fbParameters?[parameterName] = value
            }
        }

        trackEvent(
            eventName: AppEvents.Name(rawValue: eventName),
            parameters: fbParameters
        )
    }
}

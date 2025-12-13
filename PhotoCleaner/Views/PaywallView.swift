//
//  PaywallView.swift
//  PhotoCleaner
//
//  Created by Dan Mukashev on 2025-12-12.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var opacity: Double = 0
    @State private var headerScale: Double = 0.8
    @State private var showRestoreAlert: Bool = false
    @State private var restoreSuccess: Bool = false

    let painPoints: Set<PainPoint>

    var body: some View {
        ZStack {
            // Dynamic background
            DynamicBackgroundView(colorScheme: .sunsetGlow)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 20) {
                        // Icon with animation
                        ZStack {
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [
                                                Color.orange.opacity(0.3 - Double(index) * 0.1),
                                                Color.clear
                                            ],
                                            center: .center,
                                            startRadius: 10,
                                            endRadius: CGFloat(80 + index * 30)
                                        )
                                    )
                                    .frame(width: CGFloat(140 + index * 30), height: CGFloat(140 + index * 30))
                                    .blur(radius: CGFloat(15 + index * 10))
                            }

                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 110, height: 110)
                                .shadow(color: Color.orange.opacity(0.6), radius: 25, y: 12)

                            Image(systemName: "sparkles")
                                .font(.system(size: 55, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(headerScale)

                        VStack(spacing: 12) {
                            Text("Unlock Full Access")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(getPersonalizedMessage())
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 32)
                        }
                    }
                    .padding(.top, 60)

                    // Benefits
                    VStack(spacing: 16) {
                        BenefitRow(icon: "infinity", title: "Unlimited photo cleaning", color: .cyan)
                        BenefitRow(icon: "sparkles", title: "Smart categorization", color: .purple)
                        BenefitRow(icon: "chart.bar.fill", title: "Track space saved", color: .green)
                        BenefitRow(icon: "arrow.clockwise", title: "Review skipped photos", color: .orange)
                        BenefitRow(icon: "folder.fill", title: "Clean by album or category", color: .pink)
                    }
                    .padding(.horizontal, 32)

                    // Subscription plans
                    VStack(spacing: 16) {
                        ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                            SubscriptionPlanCard(
                                plan: plan,
                                isSelected: selectedPlan == plan,
                                subscriptionManager: subscriptionManager
                            ) {
                                selectPlan(plan)
                            }
                        }
                    }
                    .padding(.horizontal, 32)

                    // Subscribe button
                    Button(action: {
                        subscribe()
                    }) {
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                if subscriptionManager.isProcessingPurchase {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "lock.open.fill")
                                        .font(.system(size: 22, weight: .bold))
                                    Text(getSubscribeButtonText())
                                        .font(.system(size: 20, weight: .bold))
                                }
                            }

                            if selectedPlan.hasTrialOffer(from: subscriptionManager.product(for: selectedPlan)) {
                                let product = subscriptionManager.product(for: selectedPlan)
                                Text("Then \(selectedPlan.formattedPrice(from: product))/\(selectedPlan.subscriptionPeriod(from: product))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(
                                    LinearGradient(
                                        colors: selectedPlan.gradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: selectedPlan.gradient[0].opacity(0.6), radius: 25, y: 12)
                        )
                    }
                    .disabled(subscriptionManager.isProcessingPurchase)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)

                    // Restore purchases button
                    Button(action: {
                        restorePurchases()
                    }) {
                        Text("Restore Purchases")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .disabled(subscriptionManager.isProcessingPurchase)

                    // Legal text
                    VStack(spacing: 8) {
                        if selectedPlan.hasTrialOffer(from: subscriptionManager.product(for: selectedPlan)) {
                            let product = subscriptionManager.product(for: selectedPlan)
                            if let trial = selectedPlan.trialPeriod(from: product) {
                                Text("Free for \(trial), then \(selectedPlan.formattedPrice(from: product))/\(selectedPlan.subscriptionPeriod(from: product))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        Text("Auto-renewable. Cancel anytime in Settings.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 16) {
                            Button("Terms of Use") {
                                if let url = URL(string: "https://dan1sl6nd.github.io/PhotoCleaner/terms-of-use.html") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            Text("•")
                            Button("Privacy Policy") {
                                if let url = URL(string: "https://dan1sl6nd.github.io/PhotoCleaner/privacy-policy.html") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                headerScale = 1.0
            }
        }
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreSuccess ? "Purchases restored successfully!" : "No previous purchases found.")
        }
    }

    // MARK: - Methods

    private func getPersonalizedMessage() -> String {
        if painPoints.contains(.storage) {
            return "Free up gigabytes of storage space with smart cleaning"
        } else if painPoints.contains(.screenshots) {
            return "Quickly clean up screenshots and reclaim your space"
        } else if painPoints.contains(.videos) {
            return "Remove large video files and free up storage"
        } else if painPoints.contains(.organization) {
            return "Organize your library and keep only the best"
        } else {
            return "Clean your photo library faster than ever"
        }
    }

    private func getSubscribeButtonText() -> String {
        let product = subscriptionManager.product(for: selectedPlan)

        if selectedPlan.hasTrialOffer(from: product) {
            if let trial = selectedPlan.trialPeriod(from: product) {
                return "Start \(trial) Free Trial"
            } else {
                return "Start Free Trial"
            }
        } else {
            return "Subscribe for \(selectedPlan.formattedPrice(from: product))/\(selectedPlan.subscriptionPeriod(from: product))"
        }
    }

    private func selectPlan(_ plan: SubscriptionPlan) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedPlan = plan
        }
    }

    private func subscribe() {
        Task {
            do {
                try await subscriptionManager.purchase(plan: selectedPlan)
                // Purchase successful - subscription manager state updated
                // MainCoordinatorView will automatically transition to next screen
            } catch {
                // Error is already set in subscriptionManager.purchaseError
            }
        }
    }

    private func restorePurchases() {
        Task {
            do {
                try await subscriptionManager.restorePurchases()
                restoreSuccess = true
                showRestoreAlert = true
                // Subscription restored - MainCoordinatorView will automatically transition
            } catch {
                restoreSuccess = false
                showRestoreAlert = true
            }
        }
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.green)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Subscription Plan Card

struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let subscriptionManager: SubscriptionManager
    let action: () -> Void

    private var product: Product? {
        subscriptionManager.product(for: plan)
    }

    private var weeklyProduct: Product? {
        subscriptionManager.product(for: .weekly)
    }

    private var yearlyProduct: Product? {
        subscriptionManager.product(for: .yearly)
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .top) {
                // Main card content
                HStack(alignment: .center, spacing: 16) {
                    // Radio button
                    ZStack {
                        Circle()
                            .stroke(
                                isSelected
                                    ? LinearGradient(
                                        colors: plan.gradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)

                        if isSelected {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: plan.gradient,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 18, height: 18)
                        }
                    }

                    // Plan details
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(plan.displayName)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)

                            if let savings = plan.calculateSavings(weeklyProduct: weeklyProduct, yearlyProduct: yearlyProduct) {
                                Text(savings)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.green.opacity(0.2))
                                    )
                            }
                        }

                        if plan.hasTrialOffer(from: product) {
                            if let trial = plan.trialPeriod(from: product) {
                                Text("\(trial) free, then \(plan.formattedPrice(from: product))/\(plan.subscriptionPeriod(from: product))")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            } else {
                                Text("\(plan.formattedPrice(from: product))/\(plan.subscriptionPeriod(from: product))")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        } else {
                            Text("\(plan.formattedPrice(from: product))/\(plan.subscriptionPeriod(from: product))")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.top, plan.badge != nil ? 8 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            isSelected
                                ? LinearGradient(
                                    colors: plan.gradient.map { $0.opacity(0.25) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    isSelected
                                        ? LinearGradient(
                                            colors: plan.gradient,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                        : LinearGradient(
                                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                        .shadow(
                            color: isSelected ? plan.gradient[0].opacity(0.3) : .clear,
                            radius: 20,
                            y: 10
                        )
                )

                // Badge positioned at top
                if let badge = plan.badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .offset(y: -10)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    PaywallView(painPoints: [.storage, .screenshots])
}

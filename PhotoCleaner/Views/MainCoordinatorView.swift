//
//  MainCoordinatorView.swift
//  PhotoCleaner
//
//  Created by Dan Mukashev on 2025-12-09.
//

import SwiftUI

struct MainCoordinatorView: View {
    @Environment(PermissionViewModel.self) private var permissionVM
    @Environment(PhotoCleanerViewModel.self) private var cleanerVM
    @Environment(AppStateViewModel.self) private var appStateVM
    @Environment(SubscriptionManager.self) private var subscriptionManager

    var body: some View {
        Group {
            if !appStateVM.hasCompletedOnboarding {
                // Show onboarding
                OnboardingView { painPoints in
                    appStateVM.completeOnboarding(with: painPoints)
                }
            } else if !subscriptionManager.hasActiveSubscription {
                // Show paywall (hard paywall - must subscribe to continue)
                PaywallView(painPoints: appStateVM.identifiedPainPoints)
            } else if !permissionVM.isAuthorized {
                // Show permission request view
                PermissionView()
            } else if cleanerVM.selectedAlbum == nil {
                // Show home or album selection
                if cleanerVM.showAlbumSelection {
                    AlbumSelectionView()
                } else {
                    HomeView()
                }
            } else if cleanerVM.isLoading {
                // Loading photos
                LoadingView()
            } else if cleanerVM.photos.isEmpty {
                // No photos in selected album - check before isSessionComplete
                ZStack {
                    DynamicBackgroundView(colorScheme: .darkEnhanced)

                    VStack(spacing: 0) {
                        Spacer()

                        // Animated icon
                        ZStack {
                            // Glow effect
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.purple.opacity(0.3),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 200, height: 200)
                                .blur(radius: 20)

                            // Icon background
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.purple.opacity(0.3),
                                            Color.blue.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)

                            // Icon
                            Image(systemName: "photo.stack")
                                .font(.system(size: 50, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.bottom, 32)

                        // Title
                        Text("No Photos Found")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.bottom, 12)

                        // Description
                        Text("Add some photos to your library\nto start cleaning")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 48)

                        // Go back button
                        Button(action: {
                            cleanerVM.resetSession()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Go Back")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.purple, Color.blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Color.purple.opacity(0.5), radius: 20, y: 10)
                            )
                        }
                        .padding(.horizontal, 32)

                        Spacer()
                        Spacer()
                    }
                }
            } else if cleanerVM.isSessionComplete {
                // Session complete - show summary (only when there were photos)
                SummaryView()
            } else {
                // Show photo swipe interface
                PhotoSwipeView()
            }
        }
        .task {
            permissionVM.checkPermissionStatus()
            await subscriptionManager.checkSubscriptionStatus()
        }
    }
}

struct LoadingView: View {
    @State private var rotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var dotOpacity: [Double] = [0.3, 0.3, 0.3]

    var body: some View {
        ZStack {
            // Dynamic background
            DynamicBackgroundView(colorScheme: .darkEnhanced)

            VStack(spacing: 32) {
                // Animated loading icon
                ZStack {
                    // Outer rotating ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.5, green: 0.65, blue: 0.85).opacity(0.8),
                                    Color(red: 0.4, green: 0.5, blue: 0.75).opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(rotation))

                    // Inner glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.5, blue: 0.7).opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 60
                            )
                        )
                        .frame(width: 100, height: 100)
                        .blur(radius: 15)
                        .scaleEffect(pulseScale)

                    // Center icon
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.7, green: 0.8, blue: 0.95),
                                    Color(red: 0.5, green: 0.65, blue: 0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 0.5, green: 0.65, blue: 0.85).opacity(0.5), radius: 10)
                }

                // Loading text with animated dots
                HStack(spacing: 4) {
                    Text("Loading photos")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.85, green: 0.88, blue: 0.95))

                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color(red: 0.7, green: 0.8, blue: 0.95))
                                .frame(width: 6, height: 6)
                                .opacity(dotOpacity[index])
                        }
                    }
                }
            }
        }
        .onAppear {
            // Rotation animation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }

            // Pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }

            // Dot animations with sequential delays
            for index in 0..<3 {
                withAnimation(
                    .easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.2)
                ) {
                    dotOpacity[index] = 1.0
                }
            }
        }
    }
}

#Preview {
    MainCoordinatorView()
        .environment(PermissionViewModel())
        .environment(PhotoCleanerViewModel(
            photoService: PhotoLibraryService(),
            deletionService: PhotoDeletionService()
        ))
        .environment(AppStateViewModel())
        .environment(SubscriptionManager())
}

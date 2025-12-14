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
            } else if cleanerVM.isSessionComplete {
                // Session complete - show summary
                SummaryView()
            } else if cleanerVM.photos.isEmpty {
                // No photos in selected album
                ZStack {
                    DynamicBackgroundView(colorScheme: .darkEnhanced)
                    ContentUnavailableView(
                        "No Photos",
                        systemImage: "photo.on.rectangle.angled",
                        description: Text("This album doesn't contain any photos to review")
                    )
                }
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

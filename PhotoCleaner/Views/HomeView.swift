//
//  HomeView.swift
//  PhotoCleaner
//
//  Created by Dan Mukashev on 2025-12-11.
//

import SwiftUI

struct HomeView: View {
    @Environment(PhotoCleanerViewModel.self) private var viewModel

    @State private var showAlbumSelection: Bool = false
    @State private var cardsOpacity: Double = 0
    @State private var savedSession: SessionState? = nil

    var body: some View {
        GeometryReader { geometry in
            // Check device idiom for accurate iPad detection
            let isIPad = UIDevice.current.userInterfaceIdiom == .pad

            // Debug logging
            let _ = print("🔍 HomeView - View: \(geometry.size), Native: \(UIScreen.main.nativeBounds.size), Scale: \(UIScreen.main.nativeScale), isIPad: \(isIPad), Idiom: \(UIDevice.current.userInterfaceIdiom)")

            // Adjust spacing based on whether resume session card is present
            let hasResumeSession = savedSession != nil
            let headerTopPadding: CGFloat = isIPad ? 40 : (hasResumeSession ? 30 : 40)
            let headerBottomPadding: CGFloat = isIPad ? 24 : (hasResumeSession ? 8 : 20)
            let cardSpacing: CGFloat = isIPad ? 20 : (hasResumeSession ? 12 : 16)
            let sectionSpacing: CGFloat = isIPad ? 32 : (hasResumeSession ? 12 : 24)

        NavigationStack {
            ZStack {
                // Dynamic background
                DynamicBackgroundView(colorScheme: .vibrantPurple)

                VStack(spacing: sectionSpacing) {
                    // Header - Compact when session exists
                    if let session = savedSession {
                        // Compact header
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: isIPad ? 20 : 24, weight: .semibold))
                                .foregroundColor(.white)

                            Text("PhotoCleaner")
                                .font(.system(size: isIPad ? 18 : 20, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Spacer()
                        }
                        .padding(.horizontal, isIPad ? 24 : 20)
                        .padding(.top, isIPad ? 20 : 50)
                        .padding(.bottom, 8)

                        // Full Resume Session Card
                        CompactResumeSessionCard(session: session, isIPad: isIPad) {
                            Task {
                                await viewModel.restoreSessionState(session)
                            }
                        } onDiscard: {
                            SessionPersistenceManager.shared.clearSession()
                            savedSession = nil
                        }
                        .opacity(cardsOpacity)
                        .padding(.horizontal, isIPad ? 24 : 20)
                    } else {
                        // Full header when no session
                        VStack(spacing: isIPad ? 16 : 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: isIPad ? 70 : 50, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white, Color.purple.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("PhotoCleaner")
                                .font(.system(size: isIPad ? 48 : 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Clean up your photo library")
                                .font(.system(size: isIPad ? 20 : 16, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                        .padding(.top, headerTopPadding)
                        .padding(.bottom, headerBottomPadding)
                    }

                    // Quick Action Cards
                    VStack(spacing: cardSpacing) {
                        // Primary Card - Start Cleaning
                        ActionCard(
                            icon: "photo.stack.fill",
                            title: "Start Cleaning",
                            subtitle: "Swipe through all photos",
                            gradient: [Color.purple, Color.blue],
                            isLarge: true,
                            isIPad: isIPad,
                            hasResumeSession: hasResumeSession
                        ) {
                            startCleaningAllPhotos()
                        }

                        // Secondary Cards Grid
                        HStack(spacing: cardSpacing) {
                            ActionCard(
                                icon: "folder.fill",
                                title: "By Album",
                                subtitle: "Clean specific albums",
                                gradient: [Color.orange, Color.pink],
                                isIPad: isIPad,
                                hasResumeSession: hasResumeSession
                            ) {
                                showAlbumSelection = true
                            }

                            ActionCard(
                                icon: "chart.bar.fill",
                                title: "Large Files",
                                subtitle: "Free up most space",
                                gradient: [Color.green, Color.teal],
                                isIPad: isIPad,
                                hasResumeSession: hasResumeSession
                            ) {
                                startLargeFilesCleaning()
                            }
                        }

                        HStack(spacing: cardSpacing) {
                            ActionCard(
                                icon: "camera.viewfinder",
                                title: "Screenshots",
                                subtitle: "Clean up screenshots",
                                gradient: [Color.indigo, Color.purple],
                                isIPad: isIPad,
                                hasResumeSession: hasResumeSession
                            ) {
                                startScreenshotsCleaning()
                            }

                            ActionCard(
                                icon: "video.fill",
                                title: "Videos Only",
                                subtitle: "Clean video files",
                                gradient: [Color.red, Color.orange],
                                isIPad: isIPad,
                                hasResumeSession: hasResumeSession
                            ) {
                                startVideosCleaning()
                            }
                        }
                    }
                    .opacity(cardsOpacity)
                    .padding(.horizontal, isIPad ? 40 : 20)
                    .padding(.bottom, isIPad ? 40 : 30)

                    Spacer(minLength: 0)
                }
            }
            .navigationDestination(isPresented: $showAlbumSelection) {
                AlbumSelectionView()
            }
        }
        }
        .onAppear {
            // Check for saved session
            savedSession = viewModel.getSavedSession()

            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                cardsOpacity = 1.0
            }
        }
    }

    // MARK: - Actions

    private func startCleaningAllPhotos() {
        Task {
            await viewModel.loadPhotos(from: nil)
        }
    }

    private func startLargeFilesCleaning() {
        Task {
            await viewModel.loadLargestFiles()
        }
    }

    private func startScreenshotsCleaning() {
        Task {
            await viewModel.loadScreenshotsOnly()
        }
    }

    private func startVideosCleaning() {
        Task {
            await viewModel.loadVideosOnly()
        }
    }
}

// MARK: - Action Card

struct ActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    var isLarge: Bool = false
    var isIPad: Bool = false
    var hasResumeSession: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: isLarge ? (isIPad ? 20 : (hasResumeSession ? 12 : 16)) : (isIPad ? 16 : (hasResumeSession ? 8 : 12))) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: isLarge ? (isIPad ? 60 : (hasResumeSession ? 36 : 44)) : (isIPad ? 48 : (hasResumeSession ? 28 : 32)), weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: isLarge ? (isIPad ? 90 : (hasResumeSession ? 58 : 70)) : (isIPad ? 70 : (hasResumeSession ? 44 : 50)),
                           height: isLarge ? (isIPad ? 90 : (hasResumeSession ? 58 : 70)) : (isIPad ? 70 : (hasResumeSession ? 44 : 50)))
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(0.3)
                    )

                // Text
                VStack(spacing: isIPad ? 6 : (hasResumeSession ? 2 : 4)) {
                    Text(title)
                        .font(.system(size: isLarge ? (isIPad ? 28 : (hasResumeSession ? 20 : 22)) : (isIPad ? 24 : (hasResumeSession ? 16 : 17)), weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: isLarge ? (isIPad ? 18 : (hasResumeSession ? 14 : 15)) : (isIPad ? 16 : (hasResumeSession ? 12 : 13)), weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isLarge ? (isIPad ? 240 : (hasResumeSession ? 150 : 180)) : (isIPad ? 200 : (hasResumeSession ? 135 : 160)))
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.25) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                LinearGradient(
                                    colors: gradient.map { $0.opacity(0.5) },
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: gradient[0].opacity(0.3), radius: 15, y: 8)
            )
        }
        .buttonStyle(CardButtonStyle())
    }
}

// MARK: - Resume Session Card

struct ResumeSessionCard: View {
    let session: SessionState
    var isIPad: Bool = false
    let onResume: () -> Void
    let onDiscard: () -> Void

    @State private var showDiscardAlert = false

    private var progressPercentage: Int {
        guard session.totalPhotos > 0 else { return 0 }
        return Int((Double(session.photosReviewed) / Double(session.totalPhotos)) * 100)
    }

    private var timeAgo: String {
        let elapsed = Date().timeIntervalSince(session.timestamp)
        if elapsed < 3600 {
            let minutes = Int(elapsed / 60)
            return "\(minutes)m ago"
        } else if elapsed < 86400 {
            let hours = Int(elapsed / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(elapsed / 86400)
            return "\(days)d ago"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: isIPad ? 14 : 16, weight: .semibold))
                            .foregroundColor(.orange)

                        Text("Resume Session")
                            .font(.system(size: isIPad ? 16 : 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text(session.albumName)
                        .font(.system(size: isIPad ? 12 : 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Button(action: {
                    showDiscardAlert = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: isIPad ? 20 : 24))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(isIPad ? 12 : 16)

            Divider()
                .background(Color.white.opacity(0.1))

            // Stats
            HStack(spacing: isIPad ? 16 : 24) {
                StatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(session.photosReviewed)",
                    label: "Reviewed",
                    color: .blue,
                    isIPad: isIPad
                )

                StatItem(
                    icon: "trash.fill",
                    value: "\(session.photosDeleted)",
                    label: "Deleted",
                    color: .red,
                    isIPad: isIPad
                )

                StatItem(
                    icon: "chart.bar.fill",
                    value: "\(progressPercentage)%",
                    label: "Progress",
                    color: .green,
                    isIPad: isIPad
                )
            }
            .padding(.vertical, isIPad ? 12 : 16)
            .padding(.horizontal, isIPad ? 12 : 16)

            // Progress Bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(progressPercentage) / 100, height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(session.photosReviewed) of \(session.totalPhotos) photos")
                        .font(.system(size: isIPad ? 11 : 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Spacer()

                    Text(timeAgo)
                        .font(.system(size: isIPad ? 11 : 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, isIPad ? 12 : 16)
            .padding(.bottom, isIPad ? 12 : 16)

            // Resume Button
            Button(action: onResume) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: isIPad ? 14 : 16, weight: .bold))

                    Text("Continue Cleaning")
                        .font(.system(size: isIPad ? 15 : 17, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 44 : 50)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(isIPad ? 12 : 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.5), Color.pink.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.orange.opacity(0.3), radius: 15, y: 8)
        )
        .alert("Discard Session?", isPresented: $showDiscardAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Discard", role: .destructive) {
                onDiscard()
            }
        } message: {
            Text("This will permanently delete your saved progress. You won't be able to resume this session.")
        }
    }

    struct StatItem: View {
        let icon: String
        let value: String
        let label: String
        let color: Color
        var isIPad: Bool = false

        var body: some View {
            VStack(spacing: isIPad ? 4 : 6) {
                Image(systemName: icon)
                    .font(.system(size: isIPad ? 16 : 20, weight: .semibold))
                    .foregroundColor(color)

                Text(value)
                    .font(.system(size: isIPad ? 16 : 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(label)
                    .font(.system(size: isIPad ? 10 : 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Compact Resume Session Card

struct CompactResumeSessionCard: View {
    let session: SessionState
    var isIPad: Bool = false
    let onResume: () -> Void
    let onDiscard: () -> Void

    @State private var showDiscardAlert = false

    private var progressPercentage: Int {
        guard session.totalPhotos > 0 else { return 0 }
        return Int((Double(session.photosReviewed) / Double(session.totalPhotos)) * 100)
    }

    private var timeAgo: String {
        let elapsed = Date().timeIntervalSince(session.timestamp)
        if elapsed < 3600 {
            let minutes = Int(elapsed / 60)
            return "\(minutes)m ago"
        } else if elapsed < 86400 {
            let hours = Int(elapsed / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(elapsed / 86400)
            return "\(days)d ago"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: isIPad ? 14 : 16, weight: .semibold))
                            .foregroundColor(.orange)

                        Text("Resume Session")
                            .font(.system(size: isIPad ? 16 : 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text(session.albumName)
                        .font(.system(size: isIPad ? 12 : 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Button(action: {
                    showDiscardAlert = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: isIPad ? 20 : 24))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(isIPad ? 12 : 16)

            Divider()
                .background(Color.white.opacity(0.1))

            // Stats
            HStack(spacing: isIPad ? 16 : 24) {
                StatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(session.photosReviewed)",
                    label: "Reviewed",
                    color: .blue,
                    isIPad: isIPad
                )

                StatItem(
                    icon: "trash.fill",
                    value: "\(session.photosDeleted)",
                    label: "Deleted",
                    color: .red,
                    isIPad: isIPad
                )

                StatItem(
                    icon: "chart.bar.fill",
                    value: "\(progressPercentage)%",
                    label: "Progress",
                    color: .green,
                    isIPad: isIPad
                )
            }
            .padding(.vertical, isIPad ? 12 : 16)
            .padding(.horizontal, isIPad ? 12 : 16)

            // Progress Bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * CGFloat(progressPercentage) / 100, height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(session.photosReviewed) of \(session.totalPhotos) photos")
                        .font(.system(size: isIPad ? 11 : 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Spacer()

                    Text(timeAgo)
                        .font(.system(size: isIPad ? 11 : 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, isIPad ? 12 : 16)
            .padding(.bottom, isIPad ? 12 : 16)

            // Resume Button
            Button(action: onResume) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: isIPad ? 14 : 16, weight: .bold))

                    Text("Continue Cleaning")
                        .font(.system(size: isIPad ? 15 : 17, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 44 : 50)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(isIPad ? 12 : 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.5), Color.pink.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.orange.opacity(0.3), radius: 15, y: 8)
        )
        .alert("Discard Session?", isPresented: $showDiscardAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Discard", role: .destructive) {
                onDiscard()
            }
        } message: {
            Text("This will permanently delete your saved progress. You won't be able to resume this session.")
        }
    }

    struct StatItem: View {
        let icon: String
        let value: String
        let label: String
        let color: Color
        var isIPad: Bool = false

        var body: some View {
            VStack(spacing: isIPad ? 4 : 6) {
                Image(systemName: icon)
                    .font(.system(size: isIPad ? 16 : 20, weight: .semibold))
                    .foregroundColor(color)

                Text(value)
                    .font(.system(size: isIPad ? 16 : 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(label)
                    .font(.system(size: isIPad ? 10 : 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    HomeView()
        .environment(PhotoCleanerViewModel(
            photoService: PhotoLibraryService(),
            deletionService: PhotoDeletionService()
        ))
}

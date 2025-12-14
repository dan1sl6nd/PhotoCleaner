//
//  SummaryView.swift
//  PhotoCleaner
//
//  Created by Dan Mukashev on 2025-12-09.
//

import SwiftUI

struct SummaryView: View {
    @Environment(PhotoCleanerViewModel.self) private var viewModel

    @State private var showDeleteConfirmation = false
    @State private var hasProcessedDeletion = false
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.95
    @State private var confettiPieces: [ConfettiPiece] = []
    @State private var starRotation: Double = 0
    @State private var statScale: [Int: CGFloat] = [:]
    @State private var viewSize: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic celebratory background
                DynamicBackgroundView(colorScheme: .sunsetGlow)

                // Confetti overlay
                ForEach(confettiPieces) { piece in
                    ConfettiView(piece: piece)
                }

                VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 48) {
                    // Celebratory icon with premium gradient
                    ZStack {
                        // Multiple glow layers for depth
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.8, blue: 0.2).opacity(0.4 - Double(index) * 0.1),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: CGFloat(100 + index * 30)
                                    )
                                )
                                .frame(width: CGFloat(140 + index * 30), height: CGFloat(140 + index * 30))
                                .blur(radius: CGFloat(20 + index * 10))
                        }

                        // Rotating ring effect
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.yellow.opacity(0.6),
                                        Color.orange.opacity(0.4),
                                        Color.yellow.opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 130, height: 130)
                            .rotationEffect(.degrees(starRotation))

                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.85, blue: 0.3),
                                            Color(red: 1.0, green: 0.65, blue: 0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 110, height: 110)
                                .shadow(color: Color.orange.opacity(0.6), radius: 25, y: 12)
                                .shadow(color: Color.yellow.opacity(0.4), radius: 40, y: 0)

                            Image(systemName: "star.fill")
                                .font(.system(size: 55, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white, Color.white.opacity(0.95)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.orange.opacity(0.8), radius: 10)
                        }
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(starRotation * 0.5))
                    }

                    // Content
                    VStack(spacing: 32) {
                        // Title
                        VStack(spacing: 12) {
                            Text("Amazing Job!")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            if let album = viewModel.selectedAlbum {
                                Text(album.name)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }

                        // Statistics with premium icons
                        VStack(spacing: 16) {
                            SummaryStatRow(
                                icon: "photo.stack",
                                iconColor: Color(red: 0.4, green: 0.5, blue: 0.7).opacity(0.4),
                                label: "Reviewed",
                                value: "\(viewModel.stats.photosReviewed)"
                            )
                            .scaleEffect(statScale[0] ?? 0.8)

                            SummaryStatRow(
                                icon: "trash.fill",
                                iconColor: Color(red: 0.8, green: 0.4, blue: 0.4).opacity(0.4),
                                label: "Deleted",
                                value: "\(viewModel.stats.photosDeleted)"
                            )
                            .scaleEffect(statScale[1] ?? 0.8)

                            SummaryStatRow(
                                icon: "checkmark.circle.fill",
                                iconColor: Color(red: 0.4, green: 0.7, blue: 0.5).opacity(0.4),
                                label: "Kept",
                                value: "\(viewModel.stats.photosKept)"
                            )
                            .scaleEffect(statScale[2] ?? 0.8)

                            if viewModel.stats.photosSkipped > 0 {
                                SummaryStatRow(
                                    icon: "forward.fill",
                                    iconColor: Color(red: 0.7, green: 0.6, blue: 0.4).opacity(0.4),
                                    label: "Skipped",
                                    value: "\(viewModel.stats.photosSkipped)"
                                )
                                .scaleEffect(statScale[3] ?? 0.8)
                            }

                            SummaryStatRow(
                                icon: "arrow.down.circle.fill",
                                iconColor: Color(red: 0.4, green: 0.6, blue: 0.7).opacity(0.4),
                                label: "Space Freed",
                                value: viewModel.stats.formattedSpaceFreed
                            )
                            .scaleEffect(statScale[4] ?? 0.8)
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.18, green: 0.20, blue: 0.26).opacity(0.8),
                                            Color(red: 0.14, green: 0.16, blue: 0.22).opacity(0.7)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.4, green: 0.5, blue: 0.65).opacity(0.4),
                                            Color(red: 0.25, green: 0.35, blue: 0.50).opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                        .padding(.horizontal, 32)
                    }
                }
                .opacity(opacity)

                Spacer()
                Spacer()

                // Action Buttons with vibrant gradients
                VStack(spacing: 16) {
                    // Review Skipped Photos
                    if viewModel.stats.photosSkipped > 0 {
                        Button(action: {
                            viewModel.reviewSkippedPhotos()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                    .font(.system(size: 22))
                                Text("Review Skipped (\(viewModel.stats.photosSkipped))")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(Color(red: 0.92, green: 0.94, blue: 0.98))
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color(red: 0.20, green: 0.22, blue: 0.28).opacity(0.6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 30)
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.4, green: 0.5, blue: 0.65).opacity(0.5),
                                                        Color(red: 0.3, green: 0.4, blue: 0.55).opacity(0.3)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1.5
                                            )
                                    )
                            )
                        }
                        .padding(.horizontal, 32)
                    }

                    // Continue Button with premium gradient
                    Button(action: {
                        viewModel.resetSession()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 22))
                            Text("Continue Curating")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.5, green: 0.65, blue: 0.85),
                                            Color(red: 0.4, green: 0.5, blue: 0.75)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color(red: 0.4, green: 0.5, blue: 0.75).opacity(0.5), radius: 15, y: 8)
                        )
                    }
                    .padding(.horizontal, 32)
                }
                .opacity(opacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            // Store view size
            viewSize = geometry.size

            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                scale = 1.0
            }

            // Start star rotation
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                starRotation = 360
            }

            // Launch confetti
            launchConfetti(width: geometry.size.width, height: geometry.size.height)

            // Animate stats sequentially
            for index in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        statScale[index] = 1.0
                    }
                }
            }
        }
        .alert("Delete Photos?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelDeletion()
                hasProcessedDeletion = true
            }
            Button("Delete \(viewModel.stats.photosDeleted) Photos", role: .destructive) {
                Task {
                    await executeDeletion()
                }
            }
        } message: {
            Text("This will permanently delete \(viewModel.stats.photosDeleted) photos (\(viewModel.stats.formattedSpaceFreed)). They will be moved to Recently Deleted for 30 days.")
        }
        .overlay {
            if viewModel.isDeletingBatch {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)

                        Text("Deleting photos...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                    )
                }
            }
        }
        .task {
            // Show deletion confirmation if photos are queued
            if !hasProcessedDeletion && !viewModel.deletionQueue.isEmpty {
                showDeleteConfirmation = true
            }
        }
        }
    }

    // MARK: - Methods

    private func executeDeletion() async {
        do {
            try await viewModel.executeBatchDeletion()
            hasProcessedDeletion = true
        } catch {
            // Error is already set in viewModel.errorMessage
            hasProcessedDeletion = true
        }
    }

    private func launchConfetti(width: CGFloat, height: CGFloat) {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan]
        let shapes: [String] = ["circle.fill", "star.fill", "heart.fill", "sparkle"]

        confettiPieces = (0..<60).map { index in
            ConfettiPiece(
                id: index,
                color: colors.randomElement() ?? .purple,
                shape: shapes.randomElement() ?? "circle.fill",
                x: CGFloat.random(in: 0...width),
                y: -50,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.3...1.0)
            )
        }

        // Animate confetti falling
        for i in 0..<confettiPieces.count {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 2.5...4.0)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: duration)) {
                    confettiPieces[i].y = height + 50
                    confettiPieces[i].rotation += 720
                }
            }
        }
    }
}

struct SummaryStatRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor)
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            // Label
            Text(label)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.95))

            Spacer()

            // Value
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Confetti

struct ConfettiPiece: Identifiable {
    let id: Int
    let color: Color
    let shape: String
    var x: CGFloat
    var y: CGFloat
    var rotation: Double
    let scale: CGFloat
}

struct ConfettiView: View {
    let piece: ConfettiPiece

    var body: some View {
        Image(systemName: piece.shape)
            .font(.system(size: 16 * piece.scale, weight: .bold))
            .foregroundColor(piece.color)
            .rotationEffect(.degrees(piece.rotation))
            .position(x: piece.x, y: piece.y)
            .shadow(color: piece.color.opacity(0.6), radius: 5)
    }
}

#Preview {
    SummaryView()
        .environment(PhotoCleanerViewModel(
            photoService: PhotoLibraryService(),
            deletionService: PhotoDeletionService()
        ))
}

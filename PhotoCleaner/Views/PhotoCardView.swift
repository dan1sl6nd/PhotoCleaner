//
//  PhotoCardView.swift
//  PhotoCleaner
//
//  Created by Dan Mukashev on 2025-12-09.
//

import SwiftUI
import AVKit

struct PhotoCardView: View {
    let image: UIImage?
    let videoURL: URL?
    let isVideo: Bool
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var isExiting: Bool = false
    @State private var hasTriggeredThresholdHaptic: Bool = false
    @State private var player: AVPlayer?
    @State private var videoObserver: NSObjectProtocol?

    private let swipeThreshold: CGFloat = 150
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Card container with rounded corners and blur background
                ZStack {
                    // Blurred background layer
                    if isVideo {
                        if player != nil {
                            // For video, use a dark background
                            LinearGradient(
                                colors: [
                                    Color(red: 0.08, green: 0.08, blue: 0.12),
                                    Color(red: 0.12, green: 0.12, blue: 0.16)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    } else if let image = image {
                        // Blurred background of the same image
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width * 0.82, height: geometry.size.height * 0.92)
                            .blur(radius: 40)
                            .opacity(0.3)
                    }

                    // Main content layer
                    ZStack {
                        if isVideo {
                            // Video Player
                            if let player = player {
                                ZStack {
                                    VideoPlayer(player: player)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: geometry.size.width * 0.82)
                                        .frame(maxHeight: geometry.size.height * 0.92)
                                        .disabled(true)

                                    // Invisible overlay to catch gestures
                                    Color.clear
                                        .frame(width: geometry.size.width * 0.82)
                                        .frame(maxHeight: geometry.size.height * 0.92)
                                        .contentShape(Rectangle())
                                }
                            } else {
                                // Loading video placeholder
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.16, green: 0.18, blue: 0.22),
                                        Color(red: 0.14, green: 0.16, blue: 0.20)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                    .frame(width: geometry.size.width * 0.82, height: geometry.size.height * 0.92)
                                    .overlay {
                                        VStack(spacing: 12) {
                                            ProgressView()
                                                .tint(Color(red: 0.7, green: 0.8, blue: 0.95))
                                            Text("Loading video...")
                                                .font(.system(size: 14))
                                                .foregroundColor(Color(red: 0.7, green: 0.75, blue: 0.85))
                                        }
                                    }
                            }
                        } else if let image = image {
                            // Image with proper aspect ratio
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width * 0.82)
                                .frame(maxHeight: geometry.size.height * 0.92)
                        } else {
                            // Loading placeholder
                            LinearGradient(
                                colors: [
                                    Color(red: 0.16, green: 0.18, blue: 0.22),
                                    Color(red: 0.14, green: 0.16, blue: 0.20)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                                .frame(width: geometry.size.width * 0.82, height: geometry.size.height * 0.92)
                                .overlay {
                                    ProgressView()
                                        .tint(Color(red: 0.7, green: 0.8, blue: 0.95))
                                }
                        }
                    }
                }
                .frame(width: geometry.size.width * 0.82, height: geometry.size.height * 0.92)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 0.10, green: 0.10, blue: 0.14))
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.6), radius: 30, y: 15)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.35, green: 0.40, blue: 0.50).opacity(0.3),
                                    Color(red: 0.20, green: 0.25, blue: 0.35).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .offset(dragOffset)
            .rotationEffect(.degrees(rotation))

            // Swipe overlay (stays fixed, doesn't move with card)
            swipeOverlay(width: geometry.size.width, height: geometry.size.height)
        }
        .gesture(swipeGesture)
        .onAppear {
            if isVideo, let videoURL = videoURL {
                setupVideoPlayer(url: videoURL)
            }
        }
        .onDisappear {
            player?.pause()
            player = nil

            // Remove notification observer to prevent memory leak
            if let observer = videoObserver {
                NotificationCenter.default.removeObserver(observer)
                videoObserver = nil
            }
        }
    }

    private func setupVideoPlayer(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.play()

        // Loop video - store observer to remove later
        videoObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }

    // MARK: - Swipe Overlay

    @ViewBuilder
    private func swipeOverlay(width: CGFloat, height: CGFloat) -> some View {
        let horizontalProgress = abs(dragOffset.width) / swipeThreshold

        if horizontalProgress > 0.15 {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Position on LEFT when swiping RIGHT (KEEP)
                    if dragOffset.width > 0 {
                        overlayContent(horizontalProgress: horizontalProgress)
                            .frame(width: geo.size.width * 0.4)
                        Spacer()
                    }

                    // Position on RIGHT when swiping LEFT (DELETE)
                    if dragOffset.width < 0 {
                        Spacer()
                        overlayContent(horizontalProgress: horizontalProgress)
                            .frame(width: geo.size.width * 0.4)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }

    @ViewBuilder
    private func overlayContent(horizontalProgress: CGFloat) -> some View {
        ZStack {
            VStack(spacing: 20) {
                // Icon
                overlayIcon
                    .font(.system(size: 70, weight: .bold))
                    .shadow(color: .black.opacity(0.5), radius: 10)

                Text(dragOffset.width < 0 ? "DELETE" : "KEEP")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .tracking(3)
                    .shadow(color: .black.opacity(0.5), radius: 5)
            }
            .foregroundColor(.white)
        }
        .opacity(min(horizontalProgress * 1.2, 1.0))
        .scaleEffect(min(0.8 + (horizontalProgress * 0.4), 1.2))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: horizontalProgress)
    }

    private var overlayIcon: some View {
        let icon = dragOffset.width < 0 ? "xmark.circle.fill" : "checkmark.circle.fill"
        return Image(systemName: icon)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.white, overlayColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var overlayColor: Color {
        dragOffset.width < 0 ? Color.red : Color.green
    }

    // MARK: - Gesture

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                guard !isExiting else { return }
                // Only allow horizontal drag
                dragOffset = CGSize(width: gesture.translation.width, height: 0)
                rotation = Double(gesture.translation.width / 20)

                // Trigger haptic feedback when crossing threshold
                let horizontalProgress = abs(gesture.translation.width)
                if horizontalProgress > swipeThreshold && !hasTriggeredThresholdHaptic {
                    lightImpact.impactOccurred()
                    hasTriggeredThresholdHaptic = true
                } else if horizontalProgress < swipeThreshold {
                    hasTriggeredThresholdHaptic = false
                }
            }
            .onEnded { gesture in
                guard !isExiting else { return }
                handleSwipeEnd(gesture)
                hasTriggeredThresholdHaptic = false
            }
    }

    private func handleSwipeEnd(_ gesture: DragGesture.Value) {
        let horizontalSwipe = gesture.translation.width

        // Check if swipe is strong enough
        if abs(horizontalSwipe) > swipeThreshold {
            // Confirmed action - medium haptic
            mediumImpact.impactOccurred()

            if horizontalSwipe < 0 {
                // Left swipe - DELETE
                animateExit(direction: .left)
                onSwipeLeft()
            } else {
                // Right swipe - KEEP
                animateExit(direction: .right)
                onSwipeRight()
            }
        } else {
            // Reset to center
            resetPosition()
        }
    }

    // MARK: - Animations

    private func animateExit(direction: SwipeDirection) {
        isExiting = true

        withAnimation(.easeOut(duration: 0.3)) {
            switch direction {
            case .left:
                dragOffset = CGSize(width: -500, height: 0)
            case .right:
                dragOffset = CGSize(width: 500, height: 0)
            default:
                break
            }
        }
    }

    private func resetPosition() {
        withAnimation(.spring()) {
            dragOffset = .zero
            rotation = 0
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()

        PhotoCardView(
            image: UIImage(systemName: "photo"),
            videoURL: nil,
            isVideo: false,
            onSwipeLeft: { print("Swiped left") },
            onSwipeRight: { print("Swiped right") }
        )
    }
}

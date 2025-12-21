//
//  PhotoSwipeView.swift
//  PhotoCleaner
//
//  Created by Dan Mukashev on 2025-12-09.
//

import SwiftUI
import Photos

struct PhotoSwipeView: View {
    @Environment(PhotoCleanerViewModel.self) private var viewModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var currentImage: UIImage?
    @State private var currentVideoURL: URL?
    @State private var isLoadingImage: Bool = false
    @State private var showingCard: Bool = false
    @State private var preloadedImages: [String: UIImage] = [:]
    @State private var preloadedVideos: [String: URL] = [:]
    @State private var isAnimatingSwipe: Bool = false
    @State private var showBackWarning: Bool = false
    @State private var cachedAssetIds: Set<String> = []
    @State private var demoDragOffset: CGSize? = nil
    @State private var idleHintTask: Task<Void, Never>?
    @State private var lastInteractionAt: Date = .now
    @State private var hasSeenIdleHint: Bool = false
    @State private var isMuted: Bool = false // Persist mute state across all videos
    @State private var pendingUndo: Bool = false // Queue undo if pressed during loading
    @State private var loadingPhotoId: String? = nil // Track which photo is currently loading
    @State private var swipeAnimationTask: Task<Void, Never>? = nil // Track swipe animation task
    @State private var cardRefreshId: UUID = UUID() // Force card refresh on undo

    // MARK: - Configuration

    private enum Configuration {
        static let preloadCount: Int = 3          // Preload next N photos
        static let maxImageCacheSize: Int = 3     // Maximum preloaded images
        static let maxVideoCacheSize: Int = 1     // Maximum preloaded videos (memory limited)
        static let idleHintDelay: UInt64 = 5_000_000_000 // 5 seconds in nanoseconds
    }

    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                ZStack {
                    // Dynamic background
                    DynamicBackgroundView(colorScheme: .emeraldForest)

                    VStack(spacing: 0) {
                        // Stats Bar (moved above photo card)
                        StatsBarView(stats: viewModel.stats)
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                        // Main Content - Fixed frame to prevent stats bar movement
                        Group {
                            if viewModel.isLoading {
                                // Show custom loading placeholder instead of default ProgressView
                                LoadingCardPlaceholder(
                                    cardSize: CGSize(
                                        width: geometry.size.width * 0.82,
                                        height: geometry.size.height * 0.65
                                    )
                                )
                            } else if viewModel.isSessionComplete {
                                // Session complete - this will be handled by MainCoordinatorView
                                Text("All photos reviewed!")
                                    .font(.title)
                                    .foregroundColor(Color(red: 0.7, green: 0.75, blue: 0.85))
                            } else {
                                ZStack {
                                    // Photo/Video Card
                                    if showingCard, let photo = viewModel.currentPhoto {
                                        PhotoCardView(
                                            image: currentImage,
                                            videoURL: currentVideoURL,
                                            isVideo: photo.asset.mediaType == .video,
                                            isMuted: $isMuted,
                                            onSwipeLeft: {
                                                handleSwipe(.delete)
                                            },
                                            onSwipeRight: {
                                                handleSwipe(.keep)
                                            },
                                            onUserInteraction: {
                                                registerUserInteraction()
                                            },
                                            demoDragOffset: demoDragOffset
                                        )
                                        .id("\(photo.id)-\(cardRefreshId)") // Force new view instance for each photo and on refresh
                                        .transition(.scale.combined(with: .opacity))
                                    }

                                    // Floating loading indicator (shows over card area when loading)
                                    if isLoadingImage {
                                        LoadingFloatingIndicator()
                                            .transition(.opacity)
                                    }
                                }
                            }
                        }
                        .frame(height: geometry.size.height * 0.65)

                        Spacer()

                        // Minimal Bottom Controls
                        bottomControls
                            .padding(.bottom, 12)
                    }
                    .safeAreaInset(edge: .top, spacing: 0) {
                        Color.clear.frame(height: 0)
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        Color.clear.frame(height: 0)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        registerUserInteraction()
                        showBackWarning = true
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.7, green: 0.8, blue: 0.95))
                    }
                    .buttonStyle(.plain)
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(viewModel.selectedAlbum?.name ?? "All Photos")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(red: 0.92, green: 0.94, blue: 0.98))

                        if viewModel.isReviewingSkipped {
                            Text("\(viewModel.skippedReviewIndex + 1)/\(viewModel.totalSkippedPhotos) skipped")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75))
                        } else {
                            Text("\(viewModel.stats.photosReviewed)/\(viewModel.stats.totalPhotos)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(red: 0.6, green: 0.65, blue: 0.75))
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        registerUserInteraction()
                        viewModel.finishEarly()
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.green, Color.teal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.green.opacity(0.3), radius: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .task {
                await loadCurrentPhoto()
                armIdleHintIfNeeded()
            }
            .onChange(of: viewModel.currentIndex) {
                // Don't reload during swipe animation
                guard !isAnimatingSwipe else { return }
                Task {
                    await loadCurrentPhoto()
                    armIdleHintIfNeeded()
                }
            }
            .onDisappear {
                idleHintTask?.cancel()
                idleHintTask = nil
                // Save session before leaving
                viewModel.saveSessionState()
                // Release all cached media to free memory
                clearAllCaches()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                // Clear caches on memory warning
                clearAllCaches()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                // Save session when app goes to background or becomes inactive
                if newPhase == .background || newPhase == .inactive {
                    viewModel.saveSessionState()
                }
            }
            .onDisappear {
                // Additional save when view disappears for extra safety
                viewModel.saveSessionState()
            }
            .alert("Leave Without Saving?", isPresented: $showBackWarning) {
                Button("Cancel", role: .cancel) { }
                Button("Leave", role: .destructive) {
                    viewModel.resetSession()
                }
            } message: {
                Text("Your progress will be lost. Photos marked for deletion will not be removed.")
            }
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 60) {
            Button(action: {
                registerUserInteraction()

                // If card is loading or animating, queue the undo for later
                if isLoadingImage || isAnimatingSwipe || !showingCard {
                    // If swipe animation is happening, cancel it and reload current photo
                    if let task = swipeAnimationTask {
                        task.cancel()
                        swipeAnimationTask = nil
                        isAnimatingSwipe = false

                        // Reload current photo (processAction wasn't called yet)
                        Task {
                            await loadCurrentPhoto()
                        }
                        return
                    }

                    // Otherwise, queue the undo for after loading finishes
                    pendingUndo = true
                    return
                }

                // Execute undo immediately if ready
                executeUndo()
            }) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: viewModel.canUndo
                                        ? [Color.orange, Color.red]
                                        : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(
                                color: viewModel.canUndo ? Color.orange.opacity(0.6) : Color.clear,
                                radius: 12,
                                y: 6
                            )

                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }

                    Text("Undo")
                        .font(.system(size: 12, weight: .semibold))
                        .fontDesign(.default)
                        .foregroundColor(.white.opacity(viewModel.canUndo ? 0.9 : 0.5))
                }
            }
            .buttonStyle(BouncyButtonStyle())
            .disabled(!viewModel.canUndo)

            Button(action: {
                registerUserInteraction()
                handleSwipe(.skip)
            }) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.purple.opacity(0.6), radius: 12, y: 6)

                        Image(systemName: "forward.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }

                    Text("Skip")
                        .font(.system(size: 12, weight: .semibold))
                        .fontDesign(.default)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .buttonStyle(BouncyButtonStyle())
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Methods

    private func executeUndo() {
        // Cancel any ongoing swipe animation
        swipeAnimationTask?.cancel()
        swipeAnimationTask = nil

        // Reset all animation states when undoing
        isAnimatingSwipe = false
        showingCard = false
        demoDragOffset = nil
        currentImage = nil
        currentVideoURL = nil

        // Force PhotoCardView to be completely recreated
        cardRefreshId = UUID()

        viewModel.undoLastAction()

        // Reload the photo after undo with a brief delay to ensure clean state
        Task {
            // Wait for view state to fully reset
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            await loadCurrentPhoto()
        }
    }

    private func registerUserInteraction() {
        lastInteractionAt = Date()

        idleHintTask?.cancel()
        idleHintTask = nil
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            demoDragOffset = nil
        }
        armIdleHintIfNeeded()
    }

    private func armIdleHintIfNeeded() {
        guard showingCard, !isLoadingImage, !isAnimatingSwipe else { return }

        // Only show idle hint on first photo and only once
        guard viewModel.currentIndex == 0, !hasSeenIdleHint else { return }

        idleHintTask?.cancel()
        idleHintTask = Task { @MainActor in
            let hintDistance: CGFloat = 110

            // Wait before showing hint
            try? await Task.sleep(nanoseconds: Configuration.idleHintDelay)
            guard !Task.isCancelled else { return }
            guard showingCard, !isLoadingImage, !isAnimatingSwipe else { return }
            guard Date().timeIntervalSince(lastInteractionAt) >= 5 else { return }

            // Mark hint as shown
            hasSeenIdleHint = true

            // Show single hint cycle (right then left)
            do {

                // Hint right (keep)
                withAnimation(.easeInOut(duration: 0.5)) {
                    demoDragOffset = CGSize(width: hintDistance, height: 0)
                }
                try await Task.sleep(nanoseconds: 550_000_000)
                guard !Task.isCancelled else { return }

                // Return to center
                withAnimation(.easeInOut(duration: 0.25)) {
                    demoDragOffset = .zero
                }
                try await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }

                // Hint left (delete)
                withAnimation(.easeInOut(duration: 0.55)) {
                    demoDragOffset = CGSize(width: -hintDistance, height: 0)
                }
                try await Task.sleep(nanoseconds: 600_000_000)
                guard !Task.isCancelled else { return }

                // Return to center and finish
                withAnimation(.easeInOut(duration: 0.25)) {
                    demoDragOffset = .zero
                }
                try await Task.sleep(nanoseconds: 250_000_000)

                demoDragOffset = nil
            } catch {
                // Task was cancelled, clean up
                demoDragOffset = nil
            }
        }
    }

    private func handleSwipe(_ action: PhotoAction) {
        // CRITICAL: Prevent concurrent swipes to avoid data corruption
        guard !isAnimatingSwipe else {
            #if DEBUG
            print("⚠️ Ignoring swipe - animation already in progress")
            #endif
            return
        }

        registerUserInteraction()

        // Clear any pending undo (user swiped, so undo shouldn't happen)
        pendingUndo = false

        // Set flag to prevent onChange from firing
        isAnimatingSwipe = true

        // Animate card out
        withAnimation {
            showingCard = false
        }

        // Process action and load next photo after animation
        swipeAnimationTask = Task {
            // Wait for card exit animation
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

            // Check if task was cancelled (by undo)
            guard !Task.isCancelled else {
                isAnimatingSwipe = false
                return
            }

            // Process the action (this will update currentIndex)
            viewModel.processAction(action)

            // Load next photo
            await loadCurrentPhoto()

            // Reset flag
            isAnimatingSwipe = false
            swipeAnimationTask = nil
        }
    }

    private func loadCurrentPhoto() async {
        guard let photo = viewModel.currentPhoto else {
            showingCard = false
            pendingUndo = false
            loadingPhotoId = nil
            return
        }

        // Track which photo we're loading to detect if it changes mid-load
        let photoId = photo.id
        loadingPhotoId = photoId

        isLoadingImage = true
        showingCard = false // Reset first
        demoDragOffset = nil

        // Force a fresh PhotoCardView instance for each photo
        cardRefreshId = UUID()

        let isVideo = photo.asset.mediaType == .video

        if isVideo {
            // Load video
            var loadedVideoURL: URL?

            // Check if video is already preloaded
            if let preloadedVideo = preloadedVideos[photo.id] {
                loadedVideoURL = preloadedVideo
                // Remove from preloaded cache
                preloadedVideos.removeValue(forKey: photo.id)
            } else {
                // Load video if not preloaded (with 30 second timeout)
                loadedVideoURL = await withTimeout(seconds: 30) {
                    await viewModel.photoLibraryService.loadVideoURL(for: photo.asset)
                }
            }

            // Check if we're still loading the same photo (undo might have changed currentIndex)
            guard loadingPhotoId == photoId else {
                // Photo changed during loading, abort
                return
            }

            // Update UI
            currentVideoURL = loadedVideoURL
            currentImage = nil
            isLoadingImage = false

            // Check if undo was queued during loading - execute immediately without showing card
            if pendingUndo {
                pendingUndo = false
                loadingPhotoId = nil
                executeUndo()
                return
            }

            // Show card with animation
            withAnimation(.spring()) {
                showingCard = true
            }

            loadingPhotoId = nil

            // Preload next media
            await preloadUpcomingMedia()
            await MainActor.run {
                armIdleHintIfNeeded()
            }
        } else {
            // Load image
            let quickSize = CGSize(width: 700, height: 700)
            let targetSize = CGSize(width: 1400, height: 1400)
            var loadedImage: UIImage?

            // Check if image is already preloaded
            if let preloadedImage = preloadedImages[photo.id] {
                loadedImage = preloadedImage
                // Remove from preloaded cache
                preloadedImages.removeValue(forKey: photo.id)
            } else {
                // Load a quick image first for responsiveness
                loadedImage = await viewModel.photoLibraryService.loadThumbnailQuick(for: photo.asset, size: quickSize)
            }

            // Update UI
            if let image = loadedImage {
                // Check if we're still loading the same photo (undo might have changed currentIndex)
                guard loadingPhotoId == photoId else {
                    // Photo changed during loading, abort
                    return
                }

                currentImage = image
                currentVideoURL = nil
                isLoadingImage = false

                // Check if undo was queued during loading - execute immediately without showing card
                if pendingUndo {
                    pendingUndo = false
                    loadingPhotoId = nil
                    executeUndo()
                    return
                }

                // Show card with animation
                withAnimation(.spring()) {
                    showingCard = true
                }

                loadingPhotoId = nil

                // Upgrade to a higher-quality thumbnail when available
                Task {
                    let finalImage = await viewModel.photoLibraryService.loadThumbnail(for: photo.asset, size: targetSize)
                    guard let finalImage else { return }
                    guard viewModel.currentPhoto?.id == photoId else { return }
                    await MainActor.run {
                        currentImage = finalImage
                    }
                }

                // Preload next media
                await preloadUpcomingMedia()
                await MainActor.run {
                    armIdleHintIfNeeded()
                }
            } else {
                // Failed to load image
                isLoadingImage = false
                currentImage = nil
                currentVideoURL = nil
                loadingPhotoId = nil
            }
        }
    }

    private func updatePhotoKitCaching(targetSize: CGSize, startIndex: Int, endIndex: Int) {
        // Defensive: Validate range bounds
        guard startIndex >= 0,
              endIndex <= viewModel.photos.count,
              startIndex < endIndex else {
            #if DEBUG
            print("⚠️ updatePhotoKitCaching: Invalid range [\(startIndex)..<\(endIndex)] for photos.count: \(viewModel.photos.count)")
            #endif
            return
        }

        let newIds = Set(viewModel.photos[startIndex..<endIndex].map { $0.id })
        let idsToStop = cachedAssetIds.subtracting(newIds)
        let idsToStart = newIds.subtracting(cachedAssetIds)

        if !idsToStop.isEmpty {
            let stopAssets = viewModel.photos.compactMap { photo in
                idsToStop.contains(photo.id) ? photo.asset : nil
            }
            if !stopAssets.isEmpty {
                viewModel.photoLibraryService.stopCaching(assets: stopAssets, targetSize: targetSize)
            }
        }

        if !idsToStart.isEmpty {
            let startAssets = viewModel.photos[startIndex..<endIndex].compactMap { photo in
                idsToStart.contains(photo.id) ? photo.asset : nil
            }
            if !startAssets.isEmpty {
                viewModel.photoLibraryService.startCaching(assets: startAssets, targetSize: targetSize)
            }
        }

        cachedAssetIds = newIds
    }

    private func preloadUpcomingMedia() async {
        let targetSize = CGSize(width: 1400, height: 1400)

        // Get next media to preload
        let startIndex = max(viewModel.currentIndex + 1, 0)
        let endIndex = min(startIndex + Configuration.preloadCount, viewModel.photos.count)

        // Edge case: if no photos to preload, don't clear caches
        // (photos may still be in use)
        guard startIndex < endIndex else {
            return
        }

        // Enforce cache size limits before preloading
        enforceCacheSizeLimits()

        for index in startIndex..<endIndex {
            let photo = viewModel.photos[index]

            // Skip if already processed
            guard !photo.isProcessed else { continue }

            let isVideo = photo.asset.mediaType == .video

            if isVideo {
                // Skip if already preloaded
                guard preloadedVideos[photo.id] == nil else { continue }

                // Check cache size limit (lower for videos due to memory)
                guard preloadedVideos.count < Configuration.maxVideoCacheSize else { break }

                // Preload video
                if let videoURL = await viewModel.photoLibraryService.loadVideoURL(for: photo.asset) {
                    preloadedVideos[photo.id] = videoURL
                }
            } else {
                // Skip if already preloaded
                guard preloadedImages[photo.id] == nil else { continue }

                // Check cache size limit
                guard preloadedImages.count < Configuration.maxImageCacheSize else { break }

                // Preload image
                if let image = await viewModel.photoLibraryService.loadThumbnail(for: photo.asset, size: targetSize) {
                    preloadedImages[photo.id] = image
                }
            }
        }

        // Clean up old preloaded media (keep only next few)
        // Safety check: only filter if we have a valid range
        if startIndex < endIndex && endIndex <= viewModel.photos.count {
            let validIds = Set(viewModel.photos[startIndex..<endIndex].map { $0.id })
            preloadedImages = preloadedImages.filter { validIds.contains($0.key) }
            preloadedVideos = preloadedVideos.filter { validIds.contains($0.key) }
        }

        let cacheStartIndex = max(viewModel.currentIndex, 0)
        let cacheEndIndex = min(cacheStartIndex + Configuration.preloadCount + 1, viewModel.photos.count)
        if cacheStartIndex < cacheEndIndex {
            updatePhotoKitCaching(targetSize: targetSize, startIndex: cacheStartIndex, endIndex: cacheEndIndex)
        }
    }

    // MARK: - Cache Management

    private func enforceCacheSizeLimits() {
        // Remove entries furthest from current index to keep cache relevant
        if preloadedImages.count > Configuration.maxImageCacheSize {
            // Find keys furthest from current index
            let currentPhotoIndex = viewModel.currentIndex

            let sortedKeys = preloadedImages.keys.sorted { key1, key2 in
                let index1 = viewModel.photos.firstIndex(where: { $0.id == key1 }) ?? Int.max
                let index2 = viewModel.photos.firstIndex(where: { $0.id == key2 }) ?? Int.max
                let distance1 = abs(index1 - currentPhotoIndex)
                let distance2 = abs(index2 - currentPhotoIndex)
                return distance1 > distance2 // Sort by furthest first
            }

            let excessCount = preloadedImages.count - Configuration.maxImageCacheSize
            let keysToRemove = Array(sortedKeys.prefix(excessCount))
            for key in keysToRemove {
                preloadedImages.removeValue(forKey: key)
            }
        }

        // Use lower limit for videos to prevent memory issues
        if preloadedVideos.count > Configuration.maxVideoCacheSize {
            // Keep video closest to current index
            let currentPhotoIndex = viewModel.currentIndex

            let sortedKeys = preloadedVideos.keys.sorted { key1, key2 in
                let index1 = viewModel.photos.firstIndex(where: { $0.id == key1 }) ?? Int.max
                let index2 = viewModel.photos.firstIndex(where: { $0.id == key2 }) ?? Int.max
                let distance1 = abs(index1 - currentPhotoIndex)
                let distance2 = abs(index2 - currentPhotoIndex)
                return distance1 > distance2 // Sort by furthest first
            }

            let excessCount = preloadedVideos.count - Configuration.maxVideoCacheSize
            let keysToRemove = Array(sortedKeys.prefix(excessCount))
            for key in keysToRemove {
                preloadedVideos.removeValue(forKey: key)
            }
        }
    }

    private func clearAllCaches() {
        preloadedImages.removeAll()
        preloadedVideos.removeAll()

        if !cachedAssetIds.isEmpty {
            let targetSize = CGSize(width: 1400, height: 1400)
            let stopAssets = viewModel.photos.compactMap { photo in
                cachedAssetIds.contains(photo.id) ? photo.asset : nil
            }
            if !stopAssets.isEmpty {
                viewModel.photoLibraryService.stopCaching(assets: stopAssets, targetSize: targetSize)
            }
            cachedAssetIds.removeAll()
        }
    }
}

private struct LoadingFloatingIndicator: View {
    @State private var pulse: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer glow
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
                    .scaleEffect(pulse)

                // Icon
                Image(systemName: "photo.fill.on.rectangle.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.85, blue: 1.0),
                                Color(red: 0.6, green: 0.2, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(pulse)
                    .shadow(color: Color(red: 0.5, green: 0.65, blue: 0.85).opacity(0.5), radius: 10)
            }

            Text("Loading…")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = 1.15
            }
        }
    }
}

private struct LoadingCardPlaceholder: View {
    let cardSize: CGSize

    @State private var pulse: CGFloat = 1.0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.14))

            VStack(spacing: 16) {
                Image(systemName: "photo.fill.on.rectangle.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.85, blue: 1.0),
                                Color(red: 0.6, green: 0.2, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(pulse)
                    .shadow(color: Color(red: 0.5, green: 0.65, blue: 0.85).opacity(0.5), radius: 10)

                Text("Loading…")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(width: cardSize.width, height: cardSize.height)
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
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = 1.06
            }
        }
    }
}

// MARK: - Helper Functions

/// Helper function to add timeout to async operations
private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T?) async -> T? {
    await withTaskGroup(of: T?.self) { group in
        // Start the actual operation
        group.addTask {
            await operation()
        }

        // Start the timeout task
        group.addTask {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            return nil
        }

        // Return the first result (either the operation or the timeout)
        if let result = await group.next() {
            group.cancelAll()
            return result
        }

        return nil
    }
}

// MARK: - Custom Button Style

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    PhotoSwipeView()
        .environment(PhotoCleanerViewModel(
            photoService: PhotoLibraryService(),
            deletionService: PhotoDeletionService()
        ))
}

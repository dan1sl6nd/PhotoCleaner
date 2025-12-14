//
//  PhotoCleanerViewModel.swift
//  PhotoCleaner
//
//  Created by Dan Mukashev on 2025-12-09.
//

import Foundation
import Photos
import Observation

@Observable
@MainActor
class PhotoCleanerViewModel {
    // MARK: - Properties

    var photos: [PhotoAssetModel] = []
    var currentIndex: Int = 0
    var stats: SessionStats = SessionStats()
    var deletionQueue: [PHAsset] = []
    var actionHistory: [(photo: PhotoAssetModel, action: PhotoAction, index: Int)] = []
    var isLoading: Bool = false
    var isDeletingBatch: Bool = false
    var errorMessage: String?
    var selectedAlbum: AlbumModel?
    var isFinishedEarly: Bool = false
    var showAlbumSelection: Bool = false
    var isReviewingSkipped: Bool = false

    private let maxUndoHistory = 50 // Limit undo history to prevent memory issues

    private let photoService: PhotoLibraryService
    private let deletionService: PhotoDeletionService

    // MARK: - Computed Properties

    var currentPhoto: PhotoAssetModel? {
        guard currentIndex < photos.count else { return nil }
        return photos[currentIndex]
    }

    var hasMorePhotos: Bool {
        currentIndex < photos.count
    }

    var isSessionComplete: Bool {
        // All photos processed or user finished early
        return currentIndex >= photos.count || isFinishedEarly
    }

    var canUndo: Bool {
        !actionHistory.isEmpty
    }

    // MARK: - Computed Properties (exposed for views)

    var photoLibraryService: PhotoLibraryService {
        return photoService
    }

    // MARK: - Init

    init(photoService: PhotoLibraryService, deletionService: PhotoDeletionService) {
        self.photoService = photoService
        self.deletionService = deletionService
    }

    // MARK: - Load Photos

    func loadPhotos(from album: AlbumModel? = nil) async {
        isLoading = true
        errorMessage = nil

        // Store selected album (or create a virtual "All Photos" album)
        if let album = album {
            selectedAlbum = album
        } else {
            // Create a virtual "All Photos" album for navigation
            let allPhotosCount = photoService.countAllPhotos()
            selectedAlbum = AlbumModel(
                id: "all-photos",
                name: "All Photos",
                photoCount: allPhotosCount,
                assetCollection: nil,
                albumType: .smartAlbum
            )
        }

        // Fetch photos (PhotoKit handles threading internally)
        let fetchedPhotos: [PhotoAssetModel]
        if let album = selectedAlbum, album.assetCollection != nil {
            // Fetch from specific album with asset collection
            fetchedPhotos = photoService.fetchPhotos(from: album)
        } else {
            // No album or virtual "All Photos" album - fetch all photos
            fetchedPhotos = photoService.fetchAllPhotos()
        }

        photos = fetchedPhotos
        stats.totalPhotos = photos.count
        currentIndex = 0
        isFinishedEarly = false

        isLoading = false
    }

    func loadVideosOnly() async {
        isLoading = true
        errorMessage = nil

        // Fetch videos
        let fetchedVideos = photoService.fetchVideosOnly()

        // Create a virtual "Videos" album
        selectedAlbum = AlbumModel(
            id: "videos-only",
            name: "Videos",
            photoCount: fetchedVideos.count,
            assetCollection: nil,
            albumType: .smartAlbum
        )

        photos = fetchedVideos
        stats.totalPhotos = photos.count
        currentIndex = 0
        isFinishedEarly = false

        isLoading = false
    }

    func loadBurstsOnly() async {
        isLoading = true
        errorMessage = nil

        // Fetch bursts
        let fetchedBursts = photoService.fetchBurstsOnly()

        // Create a virtual "Bursts" album
        selectedAlbum = AlbumModel(
            id: "bursts-only",
            name: "Bursts",
            photoCount: fetchedBursts.count,
            assetCollection: nil,
            albumType: .smartAlbum
        )

        photos = fetchedBursts
        stats.totalPhotos = photos.count
        currentIndex = 0
        isFinishedEarly = false

        isLoading = false
    }

    func loadScreenshotsOnly() async {
        isLoading = true
        errorMessage = nil

        // Fetch screenshots
        let fetchedScreenshots = photoService.fetchScreenshotsOnly()

        // Create a virtual "Screenshots" album
        selectedAlbum = AlbumModel(
            id: "screenshots-only",
            name: "Screenshots",
            photoCount: fetchedScreenshots.count,
            assetCollection: nil,
            albumType: .smartAlbum
        )

        photos = fetchedScreenshots
        stats.totalPhotos = photos.count
        currentIndex = 0
        isFinishedEarly = false

        isLoading = false
    }

    func loadLargestFiles() async {
        isLoading = true
        errorMessage = nil

        // Fetch largest files
        let fetchedFiles = photoService.fetchLargestFiles()

        // Create a virtual "Large Files" album
        selectedAlbum = AlbumModel(
            id: "large-files",
            name: "Large Files",
            photoCount: fetchedFiles.count,
            assetCollection: nil,
            albumType: .smartAlbum
        )

        photos = fetchedFiles
        stats.totalPhotos = photos.count
        currentIndex = 0
        isFinishedEarly = false

        isLoading = false
    }

    // MARK: - Swipe Actions

    func swipeLeft() {
        processAction(.delete)
    }

    func swipeRight() {
        processAction(.keep)
    }

    func swipeUpOrDown() {
        processAction(.skip)
    }

    func processAction(_ action: PhotoAction) {
        guard let photo = currentPhoto else { return }

        // Store action in history for undo
        actionHistory.append((photo: photo, action: action, index: currentIndex))

        // Limit history size
        if actionHistory.count > maxUndoHistory {
            actionHistory.removeFirst()
        }

        // Update photo state
        photos[currentIndex].isProcessed = true
        photos[currentIndex].action = action

        // Update statistics
        updateStats(for: action, asset: photo.asset)

        // Add to deletion queue if delete action
        if action == .delete {
            deletionQueue.append(photo.asset)
        }

        // Move to next photo
        moveToNextPhoto()
    }

    // MARK: - Navigation

    private func moveToNextPhoto() {
        if isReviewingSkipped {
            // When reviewing skipped photos, move to next skipped photo
            moveToNextSkippedPhoto()
        } else {
            // Find next unprocessed photo
            var nextIndex = currentIndex + 1

            while nextIndex < photos.count && photos[nextIndex].isProcessed {
                nextIndex += 1
            }

            currentIndex = nextIndex
        }
    }

    // MARK: - Statistics

    private func updateStats(for action: PhotoAction, asset: PHAsset) {
        stats.photosReviewed += 1

        switch action {
        case .keep:
            stats.photosKept += 1
        case .delete:
            stats.photosDeleted += 1
            stats.estimatedSpaceFreed += photoService.estimateAssetSize(asset)
        case .skip:
            stats.photosSkipped += 1
        }
    }

    private func revertStats(for action: PhotoAction, asset: PHAsset) {
        stats.photosReviewed -= 1

        switch action {
        case .keep:
            stats.photosKept -= 1
        case .delete:
            stats.photosDeleted -= 1
            stats.estimatedSpaceFreed -= photoService.estimateAssetSize(asset)
        case .skip:
            stats.photosSkipped -= 1
        }
    }

    // MARK: - Undo

    func undoLastAction() {
        guard let last = actionHistory.popLast() else { return }

        // Remove from deletion queue if it was a delete action
        if last.action == .delete {
            if let index = deletionQueue.firstIndex(where: { $0.localIdentifier == last.photo.asset.localIdentifier }) {
                deletionQueue.remove(at: index)
            }
        }

        // Revert statistics
        revertStats(for: last.action, asset: last.photo.asset)

        // Mark photo as unprocessed
        photos[last.index].isProcessed = false
        photos[last.index].action = nil

        // Move back to that photo
        currentIndex = last.index
    }

    // MARK: - Batch Deletion

    func executeBatchDeletion() async throws {
        guard !deletionQueue.isEmpty else { return }

        isDeletingBatch = true
        errorMessage = nil

        do {
            try await deletionService.deletePhotos(deletionQueue)
            deletionQueue.removeAll()
            isDeletingBatch = false
        } catch {
            errorMessage = "Failed to delete photos: \(error.localizedDescription)"
            isDeletingBatch = false
            throw error
        }
    }

    func cancelDeletion() {
        deletionQueue.removeAll()
    }

    // MARK: - Finish Early

    func finishEarly() {
        isFinishedEarly = true
        isReviewingSkipped = false
    }

    // MARK: - Reset

    func resetSession() {
        photos.removeAll()
        currentIndex = 0
        stats = SessionStats()
        deletionQueue.removeAll()
        actionHistory.removeAll()
        errorMessage = nil
        selectedAlbum = nil
        isFinishedEarly = false
        showAlbumSelection = false
        isReviewingSkipped = false
    }

    // MARK: - Review Skipped Photos

    func reviewSkippedPhotos() {
        // Enable review skipped mode
        isReviewingSkipped = true
        isFinishedEarly = false

        // Find first skipped photo
        currentIndex = -1  // Start before first index
        moveToNextSkippedPhoto()
    }

    private func moveToNextSkippedPhoto() {
        // Always search from the next index to move past current photo
        var nextIndex = currentIndex + 1

        while nextIndex < photos.count {
            if photos[nextIndex].action == .skip && photos[nextIndex].isProcessed {
                currentIndex = nextIndex
                return
            }
            nextIndex += 1
        }

        // No more skipped photos - exit review mode and complete session
        currentIndex = photos.count
        isReviewingSkipped = false
    }
}

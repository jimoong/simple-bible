import Foundation
import SwiftUI

// MARK: - Download State
enum DownloadState: Equatable {
    case idle
    case downloading(progress: Double, currentBook: String, currentChapter: Int)
    case completed
    case failed(error: String)
    case paused(progress: Double)
    
    var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }
    
    var progress: Double {
        switch self {
        case .downloading(let progress, _, _): return progress
        case .paused(let progress): return progress
        case .completed: return 1.0
        default: return 0.0
        }
    }
}

// MARK: - Download Manager
@MainActor
@Observable
final class DownloadManager {
    static let shared = DownloadManager()
    
    // MARK: - State
    var downloadStates: [String: DownloadState] = [:]  // translationId -> state
    var downloadedTranslations: Set<String> = []
    var translationSizes: [String: Int64] = [:]  // translationId -> size in bytes
    
    // Current active download
    private var activeDownloadTask: Task<Void, Never>?
    private var shouldCancelDownload = false
    
    private init() {
        Task {
            await refreshDownloadedTranslations()
        }
    }
    
    // MARK: - Public Methods
    
    /// Start downloading a translation
    func startDownload(translationId: String) {
        guard downloadStates[translationId]?.isDownloading != true else { return }
        
        shouldCancelDownload = false
        downloadStates[translationId] = .downloading(progress: 0, currentBook: "", currentChapter: 0)
        
        activeDownloadTask = Task {
            await downloadTranslation(translationId: translationId)
        }
    }
    
    /// Cancel active download
    func cancelDownload(translationId: String) {
        shouldCancelDownload = true
        activeDownloadTask?.cancel()
        
        if case .downloading(let progress, _, _) = downloadStates[translationId] {
            downloadStates[translationId] = .paused(progress: progress)
        }
    }
    
    /// Resume a paused download
    func resumeDownload(translationId: String) {
        guard case .paused = downloadStates[translationId] else { return }
        startDownload(translationId: translationId)
    }
    
    /// Delete a downloaded translation
    func deleteDownload(translationId: String) async {
        do {
            try await OfflineStorageService.shared.deleteTranslation(translationId)
            downloadedTranslations.remove(translationId)
            downloadStates[translationId] = .idle
            translationSizes.removeValue(forKey: translationId)
        } catch {
            print("❌ Failed to delete translation: \(error)")
        }
    }
    
    /// Refresh the list of downloaded translations
    func refreshDownloadedTranslations() async {
        let downloaded = await OfflineStorageService.shared.getDownloadedTranslations()
        downloadedTranslations = Set(downloaded)
        
        // Update download states and sizes
        for translationId in downloaded {
            let progress = await OfflineStorageService.shared.downloadProgress(for: translationId)
            let size = await OfflineStorageService.shared.getStorageSize(for: translationId)
            
            translationSizes[translationId] = size
            
            if progress >= 1.0 {
                downloadStates[translationId] = .completed
            }
            // Don't auto-set "paused" state for auto-cached chapters
            // Only keep existing downloading/paused states from user-initiated downloads
        }
    }
    
    /// Get download state for a translation
    func getState(for translationId: String) -> DownloadState {
        downloadStates[translationId] ?? .idle
    }
    
    /// Check if a translation is available offline
    func isAvailableOffline(translationId: String) -> Bool {
        downloadedTranslations.contains(translationId)
    }
    
    /// Get total storage used
    func getTotalStorageSize() async -> Int64 {
        await OfflineStorageService.shared.getTotalStorageSize()
    }
    
    // MARK: - Private Download Logic
    
    private func downloadTranslation(translationId: String) async {
        let books = BibleData.books
        let totalChapters = OfflineStorageService.shared.getTotalChapterCount()
        var downloadedCount = 0
        
        // Check already downloaded chapters
        for book in books {
            for chapter in 1...book.chapterCount {
                if await OfflineStorageService.shared.hasChapter(
                    translationId: translationId,
                    bookId: book.id,
                    chapter: chapter
                ) {
                    downloadedCount += 1
                }
            }
        }
        
        let startingProgress = Double(downloadedCount) / Double(totalChapters)
        
        // Start downloading
        for book in books {
            for chapter in 1...book.chapterCount {
                // Check for cancellation
                if shouldCancelDownload || Task.isCancelled {
                    let progress = Double(downloadedCount) / Double(totalChapters)
                    downloadStates[translationId] = .paused(progress: progress)
                    return
                }
                
                // Skip if already downloaded
                if await OfflineStorageService.shared.hasChapter(
                    translationId: translationId,
                    bookId: book.id,
                    chapter: chapter
                ) {
                    continue
                }
                
                // Update state
                let progress = Double(downloadedCount) / Double(totalChapters)
                downloadStates[translationId] = .downloading(
                    progress: progress,
                    currentBook: book.nameKr,
                    currentChapter: chapter
                )
                
                // Download chapter
                do {
                    let verses = try await fetchChapterFromAPI(
                        translationId: translationId,
                        book: book,
                        chapter: chapter
                    )
                    
                    // Clean Strong's numbers before saving
                    let cleanedVerses = verses.map { $0.cleaned }
                    
                    try await OfflineStorageService.shared.saveChapter(
                        translationId: translationId,
                        bookId: book.id,
                        chapter: chapter,
                        verses: cleanedVerses
                    )
                    
                    downloadedCount += 1
                    
                    // Small delay to avoid rate limiting
                    try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms
                    
                } catch {
                    print("⚠️ Failed to download \(book.id) \(chapter): \(error)")
                    // Continue with next chapter instead of failing
                }
            }
        }
        
        // Mark as completed
        downloadStates[translationId] = .completed
        downloadedTranslations.insert(translationId)
        
        // Update size
        let size = await OfflineStorageService.shared.getStorageSize(for: translationId)
        translationSizes[translationId] = size
        
        print("✅ Download completed for \(translationId)")
    }
    
    /// Fetch chapter directly from bolls.life API
    private func fetchChapterFromAPI(translationId: String, book: BibleBook, chapter: Int) async throws -> [OfflineVerse] {
        guard let bookNum = Constants.bookNumbers[book.apiName] else {
            throw BibleAPIError.invalidURL
        }
        
        let urlString = "https://bolls.life/get-chapter/\(translationId)/\(bookNum)/\(chapter)/"
        guard let url = URL(string: urlString) else {
            throw BibleAPIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BibleAPIError.noData
        }
        
        return try JSONDecoder().decode([OfflineVerse].self, from: data)
    }
}

// MARK: - Download Info Model
struct DownloadInfo: Identifiable {
    let id: String  // translationId
    let name: String
    let language: String
    let state: DownloadState
    let size: Int64?
    
    var sizeString: String {
        guard let size = size else { return "" }
        return OfflineStorageService.shared.formatSize(size)
    }
}

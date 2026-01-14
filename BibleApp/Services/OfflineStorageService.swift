import Foundation

// MARK: - Offline Storage Service
/// Manages local storage of Bible translations for offline access
actor OfflineStorageService {
    static let shared = OfflineStorageService()
    
    private let fileManager = FileManager.default
    
    private init() {
        // Ensure base directory exists
        createBaseDirectoryIfNeeded()
    }
    
    // MARK: - Directory Management
    
    /// Base directory for offline Bible data
    private var baseDirectory: URL {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("OfflineBibles", isDirectory: true)
    }
    
    /// Directory for a specific translation
    private func translationDirectory(for translationId: String) -> URL {
        baseDirectory.appendingPathComponent(translationId, isDirectory: true)
    }
    
    /// File path for a specific chapter
    private func chapterFilePath(translationId: String, bookId: String, chapter: Int) -> URL {
        translationDirectory(for: translationId)
            .appendingPathComponent("\(bookId)_\(chapter).json")
    }
    
    private func createBaseDirectoryIfNeeded() {
        let url = baseDirectory
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    private func createTranslationDirectoryIfNeeded(for translationId: String) {
        let url = translationDirectory(for: translationId)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Save Chapter
    
    /// Save chapter verses to local storage
    func saveChapter(translationId: String, bookId: String, chapter: Int, verses: [OfflineVerse]) async throws {
        createTranslationDirectoryIfNeeded(for: translationId)
        
        let filePath = chapterFilePath(translationId: translationId, bookId: bookId, chapter: chapter)
        let data = try JSONEncoder().encode(verses)
        try data.write(to: filePath)
    }
    
    // MARK: - Load Chapter
    
    /// Load chapter verses from local storage
    func loadChapter(translationId: String, bookId: String, chapter: Int) async -> [OfflineVerse]? {
        let filePath = chapterFilePath(translationId: translationId, bookId: bookId, chapter: chapter)
        
        guard fileManager.fileExists(atPath: filePath.path),
              let data = try? Data(contentsOf: filePath),
              let verses = try? JSONDecoder().decode([OfflineVerse].self, from: data) else {
            return nil
        }
        
        return verses
    }
    
    /// Check if a chapter exists locally
    func hasChapter(translationId: String, bookId: String, chapter: Int) async -> Bool {
        let filePath = chapterFilePath(translationId: translationId, bookId: bookId, chapter: chapter)
        return fileManager.fileExists(atPath: filePath.path)
    }
    
    /// Delete a chapter from local storage
    func deleteChapter(translationId: String, bookId: String, chapter: Int) async {
        let filePath = chapterFilePath(translationId: translationId, bookId: bookId, chapter: chapter)
        try? fileManager.removeItem(at: filePath)
    }
    
    // MARK: - Translation Download Status
    
    /// Get download progress for a translation (0.0 - 1.0)
    func downloadProgress(for translationId: String) async -> Double {
        let totalChapters = getTotalChapterCount()
        let downloadedChapters = await getDownloadedChapterCount(for: translationId)
        
        guard totalChapters > 0 else { return 0 }
        return Double(downloadedChapters) / Double(totalChapters)
    }
    
    /// Get downloaded chapter count for a translation
    func getDownloadedChapterCount(for translationId: String) async -> Int {
        let directory = translationDirectory(for: translationId)
        
        guard let contents = try? fileManager.contentsOfDirectory(atPath: directory.path) else {
            return 0
        }
        
        return contents.filter { $0.hasSuffix(".json") }.count
    }
    
    /// Get total chapter count in the Bible (1189 chapters)
    nonisolated func getTotalChapterCount() -> Int {
        BibleData.books.reduce(0) { $0 + $1.chapterCount }
    }
    
    /// Check if a translation is fully downloaded
    func isFullyDownloaded(translationId: String) async -> Bool {
        let progress = await downloadProgress(for: translationId)
        return progress >= 1.0
    }
    
    /// Get list of downloaded translations
    func getDownloadedTranslations() async -> [String] {
        guard let contents = try? fileManager.contentsOfDirectory(atPath: baseDirectory.path) else {
            return []
        }
        
        var downloadedIds: [String] = []
        
        for item in contents {
            let itemPath = baseDirectory.appendingPathComponent(item)
            var isDirectory: ObjCBool = false
            
            if fileManager.fileExists(atPath: itemPath.path, isDirectory: &isDirectory),
               isDirectory.boolValue {
                // Check if it has any chapters
                let chapterCount = await getDownloadedChapterCount(for: item)
                if chapterCount > 0 {
                    downloadedIds.append(item)
                }
            }
        }
        
        return downloadedIds
    }
    
    // MARK: - Delete Translation
    
    /// Delete all downloaded data for a translation
    func deleteTranslation(_ translationId: String) async throws {
        let directory = translationDirectory(for: translationId)
        
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
    }
    
    /// Delete all offline data
    func deleteAllDownloads() async throws {
        if fileManager.fileExists(atPath: baseDirectory.path) {
            try fileManager.removeItem(at: baseDirectory)
            createBaseDirectoryIfNeeded()
        }
    }
    
    // MARK: - Storage Size
    
    /// Get total storage size used by offline data (in bytes)
    func getTotalStorageSize() async -> Int64 {
        return getDirectorySize(url: baseDirectory)
    }
    
    /// Get storage size for a specific translation (in bytes)
    func getStorageSize(for translationId: String) async -> Int64 {
        let directory = translationDirectory(for: translationId)
        return getDirectorySize(url: directory)
    }
    
    private func getDirectorySize(url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: []) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        return totalSize
    }
    
    /// Format bytes to human readable string
    nonisolated func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Offline Verse Model
struct OfflineVerse: Codable {
    let pk: Int
    let verse: Int
    let text: String
    
    /// Create a cleaned version of this verse (removes Strong's numbers)
    var cleaned: OfflineVerse {
        OfflineVerse(pk: pk, verse: verse, text: Self.cleanText(text))
    }
    
    /// Clean text by removing markup tags (Strong's numbers, footnotes, etc.)
    static func cleanText(_ text: String) -> String {
        text.replacingOccurrences(of: "<S>\\d+</S>", with: "", options: .regularExpression)  // Strong's numbers
            .replacingOccurrences(of: "<sup>.*?</sup>", with: "", options: .regularExpression)  // Footnotes
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)  // Any remaining HTML tags
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}

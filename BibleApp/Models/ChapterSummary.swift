//
//  ChapterSummary.swift
//  BibleApp
//
//  Chapter-level summaries, titles, and key events
//

import Foundation

struct ChapterKeyEvent: Codable, Identifiable {
    let verse: Int
    let eventKo: String
    let eventEn: String
    
    var id: Int { verse }
    
    func event(for language: LanguageMode) -> String {
        language == .kr ? eventKo : eventEn
    }
}

struct ChapterSummary: Codable, Identifiable {
    let chapter: Int
    let titleKo: String
    let titleEn: String
    let summaryKo: String
    let summaryEn: String
    let messageKo: String
    let messageEn: String
    let keyEvents: [ChapterKeyEvent]
    let timelineYear: String?
    
    var id: Int { chapter }
    
    func title(for language: LanguageMode) -> String {
        language == .kr ? titleKo : titleEn
    }
    
    func summary(for language: LanguageMode) -> String {
        language == .kr ? summaryKo : summaryEn
    }
    
    func message(for language: LanguageMode) -> String {
        language == .kr ? messageKo : messageEn
    }
}

struct BookChapterData: Codable {
    let bookId: String           // Matches BibleBook.id (e.g., "genesis")
    let bookNumber: Int          // 1-66
    let bookNameKo: String
    let bookNameEn: String
    let chapters: [ChapterSummary]
    
    func chapterSummary(for chapter: Int) -> ChapterSummary? {
        chapters.first { $0.chapter == chapter }
    }
}

// MARK: - Chapter Data Manager
class ChapterDataManager {
    static let shared = ChapterDataManager()
    
    private var cache: [String: BookChapterData] = [:]
    
    private init() {}
    
    /// Load chapter data for a specific book
    func loadBookData(bookId: String) -> BookChapterData? {
        // Check cache first
        if let cached = cache[bookId] {
            return cached
        }
        
        // Try to load from bundle
        // Note: ChapterSummaries is added as a folder reference in the project
        guard let url = Bundle.main.url(forResource: "chapters_\(bookId)", withExtension: "json", subdirectory: "ChapterSummaries"),
              let data = try? Data(contentsOf: url) else {
            print("ChapterDataManager: Could not find chapters_\(bookId).json in ChapterSummaries folder")
            return nil
        }
        
        do {
            let bookData = try JSONDecoder().decode(BookChapterData.self, from: data)
            cache[bookId] = bookData
            return bookData
        } catch {
            print("ChapterDataManager: Failed to decode chapters_\(bookId).json - \(error)")
            return nil
        }
    }
    
    /// Get chapter summary for a specific book and chapter
    func chapterSummary(bookId: String, chapter: Int) -> ChapterSummary? {
        loadBookData(bookId: bookId)?.chapterSummary(for: chapter)
    }
    
    /// Clear the cache
    func clearCache() {
        cache.removeAll()
    }
}

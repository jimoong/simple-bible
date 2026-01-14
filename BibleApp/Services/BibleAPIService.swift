import Foundation

enum BibleAPIError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse data: \(error.localizedDescription)"
        case .noData:
            return "No data received"
        }
    }
}

// Response model for bolls.life Korean API
struct BollsVerseResponse: Codable {
    let pk: Int
    let verse: Int
    let text: String
    
    /// Clean text by removing markup tags (Strong's numbers, footnotes, etc.)
    var cleanText: String {
        text.replacingOccurrences(of: "<S>\\d+</S>", with: "", options: .regularExpression)  // Strong's numbers
            .replacingOccurrences(of: "<sup>.*?</sup>", with: "", options: .regularExpression)  // Footnotes
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)  // Any remaining HTML tags
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}

actor BibleAPIService {
    static let shared = BibleAPIService()
    
    private let session: URLSession
    private var cache: [String: [BibleVerse]] = [:]
    
    // Current translations (loaded from UserDefaults)
    private var primaryTranslationId: String = "KRV"
    private var secondaryTranslationId: String = "KJV"
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)
        
        // Load saved translations
        loadSavedTranslations()
    }
    
    private func loadSavedTranslations() {
        primaryTranslationId = UserDefaults.standard.string(forKey: "primaryTranslationId") ?? "KRV"
        secondaryTranslationId = UserDefaults.standard.string(forKey: "secondaryTranslationId") ?? "KJV"
    }
    
    /// Reload translations from UserDefaults (call when settings change)
    func reloadTranslations() {
        loadSavedTranslations()
        cache.removeAll() // Clear cache when translations change
        // print("🔄 Translations reloaded: Primary=\(primaryTranslationId), Secondary=\(secondaryTranslationId)")
    }
    
    /// Fetch a chapter and return verses with primary and secondary translation text
    func fetchChapter(book: BibleBook, chapter: Int) async throws -> [BibleVerse] {
        // Reload translations to ensure we have latest settings
        loadSavedTranslations()
        
        let cacheKey = "\(book.id)-\(chapter)-\(primaryTranslationId)-\(secondaryTranslationId)"
        
        // Check cache first
        if let cached = cache[cacheKey] {
            return cached
        }
        
        // Fetch primary translation (bolls.life)
        let primaryVerses = await fetchTranslationChapterSafe(
            book: book, 
            chapter: chapter, 
            translationId: primaryTranslationId
        )
        
        // Fetch secondary translation (bolls.life)
        let secondaryVerses = await fetchTranslationChapterSafe(
            book: book, 
            chapter: chapter, 
            translationId: secondaryTranslationId
        )
        
        // Uncomment for verbose logging:
        // print("📖 Primary (\(primaryTranslationId)): \(primaryVerses.count), Secondary (\(secondaryTranslationId)): \(secondaryVerses.count)")
        
        // Determine which has more verses (use as base)
        // Filter out verse 0 (title/superscription) as it causes offset issues in navigation
        let allVerseNumbers = Set(primaryVerses.map { $0.verse } + secondaryVerses.map { $0.verse })
            .filter { $0 > 0 }  // Exclude verse 0 (titles/superscriptions)
            .sorted()
        
        // Debug: Log verse numbers for troubleshooting Numbers navigation issue
        #if DEBUG
        if book.id == "numbers" && chapter == 1 {
            let primaryNums = primaryVerses.map { $0.verse }.sorted()
            let secondaryNums = secondaryVerses.map { $0.verse }.sorted()
            let around23 = allVerseNumbers.filter { $0 >= 20 && $0 <= 26 }
            
            print("\n" + String(repeating: "=", count: 50))
            print("🔍 NUMBERS 1 DEBUG")
            print(String(repeating: "=", count: 50))
            print("Primary (\(primaryTranslationId)): \(primaryNums.count) verses, first=\(primaryNums.first ?? -1)")
            print("Secondary (\(secondaryTranslationId)): \(secondaryNums.count) verses, first=\(secondaryNums.first ?? -1)")
            print("Verses 20-26: \(around23)")
            if !allVerseNumbers.contains(23) {
                print("⚠️ VERSE 23 IS MISSING!")
            }
            if primaryNums.first == 0 || secondaryNums.first == 0 {
                print("⚠️ Had verse 0 (filtered out)")
            }
            print(String(repeating: "=", count: 50) + "\n")
        }
        #endif
        
        // Build verse list
        var verses: [BibleVerse] = []
        
        for verseNum in allVerseNumbers {
            let primaryText = primaryVerses.first(where: { $0.verse == verseNum })?.cleanText ?? ""
            let secondaryText = secondaryVerses.first(where: { $0.verse == verseNum })?.cleanText ?? ""
            
            // Determine which text goes to textKr and textEn based on primary language
            let primaryLangCode = UserDefaults.standard.string(forKey: "primaryLanguageCode") ?? "ko"
            
            let verse: BibleVerse
            if primaryLangCode == "ko" {
                // Korean is primary
                verse = BibleVerse(
                    bookName: book.nameEn,
                    chapter: chapter,
                    verseNumber: verseNum,
                    textEn: secondaryText,
                    textKr: primaryText
                )
            } else {
                // Non-Korean is primary - put in textKr slot (will be shown as primary)
                // Secondary (usually English) goes in textEn
                verse = BibleVerse(
                    bookName: book.nameEn,
                    chapter: chapter,
                    verseNumber: verseNum,
                    textEn: secondaryText,
                    textKr: primaryText  // Primary text uses textKr slot
                )
            }
            verses.append(verse)
        }
        
        cache[cacheKey] = verses
        return verses
    }
    
    // MARK: - Generic Translation Fetch (bolls.life)
    private func fetchTranslationChapterSafe(book: BibleBook, chapter: Int, translationId: String) async -> [BollsVerseResponse] {
        // 1. Try offline storage first
        if let offlineVerses = await OfflineStorageService.shared.loadChapter(
            translationId: translationId,
            bookId: book.id,
            chapter: chapter
        ) {
            // print("📱 \(translationId): Loaded \(offlineVerses.count) verses from offline storage")
            return offlineVerses.map { BollsVerseResponse(pk: $0.pk, verse: $0.verse, text: $0.text) }
        }
        
        // 2. Fetch from network
        do {
            let verses = try await fetchTranslationChapter(book: book, chapter: chapter, translationId: translationId)
            
            // 3. Save to offline storage for future use (with cleaned text)
            Task {
                let offlineVerses = verses.map { OfflineVerse(pk: $0.pk, verse: $0.verse, text: $0.cleanText) }
                try? await OfflineStorageService.shared.saveChapter(
                    translationId: translationId,
                    bookId: book.id,
                    chapter: chapter,
                    verses: offlineVerses
                )
            }
            
            return verses
        } catch {
            print("✗ \(translationId) failed for '\(book.nameEn)': \(error.localizedDescription)")
            return []
        }
    }
    
    private func fetchTranslationChapter(book: BibleBook, chapter: Int, translationId: String) async throws -> [BollsVerseResponse] {
        guard let bookNum = Constants.bookNumbers[book.apiName] else {
            print("⚠️ No book number mapping for '\(book.apiName)'")
            throw BibleAPIError.invalidURL
        }
        
        // bolls.life API: https://bolls.life/get-chapter/{TRANSLATION}/{bookNum}/{chapter}/
        let urlString = "https://bolls.life/get-chapter/\(translationId)/\(bookNum)/\(chapter)/"
        guard let url = URL(string: urlString) else {
            throw BibleAPIError.invalidURL
        }
        
        // print("🔍 \(translationId): \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BibleAPIError.noData
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("✗ \(translationId): HTTP \(httpResponse.statusCode)")
            throw BibleAPIError.noData
        }
        
        let verses = try JSONDecoder().decode([BollsVerseResponse].self, from: data)
        // print("✓ \(translationId): \(verses.count) verses (network)")
        
        return verses
    }
    
    /// Clear the cache
    func clearCache() {
        cache.removeAll()
        print("🗑 Cache cleared")
    }
    
    /// Clear cache for a specific chapter (including offline storage)
    func clearChapterCache(book: BibleBook, chapter: Int) async {
        // Clear in-memory cache entries for this chapter
        let keysToRemove = cache.keys.filter { $0.hasPrefix("\(book.id)-\(chapter)-") }
        for key in keysToRemove {
            cache.removeValue(forKey: key)
        }
        
        // Clear offline storage for both translations
        loadSavedTranslations()
        await OfflineStorageService.shared.deleteChapter(
            translationId: primaryTranslationId,
            bookId: book.id,
            chapter: chapter
        )
        await OfflineStorageService.shared.deleteChapter(
            translationId: secondaryTranslationId,
            bookId: book.id,
            chapter: chapter
        )
        
        print("🗑 Cleared cache for \(book.id) chapter \(chapter)")
    }
    
    /// Prefetch adjacent chapters
    func prefetchAdjacentChapters(book: BibleBook, currentChapter: Int) async {
        if currentChapter < book.chapterCount {
            _ = try? await fetchChapter(book: book, chapter: currentChapter + 1)
        }
        if currentChapter > 1 {
            _ = try? await fetchChapter(book: book, chapter: currentChapter - 1)
        }
        if book.isSingleChapter, let nextBook = BibleData.nextBook(after: book) {
            _ = try? await fetchChapter(book: nextBook, chapter: 1)
        }
    }
}

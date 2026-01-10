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
}

actor BibleAPIService {
    static let shared = BibleAPIService()
    
    private let session: URLSession
    private var cache: [String: [BibleVerse]] = [:]
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.requestCachePolicy = .returnCacheDataElseLoad
        self.session = URLSession(configuration: config)
    }
    
    /// Fetch a chapter and return verses with both English and Korean text
    func fetchChapter(book: BibleBook, chapter: Int) async throws -> [BibleVerse] {
        let cacheKey = "\(book.id)-\(chapter)"
        
        // Check cache first
        if let cached = cache[cacheKey] {
            return cached
        }
        
        // Fetch English (primary API)
        let englishVerses = try await fetchEnglishChapter(book: book, chapter: chapter)
        
        // Fetch Korean (bolls.life)
        let koreanVerses = await fetchKoreanChapterSafe(book: book, chapter: chapter)
        
        // Deduplicate English verses by verse number (KJV API returns footnotes as separate entries)
        // Keep only the first (main) entry for each verse number, skip footnotes
        var englishByNumber: [Int: String] = [:]
        for enVerse in englishVerses {
            let verseNum = enVerse.verseNumber
            // Only keep the first entry for each verse number (main text, not footnotes)
            if englishByNumber[verseNum] == nil {
                englishByNumber[verseNum] = enVerse.text
            }
        }
        
        print("📖 English: \(englishByNumber.count) unique verses (from \(englishVerses.count) entries), Korean: \(koreanVerses.count)")
        
        // Merge English and Korean verses
        var verses: [BibleVerse] = []
        
        // Sort by verse number to maintain order
        let sortedVerseNumbers = englishByNumber.keys.sorted()
        
        for verseNum in sortedVerseNumbers {
            let enText = englishByNumber[verseNum] ?? ""
            
            // Find matching Korean verse
            let krText = koreanVerses.first(where: { $0.verse == verseNum })?.text ?? ""
            
            let verse = BibleVerse(
                bookName: book.nameEn,
                chapter: chapter,
                verseNumber: verseNum,
                textEn: enText,
                textKr: krText
            )
            verses.append(verse)
        }
        
        cache[cacheKey] = verses
        return verses
    }
    
    // MARK: - English (wldeh/bible-api)
    private func fetchEnglishChapter(book: BibleBook, chapter: Int) async throws -> [APIVerseData] {
        guard let url = Constants.API.chapterURL(version: "en-kjv", book: book.apiName, chapter: chapter) else {
            print("⚠️ Invalid URL for '\(book.nameEn)' chapter \(chapter)")
            throw BibleAPIError.invalidURL
        }
        
        print("🔍 EN: \(url.absoluteString)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("✗ EN: No HTTP response for '\(book.nameEn)'")
            throw BibleAPIError.noData
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            print("✗ EN: HTTP \(httpResponse.statusCode) for '\(book.nameEn)' ch.\(chapter)")
            throw BibleAPIError.noData
        }
        
        do {
            let chapterResponse = try JSONDecoder().decode(APIChapterResponse.self, from: data)
            print("✓ EN: \(chapterResponse.data.count) verses")
            return chapterResponse.data
        } catch {
            print("✗ EN decode error for '\(book.nameEn)': \(error)")
            throw BibleAPIError.decodingError(error)
        }
    }
    
    // MARK: - Korean (bolls.life API)
    private func fetchKoreanChapterSafe(book: BibleBook, chapter: Int) async -> [BollsVerseResponse] {
        do {
            return try await fetchKoreanChapter(book: book, chapter: chapter)
        } catch {
            print("✗ KR failed for '\(book.nameEn)' (apiName: \(book.apiName)): \(error.localizedDescription)")
            return []
        }
    }
    
    private func fetchKoreanChapter(book: BibleBook, chapter: Int) async throws -> [BollsVerseResponse] {
        guard let bookNum = Constants.bookNumbers[book.apiName] else {
            print("⚠️ No book number mapping for '\(book.apiName)'")
            throw BibleAPIError.invalidURL
        }
        
        // bolls.life API: https://bolls.life/get-chapter/KRV/{bookNum}/{chapter}/
        let urlString = "https://bolls.life/get-chapter/KRV/\(bookNum)/\(chapter)/"
        guard let url = URL(string: urlString) else {
            throw BibleAPIError.invalidURL
        }
        
        print("🔍 KR: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BibleAPIError.noData
        }
        
        print("📡 KR status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw BibleAPIError.noData
        }
        
        // Debug: print first 200 chars of response
        if let preview = String(data: data, encoding: .utf8)?.prefix(200) {
            print("📄 KR preview: \(preview)")
        }
        
        let verses = try JSONDecoder().decode([BollsVerseResponse].self, from: data)
        print("✓ KR: \(verses.count) verses")
        
        return verses
    }
    
    /// Clear the cache
    func clearCache() {
        cache.removeAll()
        print("🗑 Cache cleared")
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

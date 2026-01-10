import Foundation

struct BibleVerse: Identifiable, Equatable {
    let id: String
    let bookName: String
    let chapter: Int
    let verseNumber: Int
    let textEn: String
    let textKr: String
    
    init(bookName: String, chapter: Int, verseNumber: Int, textEn: String, textKr: String) {
        self.id = "\(bookName.lowercased())-\(chapter)-\(verseNumber)"
        self.bookName = bookName
        self.chapter = chapter
        self.verseNumber = verseNumber
        self.textEn = textEn
        self.textKr = textKr
    }
    
    func text(for language: LanguageMode) -> String {
        let rawText: String
        switch language {
        case .en: rawText = textEn
        case .kr: rawText = textKr.isEmpty ? textEn : textKr
        }
        // Remove pilcrow (¶) and trim whitespace
        var cleaned = rawText.replacingOccurrences(of: "¶", with: "").trimmingCharacters(in: .whitespaces)
        
        // For English, remove KJV inline footnotes/marginal notes
        // Patterns: "2.14 toward...: or, text" or "1.5 text...: Heb. text"
        if language == .en {
            // Remove patterns like "X.Y word...: explanation" (KJV footnote format)
            // This catches verse references followed by partial text and colon explanations
            if let range = cleaned.range(of: #"\d+\.\d+\s+[^:]+:.*$"#, options: .regularExpression) {
                cleaned = String(cleaned[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            }
        }
        
        return cleaned
    }
}

// API Response models - matching the ACTUAL API structure
// Response: {"data": [{"book": "John", "chapter": "1", "verse": "1", "text": "..."}, ...]}

struct APIChapterResponse: Codable {
    let data: [APIVerseData]
}

struct APIVerseData: Codable {
    let book: String
    let chapter: String
    let verse: String
    let text: String
    
    var verseNumber: Int {
        Int(verse) ?? 0
    }
    
    var chapterNumber: Int {
        Int(chapter) ?? 0
    }
}

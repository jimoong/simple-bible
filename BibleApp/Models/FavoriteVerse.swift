//
//  FavoriteVerse.swift
//  BibleApp
//
//  Model for storing favorite (liked) verses with notes
//

import Foundation

struct FavoriteVerse: Identifiable, Codable, Equatable {
    let id: String
    let bookId: String
    let bookNameEn: String
    let bookNameKr: String
    let chapter: Int
    let verseNumber: Int
    let textEn: String
    let textKr: String
    let likedAt: Date
    var note: String?
    
    /// Create a FavoriteVerse from a BibleVerse
    init(from verse: BibleVerse, book: BibleBook, note: String? = nil) {
        self.id = "\(book.id)_\(verse.chapter)_\(verse.verseNumber)"
        self.bookId = book.id
        self.bookNameEn = book.nameEn
        self.bookNameKr = book.nameKr
        self.chapter = verse.chapter
        self.verseNumber = verse.verseNumber
        self.textEn = verse.textEn
        self.textKr = verse.textKr
        self.likedAt = Date()
        self.note = note
    }
    
    /// Create with all parameters (for decoding or editing)
    init(
        id: String,
        bookId: String,
        bookNameEn: String,
        bookNameKr: String,
        chapter: Int,
        verseNumber: Int,
        textEn: String,
        textKr: String,
        likedAt: Date,
        note: String?
    ) {
        self.id = id
        self.bookId = bookId
        self.bookNameEn = bookNameEn
        self.bookNameKr = bookNameKr
        self.chapter = chapter
        self.verseNumber = verseNumber
        self.textEn = textEn
        self.textKr = textKr
        self.likedAt = likedAt
        self.note = note
    }
    
    // MARK: - Computed Properties
    
    /// Get book name for a specific language mode
    func bookName(for language: LanguageMode) -> String {
        switch language {
        case .en: return bookNameEn
        case .kr: return bookNameKr
        }
    }
    
    /// Get verse text for a specific language mode
    func text(for language: LanguageMode) -> String {
        switch language {
        case .en: return textEn
        case .kr: return textKr.isEmpty ? textEn : textKr
        }
    }
    
    /// Formatted reference string (e.g., "창세기 1장 1절" or "Genesis 1:1")
    func referenceText(for language: LanguageMode) -> String {
        let name = bookName(for: language)
        switch language {
        case .kr:
            return "\(name) \(chapter)장 \(verseNumber)절"
        case .en:
            return "\(name) \(chapter):\(verseNumber)"
        }
    }
    
    /// Short reference (e.g., "창 1:1" or "Gen 1:1")
    func shortReference(for language: LanguageMode) -> String {
        // Get abbreviation from BibleData if available
        if let book = BibleData.book(by: bookId) {
            let abbrev = book.abbreviation(for: language)
            return "\(abbrev) \(chapter):\(verseNumber)"
        }
        // Fallback
        return "\(chapter):\(verseNumber)"
    }
}

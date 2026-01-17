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
    let verseNumberEnd: Int?  // For passages (e.g., verses 1-3), nil for single verse
    let verseNumbers: [Int]?  // Actual verse numbers for non-continuous passages (e.g., [1, 3, 5])
    let textEn: String
    let textKr: String
    let likedAt: Date
    var note: String?
    
    /// Check if this is a passage (multiple verses)
    var isPassage: Bool {
        verseNumberEnd != nil && verseNumberEnd! > verseNumber
    }
    
    /// Check if this passage has non-continuous verses
    var isNonContinuous: Bool {
        guard let numbers = verseNumbers, numbers.count > 1 else { return false }
        let sorted = numbers.sorted()
        guard let first = sorted.first, let last = sorted.last else { return false }
        return sorted != Array(first...last)
    }
    
    /// Create a FavoriteVerse from a BibleVerse (single verse)
    init(from verse: BibleVerse, book: BibleBook, note: String? = nil) {
        self.id = "\(book.id)_\(verse.chapter)_\(verse.verseNumber)"
        self.bookId = book.id
        self.bookNameEn = book.nameEn
        self.bookNameKr = book.nameKr
        self.chapter = verse.chapter
        self.verseNumber = verse.verseNumber
        self.verseNumberEnd = nil
        self.verseNumbers = nil
        self.textEn = verse.textEn
        self.textKr = verse.textKr
        self.likedAt = Date()
        self.note = note
    }
    
    /// Create a FavoriteVerse from multiple verses (passage)
    init(from verses: [BibleVerse], book: BibleBook, note: String? = nil) {
        let sortedVerses = verses.sorted { $0.verseNumber < $1.verseNumber }
        guard let first = sortedVerses.first, let last = sortedVerses.last else {
            // Fallback to empty (shouldn't happen)
            self.id = "\(book.id)_0_0"
            self.bookId = book.id
            self.bookNameEn = book.nameEn
            self.bookNameKr = book.nameKr
            self.chapter = 0
            self.verseNumber = 0
            self.verseNumberEnd = nil
            self.verseNumbers = nil
            self.textEn = ""
            self.textKr = ""
            self.likedAt = Date()
            self.note = note
            return
        }
        
        let numbers = sortedVerses.map { $0.verseNumber }
        let isContinuous = numbers == Array(first.verseNumber...last.verseNumber)
        
        // ID format: for non-continuous, use comma-separated numbers
        if isContinuous {
            self.id = "\(book.id)_\(first.chapter)_\(first.verseNumber)-\(last.verseNumber)"
        } else {
            self.id = "\(book.id)_\(first.chapter)_\(numbers.map { String($0) }.joined(separator: ","))"
        }
        
        self.bookId = book.id
        self.bookNameEn = book.nameEn
        self.bookNameKr = book.nameKr
        self.chapter = first.chapter
        self.verseNumber = first.verseNumber
        self.verseNumberEnd = sortedVerses.count > 1 ? last.verseNumber : nil
        self.verseNumbers = sortedVerses.count > 1 ? numbers : nil
        
        // Join with space for continuous, paragraph break for non-continuous
        let separator = isContinuous ? " " : "\n\n"
        self.textEn = sortedVerses.map { $0.textEn }.joined(separator: separator)
        self.textKr = sortedVerses.map { $0.textKr }.joined(separator: separator)
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
        verseNumberEnd: Int? = nil,
        verseNumbers: [Int]? = nil,
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
        self.verseNumberEnd = verseNumberEnd
        self.verseNumbers = verseNumbers
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
        
        // Check for non-continuous verses
        if isNonContinuous, let numbers = verseNumbers {
            switch language {
            case .kr:
                return "\(name) \(chapter)장 \(numbers.map { String($0) }.joined(separator: ", "))절"
            case .en:
                return "\(name) \(chapter):\(numbers.map { String($0) }.joined(separator: ", "))"
            }
        }
        
        // Continuous range or single verse
        switch language {
        case .kr:
            if let end = verseNumberEnd, end > verseNumber {
                return "\(name) \(chapter)장 \(verseNumber)-\(end)절"
            }
            return "\(name) \(chapter)장 \(verseNumber)절"
        case .en:
            if let end = verseNumberEnd, end > verseNumber {
                return "\(name) \(chapter):\(verseNumber)-\(end)"
            }
            return "\(name) \(chapter):\(verseNumber)"
        }
    }
    
    /// Short reference (e.g., "창 1:1" or "Gen 1:1")
    func shortReference(for language: LanguageMode) -> String {
        // Get abbreviation from BibleData if available
        if let book = BibleData.book(by: bookId) {
            let abbrev = book.abbreviation(for: language)
            
            // Check for non-continuous verses
            if isNonContinuous, let numbers = verseNumbers {
                return "\(abbrev) \(chapter):\(numbers.map { String($0) }.joined(separator: ", "))"
            }
            
            if let end = verseNumberEnd, end > verseNumber {
                return "\(abbrev) \(chapter):\(verseNumber)-\(end)"
            }
            return "\(abbrev) \(chapter):\(verseNumber)"
        }
        
        // Fallback
        if isNonContinuous, let numbers = verseNumbers {
            return "\(chapter):\(numbers.map { String($0) }.joined(separator: ", "))"
        }
        if let end = verseNumberEnd, end > verseNumber {
            return "\(chapter):\(verseNumber)-\(end)"
        }
        return "\(chapter):\(verseNumber)"
    }
}

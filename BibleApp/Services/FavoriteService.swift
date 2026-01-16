//
//  FavoriteService.swift
//  BibleApp
//
//  Manages favorite verses with UserDefaults persistence
//

import Foundation
import SwiftUI

// Notification for when a verse is saved as favorite
extension Notification.Name {
    static let verseFavoriteSaved = Notification.Name("verseFavoriteSaved")
}

@MainActor
@Observable
final class FavoriteService {
    static let shared = FavoriteService()
    
    private let userDefaultsKey = "favoriteVerses"
    
    // All favorite verses, sorted by likedAt (newest first)
    private(set) var favorites: [FavoriteVerse] = []
    
    private init() {
        loadFavorites()
    }
    
    // MARK: - Public API
    
    /// Check if a verse is already favorited
    func isFavorite(bookId: String, chapter: Int, verseNumber: Int) -> Bool {
        let key = makeKey(bookId: bookId, chapter: chapter, verseNumber: verseNumber)
        return favorites.contains { $0.id == key }
    }
    
    /// Check if a BibleVerse is already favorited
    func isFavorite(verse: BibleVerse, book: BibleBook) -> Bool {
        return isFavorite(bookId: book.id, chapter: verse.chapter, verseNumber: verse.verseNumber)
    }
    
    /// Check if a verse is favorited by book name (English)
    func isFavorite(bookName: String, chapter: Int, verseNumber: Int) -> Bool {
        // Find book by English name
        guard let book = BibleData.books.first(where: { $0.nameEn == bookName }) else {
            return false
        }
        return isFavorite(bookId: book.id, chapter: chapter, verseNumber: verseNumber)
    }
    
    /// Get a favorite by its key
    func getFavorite(bookId: String, chapter: Int, verseNumber: Int) -> FavoriteVerse? {
        let key = makeKey(bookId: bookId, chapter: chapter, verseNumber: verseNumber)
        return favorites.first { $0.id == key }
    }
    
    /// Add a verse to favorites
    func addFavorite(verse: BibleVerse, book: BibleBook, note: String? = nil) {
        // Don't add if already exists
        guard !isFavorite(verse: verse, book: book) else { return }
        
        let favorite = FavoriteVerse(from: verse, book: book, note: note)
        favorites.insert(favorite, at: 0) // Add to beginning (newest first)
        saveFavorites()
        HapticManager.shared.success()
        
        // Post notification with verse info for highlight animation
        NotificationCenter.default.post(
            name: .verseFavoriteSaved,
            object: nil,
            userInfo: [
                "bookName": verse.bookName,
                "chapter": verse.chapter,
                "verseNumber": verse.verseNumber
            ]
        )
    }
    
    /// Remove a verse from favorites
    func removeFavorite(bookId: String, chapter: Int, verseNumber: Int) {
        let key = makeKey(bookId: bookId, chapter: chapter, verseNumber: verseNumber)
        favorites.removeAll { $0.id == key }
        saveFavorites()
        HapticManager.shared.lightClick()
    }
    
    /// Remove a verse from favorites using BibleVerse
    func removeFavorite(verse: BibleVerse, book: BibleBook) {
        removeFavorite(bookId: book.id, chapter: verse.chapter, verseNumber: verse.verseNumber)
    }
    
    /// Remove a favorite by its ID
    func removeFavorite(id: String) {
        favorites.removeAll { $0.id == id }
        saveFavorites()
        HapticManager.shared.lightClick()
    }
    
    /// Toggle favorite status for a verse
    func toggleFavorite(verse: BibleVerse, book: BibleBook) -> Bool {
        if isFavorite(verse: verse, book: book) {
            removeFavorite(verse: verse, book: book)
            return false
        } else {
            addFavorite(verse: verse, book: book)
            return true
        }
    }
    
    /// Update note for a favorite verse
    func updateNote(id: String, note: String?) {
        guard let index = favorites.firstIndex(where: { $0.id == id }) else { return }
        
        // Create updated favorite with new note
        let oldFavorite = favorites[index]
        let updatedFavorite = FavoriteVerse(
            id: oldFavorite.id,
            bookId: oldFavorite.bookId,
            bookNameEn: oldFavorite.bookNameEn,
            bookNameKr: oldFavorite.bookNameKr,
            chapter: oldFavorite.chapter,
            verseNumber: oldFavorite.verseNumber,
            textEn: oldFavorite.textEn,
            textKr: oldFavorite.textKr,
            likedAt: oldFavorite.likedAt,
            note: note?.isEmpty == true ? nil : note
        )
        
        favorites[index] = updatedFavorite
        saveFavorites()
    }
    
    /// Get all favorites sorted by date (newest first)
    func getAllFavorites() -> [FavoriteVerse] {
        return favorites.sorted { $0.likedAt > $1.likedAt }
    }
    
    /// Get favorites count
    var count: Int {
        favorites.count
    }
    
    /// Check if there are any favorites
    var hasFavorites: Bool {
        !favorites.isEmpty
    }
    
    /// Clear all favorites (for app reset)
    func clearAll() {
        favorites.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - Private Helpers
    
    private func makeKey(bookId: String, chapter: Int, verseNumber: Int) -> String {
        return "\(bookId)_\(chapter)_\(verseNumber)"
    }
    
    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode([FavoriteVerse].self, from: data) else {
            return
        }
        // Sort by likedAt (newest first)
        favorites = decoded.sorted { $0.likedAt > $1.likedAt }
    }
    
    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}

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
    static let verseFavoriteRemoved = Notification.Name("verseFavoriteRemoved")
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
    
    /// Check if a verse is already favorited (either as single verse or part of a passage)
    func isFavorite(bookId: String, chapter: Int, verseNumber: Int) -> Bool {
        // Check for exact single verse match
        let key = makeKey(bookId: bookId, chapter: chapter, verseNumber: verseNumber)
        if favorites.contains(where: { $0.id == key }) {
            return true
        }
        
        // Check if verse is part of any saved passage
        return favorites.contains { favorite in
            guard favorite.bookId == bookId && favorite.chapter == chapter else { return false }
            
            // If non-continuous with explicit verse numbers, check the array
            if let numbers = favorite.verseNumbers {
                return numbers.contains(verseNumber)
            }
            
            // Otherwise check continuous range
            return favorite.verseNumber <= verseNumber &&
                   (favorite.verseNumberEnd ?? favorite.verseNumber) >= verseNumber
        }
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
    
    /// Add multiple verses as a single passage to favorites
    func addFavoritePassage(verses: [BibleVerse], book: BibleBook, note: String? = nil) {
        guard !verses.isEmpty else { return }
        
        // For single verse, use regular addFavorite
        if verses.count == 1, let verse = verses.first {
            addFavorite(verse: verse, book: book, note: note)
            return
        }
        
        let favorite = FavoriteVerse(from: verses, book: book, note: note)
        
        // Check if this exact passage already exists
        if favorites.contains(where: { $0.id == favorite.id }) { return }
        
        favorites.insert(favorite, at: 0) // Add to beginning (newest first)
        saveFavorites()
        HapticManager.shared.success()
        
        // Post notification for each verse in the passage for highlight animation
        for verse in verses {
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
    }
    
    /// Remove a verse from favorites
    func removeFavorite(bookId: String, chapter: Int, verseNumber: Int) {
        // Get book name before removing
        guard let favorite = favorites.first(where: { 
            $0.bookId == bookId && $0.chapter == chapter && $0.verseNumber == verseNumber 
        }) else { return }
        
        let key = makeKey(bookId: bookId, chapter: chapter, verseNumber: verseNumber)
        favorites.removeAll { $0.id == key }
        saveFavorites()
        HapticManager.shared.lightClick()
        
        // Post notification for removed favorite
        postRemovalNotification(for: favorite)
    }
    
    /// Remove a verse from favorites using BibleVerse
    func removeFavorite(verse: BibleVerse, book: BibleBook) {
        removeFavorite(bookId: book.id, chapter: verse.chapter, verseNumber: verse.verseNumber)
    }
    
    /// Remove a favorite by its ID
    func removeFavorite(id: String) {
        // Get favorite info before removing
        guard let favorite = favorites.first(where: { $0.id == id }) else { return }
        
        favorites.removeAll { $0.id == id }
        saveFavorites()
        HapticManager.shared.lightClick()
        
        // Post notification for removed favorite
        postRemovalNotification(for: favorite)
    }
    
    /// Post notification for a removed favorite (handles both single verses and passages)
    private func postRemovalNotification(for favorite: FavoriteVerse) {
        // For passages, post notification for each verse
        if let verseNumbers = favorite.verseNumbers {
            for verseNum in verseNumbers {
                NotificationCenter.default.post(
                    name: .verseFavoriteRemoved,
                    object: nil,
                    userInfo: [
                        "bookNameEn": favorite.bookNameEn,
                        "chapter": favorite.chapter,
                        "verseNumber": verseNum
                    ]
                )
            }
        } else if let endVerse = favorite.verseNumberEnd, endVerse > favorite.verseNumber {
            // Continuous passage
            for verseNum in favorite.verseNumber...endVerse {
                NotificationCenter.default.post(
                    name: .verseFavoriteRemoved,
                    object: nil,
                    userInfo: [
                        "bookNameEn": favorite.bookNameEn,
                        "chapter": favorite.chapter,
                        "verseNumber": verseNum
                    ]
                )
            }
        } else {
            // Single verse
            NotificationCenter.default.post(
                name: .verseFavoriteRemoved,
                object: nil,
                userInfo: [
                    "bookNameEn": favorite.bookNameEn,
                    "chapter": favorite.chapter,
                    "verseNumber": favorite.verseNumber
                ]
            )
        }
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

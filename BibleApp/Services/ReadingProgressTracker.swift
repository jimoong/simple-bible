//
//  ReadingProgressTracker.swift
//  BibleApp
//
//  Tracks which chapters have been marked as read
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class ReadingProgressTracker {
    static let shared = ReadingProgressTracker()
    
    private let userDefaultsKey = "readChapters"
    
    // Set of "bookId_chapter" keys that have been read
    private(set) var readChapters: Set<String> = []
    
    private init() {
        loadReadChapters()
    }
    
    // MARK: - Public API
    
    /// Check if a specific chapter has been read
    func isChapterRead(bookId: String, chapter: Int) -> Bool {
        let key = makeKey(bookId: bookId, chapter: chapter)
        return readChapters.contains(key)
    }
    
    /// Check if all chapters of a book have been read
    func isBookFullyRead(book: BibleBook) -> Bool {
        for chapter in 1...book.chapterCount {
            if !isChapterRead(bookId: book.id, chapter: chapter) {
                return false
            }
        }
        return true
    }
    
    /// Get the count of read chapters for a book
    func readChapterCount(for book: BibleBook) -> Int {
        var count = 0
        for chapter in 1...book.chapterCount {
            if isChapterRead(bookId: book.id, chapter: chapter) {
                count += 1
            }
        }
        return count
    }
    
    /// Mark a chapter as read
    func markAsRead(bookId: String, chapter: Int) {
        let key = makeKey(bookId: bookId, chapter: chapter)
        readChapters.insert(key)
        saveReadChapters()
    }
    
    /// Mark a chapter as unread
    func markAsUnread(bookId: String, chapter: Int) {
        let key = makeKey(bookId: bookId, chapter: chapter)
        readChapters.remove(key)
        saveReadChapters()
    }
    
    /// Toggle read state for a chapter
    func toggleReadState(bookId: String, chapter: Int) {
        if isChapterRead(bookId: bookId, chapter: chapter) {
            markAsUnread(bookId: bookId, chapter: chapter)
        } else {
            markAsRead(bookId: bookId, chapter: chapter)
        }
    }
    
    /// Clear all read progress
    func clearAll() {
        readChapters.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - Private Helpers
    
    private func makeKey(bookId: String, chapter: Int) -> String {
        return "\(bookId)_\(chapter)"
    }
    
    private func loadReadChapters() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let chapters = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return
        }
        readChapters = chapters
    }
    
    private func saveReadChapters() {
        if let data = try? JSONEncoder().encode(readChapters) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}

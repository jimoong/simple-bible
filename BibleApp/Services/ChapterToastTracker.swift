//
//  ChapterToastTracker.swift
//  BibleApp
//
//  Tracks which chapter toasts have been seen to avoid showing them repeatedly
//

import Foundation

class ChapterToastTracker {
    static let shared = ChapterToastTracker()
    
    private let userDefaultsKey = "seenChapterToasts"
    private let expirationInterval: TimeInterval = 6 * 30 * 24 * 60 * 60 // ~6 months in seconds
    
    private init() {
        // Clean up expired entries on init
        cleanupExpiredEntries()
    }
    
    /// Check if toast should be shown for a chapter
    func shouldShowToast(bookId: String, chapter: Int) -> Bool {
        let key = makeKey(bookId: bookId, chapter: chapter)
        let seenDates = getSeenDates()
        
        guard let seenDate = seenDates[key] else {
            return true // Never seen
        }
        
        // Check if it's been more than 6 months
        let elapsed = Date().timeIntervalSince(seenDate)
        return elapsed > expirationInterval
    }
    
    /// Mark a chapter toast as seen
    func markAsSeen(bookId: String, chapter: Int) {
        let key = makeKey(bookId: bookId, chapter: chapter)
        var seenDates = getSeenDates()
        seenDates[key] = Date()
        saveSeenDates(seenDates)
    }
    
    /// Clear all seen records (for testing)
    func clearAll() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - Private Helpers
    
    private func makeKey(bookId: String, chapter: Int) -> String {
        return "\(bookId)_\(chapter)"
    }
    
    private func getSeenDates() -> [String: Date] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let dates = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return [:]
        }
        return dates
    }
    
    private func saveSeenDates(_ dates: [String: Date]) {
        if let data = try? JSONEncoder().encode(dates) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func cleanupExpiredEntries() {
        var seenDates = getSeenDates()
        let now = Date()
        
        seenDates = seenDates.filter { _, seenDate in
            now.timeIntervalSince(seenDate) < expirationInterval
        }
        
        saveSeenDates(seenDates)
    }
}

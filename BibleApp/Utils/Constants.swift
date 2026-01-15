import Foundation
import SwiftUI

enum Constants {
    
    // MARK: - Google Gemini API Configuration
    enum Gemini {
        /// API key loaded from Secrets.swift (gitignored)
        /// Get your key at: https://aistudio.google.com/app/apikey
        static let apiKey = Secrets.geminiKey
        
        /// Model to use
        static let model = "gemini-2.0-flash"  // Options: "gemini-2.0-flash", "gemini-1.5-pro", "gemini-1.5-flash"
        
        /// API endpoint
        static var apiURL: String {
            "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        }
    }
    
    enum API {
        // Primary API (English)
        static let primaryBaseURL = "https://cdn.jsdelivr.net/gh/wldeh/bible-api/bibles"
        
        // Korean API (getbible.net)
        static let koreanBaseURL = "https://getbible.net/v2"
        
        static func chapterURL(version: String, book: String, chapter: Int) -> URL? {
            URL(string: "\(primaryBaseURL)/\(version)/books/\(book)/chapters/\(chapter).json")
        }
        
        static func koreanChapterURL(book: String, chapter: Int) -> URL? {
            // getbible.net uses format: /korean/book/chapter.json
            // Book names need to be converted (e.g., "john" -> "43" for John which is 43rd book)
            URL(string: "\(koreanBaseURL)/korean/\(book)/\(chapter).json")
        }
    }
    
    // Book number mapping for bolls.life API (1-indexed)
    static let bookNumbers: [String: Int] = [
        "genesis": 1, "exodus": 2, "leviticus": 3, "numbers": 4, "deuteronomy": 5,
        "joshua": 6, "judges": 7, "ruth": 8, "1samuel": 9, "2samuel": 10,
        "1kings": 11, "2kings": 12, "1chronicles": 13, "2chronicles": 14,
        "ezra": 15, "nehemiah": 16, "esther": 17, "job": 18, "psalms": 19,
        "proverbs": 20, "ecclesiastes": 21, "songofsolomon": 22, "isaiah": 23,
        "jeremiah": 24, "lamentations": 25, "ezekiel": 26, "daniel": 27,
        "hosea": 28, "joel": 29, "amos": 30, "obadiah": 31, "jonah": 32,
        "micah": 33, "nahum": 34, "habakkuk": 35, "zephaniah": 36, "haggai": 37,
        "zechariah": 38, "malachi": 39, "matthew": 40, "mark": 41, "luke": 42,
        "john": 43, "acts": 44, "romans": 45, "1corinthians": 46, "2corinthians": 47,
        "galatians": 48, "ephesians": 49, "philippians": 50, "colossians": 51,
        "1thessalonians": 52, "2thessalonians": 53, "1timothy": 54, "2timothy": 55,
        "titus": 56, "philemon": 57, "hebrews": 58, "james": 59, "1peter": 60,
        "2peter": 61, "1john": 62, "2john": 63, "3john": 64, "jude": 65,
        "revelation": 66
    ]
}

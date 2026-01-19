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
    
    // MARK: - Debug / Testing
    
    /// Populate with mock data for testing
    func populateMockData() {
        // Clear existing favorites first
        clearAll()
        
        let mockFavorites: [(bookId: String, chapter: Int, verse: Int, textEn: String, textKr: String, daysAgo: Double, note: String?)] = [
            // 방금 전 (Just now)
            ("genesis", 1, 1, "In the beginning God created the heaven and the earth.", "태초에 하나님이 천지를 창조하시니라", 0.001, "모든 것의 시작. 하나님의 창조 사역의 첫 문장."),
            
            // 오늘 (Today)
            ("psalms", 23, 1, "The LORD is my shepherd; I shall not want.", "여호와는 나의 목자시니 내게 부족함이 없으리로다", 0.2, "가장 사랑하는 시편. 평안함을 느끼게 해주는 구절."),
            ("john", 3, 16, "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.", "하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니 이는 그를 믿는 자마다 멸망하지 않고 영생을 얻게 하려 하심이라", 0.3, nil),
            
            // 어제 (Yesterday)
            ("proverbs", 3, 5, "Trust in the LORD with all thine heart; and lean not unto thine own understanding.", "너는 마음을 다하여 여호와를 신뢰하고 네 명철을 의지하지 말라", 1.2, "신뢰와 겸손에 대한 교훈. 내 지혜가 아닌 하나님의 인도하심을 따르자."),
            ("romans", 8, 28, "And we know that all things work together for good to them that love God, to them who are the called according to his purpose.", "우리가 알거니와 하나님을 사랑하는 자 곧 그의 뜻대로 부르심을 입은 자들에게는 모든 것이 합력하여 선을 이루느니라", 1.5, nil),
            
            // 지난 주 (Last week)
            ("philippians", 4, 13, "I can do all things through Christ which strengtheneth me.", "내게 능력 주시는 자 안에서 내가 모든 것을 할 수 있느니라", 4, "힘들 때마다 되새기는 구절"),
            ("isaiah", 40, 31, "But they that wait upon the LORD shall renew their strength; they shall mount up with wings as eagles; they shall run, and not be weary; and they shall walk, and not faint.", "오직 여호와를 앙망하는 자는 새 힘을 얻으리니 독수리가 날개치며 올라감 같을 것이요 달음박질하여도 곤비하지 아니하겠고 걸어가도 피곤하지 아니하리로다", 5, "기다림의 아름다움. 인내하면 새 힘을 얻는다."),
            ("matthew", 6, 33, "But seek ye first the kingdom of God, and his righteousness; and all these things shall be added unto you.", "그런즉 너희는 먼저 그의 나라와 그의 의를 구하라 그리하면 이 모든 것을 너희에게 더하시리라", 6, nil),
            ("psalms", 119, 105, "Thy word is a lamp unto my feet, and a light unto my path.", "주의 말씀은 내 발에 등이요 내 길에 빛이니이다", 7, "말씀의 중요성을 일깨워주는 구절"),
            
            // 지난 달 (Last month)
            ("jeremiah", 29, 11, "For I know the thoughts that I think toward you, saith the LORD, thoughts of peace, and not of evil, to give you an expected end.", "여호와의 말씀이니라 너희를 향한 나의 생각을 내가 아나니 평안이요 재앙이 아니니라 너희에게 미래와 희망을 주는 것이니라", 15, "미래에 대한 희망과 확신"),
            ("1corinthians", 13, 4, "Charity suffereth long, and is kind; charity envieth not; charity vaunteth not itself, is not puffed up", "사랑은 오래 참고 사랑은 온유하며 시기하지 아니하며 사랑은 자랑하지 아니하며 교만하지 아니하며", 18, "사랑의 정의. 결혼식 때 읽었던 구절."),
            ("ephesians", 2, 8, "For by grace are ye saved through faith; and that not of yourselves: it is the gift of God", "너희는 그 은혜에 의하여 믿음으로 말미암아 구원을 받았으니 이것은 너희에게서 난 것이 아니요 하나님의 선물이라", 22, nil),
            ("hebrews", 11, 1, "Now faith is the substance of things hoped for, the evidence of things not seen.", "믿음은 바라는 것들의 실상이요 보이지 않는 것들의 증거니", 25, "믿음의 본질에 대한 깊은 통찰"),
            ("galatians", 5, 22, "But the fruit of the Spirit is love, joy, peace, longsuffering, gentleness, goodness, faith", "오직 성령의 열매는 사랑과 희락과 화평과 오래 참음과 자비와 양선과 충성과", 28, nil),
            
            // 6개월 전 (6 months ago)
            ("genesis", 12, 1, "Now the LORD had said unto Abram, Get thee out of thy country, and from thy kindred, and from thy father's house, unto a land that I will shew thee", "여호와께서 아브람에게 이르시되 너는 너의 고향과 친척과 아버지의 집을 떠나 내가 네게 보여 줄 땅으로 가라", 180, "아브라함의 부르심. 믿음의 여정의 시작."),
            ("exodus", 14, 14, "The LORD shall fight for you, and ye shall hold your peace.", "여호와께서 너희를 위하여 싸우시리니 너희는 잠잠할지니라", 185, "하나님이 싸우신다. 내가 할 일은 평안히 있는 것."),
            ("joshua", 1, 9, "Have not I commanded thee? Be strong and of a good courage; be not afraid, neither be thou dismayed: for the LORD thy God is with thee whithersoever thou goest.", "내가 네게 명령한 것이 아니냐 강하고 담대하라 두려워하지 말며 놀라지 말라 네가 어디로 가든지 네 하나님 여호와가 너와 함께 하느니라 하시니라", 190, nil),
            ("psalms", 46, 10, "Be still, and know that I am God: I will be exalted among the heathen, I will be exalted in the earth.", "이르시기를 너희는 가만히 있어 내가 하나님 됨을 알지어다 내가 뭇 나라 중에서 높임을 받으리라 내가 세계 중에서 높임을 받으리라 하시도다", 195, "고요함 속에서 하나님을 만나다"),
            
            // 작년 (Last year)
            ("genesis", 50, 20, "But as for you, ye thought evil against me; but God meant it unto good, to bring to pass, as it is this day, to save much people alive.", "당신들은 나를 해하려 하였으나 하나님은 그것을 선으로 바꾸사 오늘과 같이 많은 백성의 생명을 구원하게 하시려 하셨나니", 370, "요셉의 고백. 모든 일에 하나님의 선한 뜻이 있다."),
            ("daniel", 3, 17, "If it be so, our God whom we serve is able to deliver us from the burning fiery furnace, and he will deliver us out of thine hand, O king.", "왕이여 우리가 섬기는 하나님이 계시다면 우리를 맹렬히 타는 풀무불 가운데에서 능히 건져내시겠고 왕의 손에서도 건져내시리이다", 380, nil),
            ("micah", 6, 8, "He hath shewed thee, O man, what is good; and what doth the LORD require of thee, but to do justly, and to love mercy, and to walk humbly with thy God?", "사람아 주께서 선한 것이 무엇임을 네게 보이셨나니 여호와께서 네게 구하시는 것은 오직 정의를 행하며 인자를 사랑하며 겸손하게 네 하나님과 함께 행하는 것이 아니냐", 400, "하나님이 원하시는 삶의 모습"),
            ("revelation", 21, 4, "And God shall wipe away all tears from their eyes; and there shall be no more death, neither sorrow, nor crying, neither shall there be any more pain: for the former things are passed away.", "모든 눈물을 그 눈에서 닦아 주시니 다시는 사망이 없고 애통하는 것이나 곡하는 것이나 아픈 것이 다시 있지 아니하리니 처음 것들이 다 지나갔음이러라", 420, "천국에 대한 소망. 모든 아픔이 사라지는 그 날을 기다린다."),
        ]
        
        var newFavorites: [FavoriteVerse] = []
        
        for mock in mockFavorites {
            guard let book = BibleData.book(by: mock.bookId) else { continue }
            
            let likedAt = Date().addingTimeInterval(-mock.daysAgo * 24 * 60 * 60)
            let favorite = FavoriteVerse(
                id: "\(mock.bookId)_\(mock.chapter)_\(mock.verse)",
                bookId: mock.bookId,
                bookNameEn: book.nameEn,
                bookNameKr: book.nameKr,
                chapter: mock.chapter,
                verseNumber: mock.verse,
                verseNumberEnd: nil,
                verseNumbers: nil,
                textEn: mock.textEn,
                textKr: mock.textKr,
                likedAt: likedAt,
                note: mock.note
            )
            newFavorites.append(favorite)
        }
        
        // Sort by likedAt (newest first)
        favorites = newFavorites.sorted { $0.likedAt > $1.likedAt }
        saveFavorites()
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

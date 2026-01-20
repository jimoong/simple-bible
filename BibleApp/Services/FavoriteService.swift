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
    private let hasPopulatedRecommendedKey = "hasPopulatedRecommendedVerses"
    
    // All favorite verses, sorted by likedAt (newest first)
    private(set) var favorites: [FavoriteVerse] = []
    
    private init() {
        loadFavorites()
        populateRecommendedVersesIfNeeded()
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
    
    // MARK: - Recommended Verses (First Install)
    
    /// Populate recommended verses on first install
    private func populateRecommendedVersesIfNeeded() {
        // Check if already populated
        guard !UserDefaults.standard.bool(forKey: hasPopulatedRecommendedKey) else { return }
        
        // Mark as populated
        UserDefaults.standard.set(true, forKey: hasPopulatedRecommendedKey)
        
        // Use first install time for all recommended verses
        let installTime = Date()
        
        let recommendedVerses: [(bookId: String, chapter: Int, verse: Int, textEn: String, textKr: String, noteEn: String, noteKr: String)] = [
            // 희망과 격려 (Hope & Encouragement)
            ("philippians", 4, 13,
             "I can do all things through Christ which strengtheneth me.",
             "내게 능력 주시는 자 안에서 내가 모든 것을 할 수 있느니라",
             "Not by my own strength, but through Christ, all things are possible. Remember this promise in the difficulties you face today.",
             "나의 힘이 아닌, 주님 안에서 모든 것이 가능합니다. 오늘 직면한 어려움 속에서도 이 약속을 기억하세요."),
            
            ("jeremiah", 29, 11,
             "For I know the thoughts that I think toward you, saith the LORD, thoughts of peace, and not of evil, to give you an expected end.",
             "여호와의 말씀이니라 너희를 향한 나의 생각을 내가 아나니 평안이요 재앙이 아니니라 너희에게 미래와 희망을 주는 것이니라",
             "God already knows our future. Even in uncertain situations, we can trust His plans.",
             "하나님은 우리의 미래를 이미 알고 계십니다. 불확실한 상황에서도 그분의 계획을 신뢰할 수 있습니다."),
            
            ("romans", 8, 28,
             "And we know that all things work together for good to them that love God, to them who are the called according to his purpose.",
             "우리가 알거니와 하나님을 사랑하는 자 곧 그의 뜻대로 부르심을 입은 자들에게는 모든 것이 합력하여 선을 이루느니라",
             "Even things we don't understand right now will ultimately be used for good purposes.",
             "당장은 이해되지 않는 일들도, 결국 선한 목적을 위해 쓰임받게 됩니다."),
            
            ("isaiah", 40, 31,
             "But they that wait upon the LORD shall renew their strength; they shall mount up with wings as eagles; they shall run, and not be weary; and they shall walk, and not faint.",
             "오직 여호와를 앙망하는 자는 새 힘을 얻으리니 독수리가 날개치며 올라감 같을 것이요 달음박질하여도 곤비하지 아니하겠고 걸어가도 피곤하지 아니하리로다",
             "When we're tired, we don't just stop—we gain new strength when we look to the Lord.",
             "지칠 때 멈추는 것이 아니라, 주님을 바라볼 때 새 힘을 얻습니다."),
            
            // 사랑 (Love)
            ("john", 3, 16,
             "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
             "하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니 이는 그를 믿는 자마다 멸망하지 않고 영생을 얻게 하려 하심이라",
             "If the entire Bible were summarized in one verse, this would be it. The depth of God's love is felt here.",
             "성경 전체를 한 구절로 요약한다면 바로 이 말씀. 하나님 사랑의 깊이가 느껴집니다."),
            
            ("1john", 4, 19,
             "We love him, because he first loved us.",
             "우리가 사랑함은 그가 먼저 우리를 사랑하셨음이라",
             "The reason we can love is because we were loved first.",
             "우리가 사랑할 수 있는 이유는, 먼저 사랑받았기 때문입니다."),
            
            // 평안과 위로 (Peace & Comfort)
            ("psalms", 23, 1,
             "The LORD is my shepherd; I shall not want.",
             "여호와는 나의 목자시니 내게 부족함이 없으리로다",
             "Like a sheep following its shepherd, imagine a life guided without lack.",
             "목자의 인도를 따르는 양처럼, 부족함 없이 인도받는 삶을 상상해봅니다."),
            
            ("matthew", 11, 28,
             "Come unto me, all ye that labour and are heavy laden, and I will give you rest.",
             "수고하고 무거운 짐 진 자들아 다 내게로 오라 내가 너희를 쉬게 하리라",
             "An invitation to lay down heavy burdens. Rest is not laziness—it's grace.",
             "무거운 짐을 내려놓으라는 초대. 쉼은 게으름이 아니라 은혜입니다."),
            
            ("john", 14, 27,
             "Peace I leave with you, my peace I give unto you: not as the world giveth, give I unto you. Let not your heart be troubled, neither let it be afraid.",
             "평안을 너희에게 끼치노니 곧 나의 평안을 너희에게 주노라 내가 너희에게 주는 것은 세상이 주는 것과 같지 아니하니라 너희는 마음에 근심하지도 말고 두려워하지도 말라",
             "There is a true peace different from what the world gives.",
             "세상이 주는 평안과 다른, 진정한 평안이 있습니다."),
            
            ("psalms", 46, 10,
             "Be still, and know that I am God: I will be exalted among the heathen, I will be exalted in the earth.",
             "이르시기를 너희는 가만히 있어 내가 하나님 됨을 알지어다 내가 뭇 나라 중에서 높임을 받으리라 내가 세계 중에서 높임을 받으리라 하시도다",
             "We need time to stop our busy daily lives and quietly recognize God.",
             "바쁜 일상을 멈추고, 고요히 하나님을 인식하는 시간이 필요합니다."),
            
            // 믿음 (Faith)
            ("hebrews", 11, 1,
             "Now faith is the substance of things hoped for, the evidence of things not seen.",
             "믿음은 바라는 것들의 실상이요 보이지 않는 것들의 증거니",
             "Faith is being certain of what we cannot see. If we only believe what we can see, that's not faith.",
             "믿음은 보이지 않는 것을 확신하는 것. 눈에 보이는 것만 믿는다면 그것은 믿음이 아닙니다."),
            
            ("proverbs", 3, 5,
             "Trust in the LORD with all thine heart; and lean not unto thine own understanding.",
             "너는 마음을 다하여 여호와를 신뢰하고 네 명철을 의지하지 말라",
             "When we rely on God's wisdom rather than our own, the path opens up.",
             "내 지혜가 아닌 하나님의 지혜에 의지할 때, 길이 열립니다."),
            
            // 지혜 (Wisdom)
            ("proverbs", 1, 7,
             "The fear of the LORD is the beginning of knowledge: but fools despise wisdom and instruction.",
             "여호와를 경외하는 것이 지식의 근본이거늘 미련한 자는 지혜와 훈계를 멸시하느니라",
             "The starting point of all knowledge is fearing God.",
             "모든 지식의 출발점은 하나님을 경외하는 것입니다."),
            
            ("james", 1, 5,
             "If any of you lack wisdom, let him ask of God, that giveth to all men liberally, and upbraideth not; and it shall be given him.",
             "너희 중에 누구든지 지혜가 부족하거든 모든 사람에게 후히 주시고 꾸짖지 아니하시는 하나님께 구하라 그리하면 주시리라",
             "If you lack wisdom, ask. But ask in faith, without doubting.",
             "지혜가 부족하면 구하라. 단, 의심 없이 믿음으로 구해야 합니다."),
            
            // 용기와 힘 (Courage & Strength)
            ("joshua", 1, 9,
             "Have not I commanded thee? Be strong and of a good courage; be not afraid, neither be thou dismayed: for the LORD thy God is with thee whithersoever thou goest.",
             "내가 네게 명령한 것이 아니냐 강하고 담대하라 두려워하지 말며 놀라지 말라 네가 어디로 가든지 네 하나님 여호와가 너와 함께 하느니라 하시니라",
             "The reason we can be bold even in the face of fear is because God is with us.",
             "두려움 앞에서도 담대할 수 있는 이유는, 하나님이 함께하시기 때문입니다."),
            
            ("isaiah", 41, 10,
             "Fear thou not; for I am with thee: be not dismayed; for I am thy God: I will strengthen thee; yea, I will help thee; yea, I will uphold thee with the right hand of my righteousness.",
             "두려워하지 말라 내가 너와 함께 함이라 놀라지 말라 나는 네 하나님이 됨이라 내가 너를 굳세게 하리라 참으로 너를 도와 주리라 참으로 나의 의로운 오른손으로 너를 붙들리라",
             "\"Fear not\" is not a command, but comfort based on the promise that He is with us.",
             "\"두려워 말라\"는 명령이 아니라, 함께하신다는 약속에 기반한 위로입니다."),
            
            ("psalms", 27, 1,
             "The LORD is my light and my salvation; whom shall I fear? the LORD is the strength of my life; of whom shall I be afraid?",
             "여호와는 나의 빛이요 나의 구원이시니 내가 누구를 두려워하리요 여호와는 내 생명의 능력이시니 내가 누구를 무서워하리요",
             "Before God who is light, darkness loses its power.",
             "빛이신 하나님 앞에서 어둠은 힘을 잃습니다."),
            
            // 감사와 삶의 방향 (Gratitude & Purpose)
            ("1thessalonians", 5, 18,
             "In every thing give thanks: for this is the will of God in Christ Jesus concerning you.",
             "범사에 감사하라 이것이 그리스도 예수 안에서 너희를 향하신 하나님의 뜻이니라",
             "Give thanks in all circumstances. It's not easy, but gratitude changes our perspective.",
             "모든 상황에서 감사하라. 쉽지 않지만, 감사는 관점을 바꿉니다."),
            
            ("matthew", 6, 33,
             "But seek ye first the kingdom of God, and his righteousness; and all these things shall be added unto you.",
             "그런즉 너희는 먼저 그의 나라와 그의 의를 구하라 그리하면 이 모든 것을 너희에게 더하시리라",
             "A matter of priorities. When we seek what should be sought first, the rest follows.",
             "우선순위의 문제. 먼저 구할 것을 구하면 나머지는 따라옵니다."),
            
            ("micah", 6, 8,
             "He hath shewed thee, O man, what is good; and what doth the LORD require of thee, but to do justly, and to love mercy, and to walk humbly with thy God?",
             "사람아 주께서 선한 것이 무엇임을 네게 보이셨나니 여호와께서 네게 구하시는 것은 오직 정의를 행하며 인자를 사랑하며 겸손하게 네 하나님과 함께 행하는 것이 아니냐",
             "Justice, mercy, humility—the essence of the life God desires.",
             "공의, 인자, 겸손 - 하나님이 원하시는 삶의 핵심입니다."),
            
            // 은혜와 구원 (Grace & Salvation)
            ("ephesians", 2, 8,
             "For by grace are ye saved through faith; and that not of yourselves: it is the gift of God",
             "너희는 그 은혜에 의하여 믿음으로 말미암아 구원을 받았으니 이것은 너희에게서 난 것이 아니요 하나님의 선물이라",
             "Salvation is a gift, not our achievement. There's nothing to boast about.",
             "구원은 우리의 업적이 아닌 선물입니다. 자랑할 것이 없습니다."),
            
            ("romans", 6, 23,
             "For the wages of sin is death; but the gift of God is eternal life through Jesus Christ our Lord.",
             "죄의 삯은 사망이요 하나님의 은사는 그리스도 예수 우리 주 안에 있는 영생이니라",
             "The consequence of sin and God's gift—this stark contrast shows the essence of the gospel.",
             "죄의 결과와 하나님의 선물, 극명한 대조가 복음의 핵심을 보여줍니다."),
        ]
        
        var newRecommended: [FavoriteVerse] = []
        
        for verse in recommendedVerses {
            guard let book = BibleData.book(by: verse.bookId) else { continue }
            
            let favorite = FavoriteVerse(
                id: "\(verse.bookId)_\(verse.chapter)_\(verse.verse)",
                bookId: verse.bookId,
                bookNameEn: book.nameEn,
                bookNameKr: book.nameKr,
                chapter: verse.chapter,
                verseNumber: verse.verse,
                verseNumberEnd: nil,
                verseNumbers: nil,
                textEn: verse.textEn,
                textKr: verse.textKr,
                likedAt: installTime,
                note: verse.noteKr,  // Default to Korean note
                isRecommended: true
            )
            newRecommended.append(favorite)
        }
        
        // Add recommended verses to existing favorites
        favorites.append(contentsOf: newRecommended)
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

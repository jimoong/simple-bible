import Foundation

// MARK: - Bible Book Category
enum BibleBookCategory: String, CaseIterable {
    // Old Testament
    case law            // 율법 (창세기~신명기)
    case history        // 역사 (여호수아~에스더)
    case poetry         // 시와 지혜 (욥기~아가)
    case majorProphets  // 대예언 (이사야~다니엘)
    case minorProphets  // 소예언 (호세아~말라기)
    
    // New Testament
    case gospels        // 예수님 이야기 (마태~요한)
    case acts           // 교회사 (사도행전)
    case paulineEpistles // 바울의 편지 (로마서~빌레몬서)
    case generalEpistles // 공동 편지 (히브리서~유다서)
    case prophecy       // 마지막 때 (요한계시록)
    
    var isOldTestament: Bool {
        switch self {
        case .law, .history, .poetry, .majorProphets, .minorProphets:
            return true
        case .gospels, .acts, .paulineEpistles, .generalEpistles, .prophecy:
            return false
        }
    }
    
    var isNewTestament: Bool {
        !isOldTestament
    }
    
    func displayName(for language: LanguageMode) -> String {
        switch language {
        case .kr:
            switch self {
            case .law: return "율법"
            case .history: return "역사"
            case .poetry: return "시와 지혜"
            case .majorProphets: return "대예언"
            case .minorProphets: return "소예언"
            case .gospels: return "예수님 이야기"
            case .acts: return "교회사"
            case .paulineEpistles: return "바울의 편지"
            case .generalEpistles: return "공동 편지"
            case .prophecy: return "마지막 때"
            }
        case .en:
            switch self {
            case .law: return "Law"
            case .history: return "History"
            case .poetry: return "Poetry"
            case .majorProphets: return "Major Prophets"
            case .minorProphets: return "Minor Prophets"
            case .gospels: return "Gospels"
            case .acts: return "Acts"
            case .paulineEpistles: return "Paul's Letters"
            case .generalEpistles: return "Letters"
            case .prophecy: return "Prophecy"
            }
        }
    }
    
    static var oldTestamentCategories: [BibleBookCategory] {
        [.law, .history, .poetry, .majorProphets, .minorProphets]
    }
    
    static var newTestamentCategories: [BibleBookCategory] {
        [.gospels, .acts, .paulineEpistles, .generalEpistles, .prophecy]
    }
    
    /// Get the category for a book based on its order
    static func category(for bookOrder: Int) -> BibleBookCategory {
        switch bookOrder {
        case 1...5: return .law
        case 6...17: return .history
        case 18...22: return .poetry
        case 23...27: return .majorProphets
        case 28...39: return .minorProphets
        case 40...43: return .gospels
        case 44: return .acts
        case 45...57: return .paulineEpistles
        case 58...65: return .generalEpistles
        case 66: return .prophecy
        default: return .law
        }
    }
}

struct BibleBook: Identifiable, Equatable {
    let id: String
    let nameEn: String
    let nameKr: String
    let abbrEn: String      // Standard English abbreviation (e.g., "Gen", "Exo")
    let abbrKr: String      // Standard Korean abbreviation (e.g., "창", "출")
    let apiName: String
    let chapterCount: Int
    let order: Int
    
    var isSingleChapter: Bool {
        chapterCount == 1
    }
    
    var isOldTestament: Bool {
        order <= 39
    }
    
    var isNewTestament: Bool {
        order > 39
    }
    
    var category: BibleBookCategory {
        BibleBookCategory.category(for: order)
    }
    
    func name(for language: LanguageMode) -> String {
        switch language {
        case .en: return nameEn
        case .kr: return nameKr
        }
    }
    
    func abbreviation(for language: LanguageMode) -> String {
        switch language {
        case .en: return abbrEn
        case .kr: return abbrKr
        }
    }
}

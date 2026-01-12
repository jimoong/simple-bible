import Foundation

struct BibleBook: Identifiable, Equatable {
    let id: String
    let nameEn: String
    let nameKr: String
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
    
    func name(for language: LanguageMode) -> String {
        switch language {
        case .en: return nameEn
        case .kr: return nameKr
        }
    }
    
    func abbreviation(for language: LanguageMode) -> String {
        switch language {
        case .en: return String(nameEn.prefix(3)).uppercased()
        case .kr: return String(nameKr.prefix(2))
        }
    }
}

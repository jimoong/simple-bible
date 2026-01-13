import Foundation

enum ReadingMode: String, CaseIterable {
    case tap = "tap"
    case scroll = "scroll"
    
    var displayName: String {
        switch self {
        case .tap: return "Tap"
        case .scroll: return "Scroll"
        }
    }
    
    var displayNameKorean: String {
        switch self {
        case .tap: return "탭"
        case .scroll: return "스크롤"
        }
    }
    
    func displayName(for language: LanguageMode) -> String {
        switch language {
        case .kr: return displayNameKorean
        case .en: return displayName
        }
    }
}

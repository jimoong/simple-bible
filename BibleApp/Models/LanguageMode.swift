import Foundation

enum LanguageMode: String, CaseIterable {
    case en
    case kr
    
    var apiVersion: String {
        switch self {
        case .en: return "en-kjv"
        case .kr: return "ko-krv"  // Korean Revised Version
        }
    }
    
    var displayName: String {
        switch self {
        case .en: return "EN"
        case .kr: return "KR"
        }
    }
    
    var fullName: String {
        switch self {
        case .en: return "English"
        case .kr: return "한국어"
        }
    }
}

enum BookSortOrder: String, CaseIterable {
    case canonical
    case alphabetical
    
    var displayName: String {
        switch self {
        case .canonical: return "Canonical"
        case .alphabetical: return "A-Z"
        }
    }
}

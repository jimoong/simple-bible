import Foundation

enum LanguageMode: String, CaseIterable {
    case kr
    case en
    
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
    
    /// Get LanguageMode from a language code
    /// - Korean (ko) → .kr (UI in Korean)
    /// - All other languages → .en (UI falls back to English)
    static func from(languageCode: String) -> LanguageMode {
        switch languageCode.lowercased() {
        case "ko": return .kr
        default: return .en  // Fallback to English UI for all non-Korean languages
        }
    }
    
    /// Get the UI language mode based on primary translation
    /// Returns .kr only if primary translation is Korean, .en otherwise
    static var uiLanguage: LanguageMode {
        let primaryLangCode = UserDefaults.standard.string(forKey: "primaryLanguageCode") ?? "ko"
        return from(languageCode: primaryLangCode)
    }
}

// MARK: - Language Display Helper
struct LanguageDisplay {
    /// Get display code for a language code (e.g., "ko" -> "한", "en" -> "EN", "ja" -> "日")
    static func displayCode(for languageCode: String, inKorean: Bool) -> String {
        switch languageCode.lowercased() {
        case "ko": return inKorean ? "한" : "KR"
        case "en": return inKorean ? "영" : "EN"
        case "ja": return inKorean ? "일" : "JP"
        case "zh": return inKorean ? "중" : "ZH"
        case "es": return inKorean ? "스" : "ES"
        case "de": return inKorean ? "독" : "DE"
        case "fr": return inKorean ? "불" : "FR"
        case "pt": return inKorean ? "포" : "PT"
        default: return languageCode.uppercased().prefix(2).description
        }
    }
}

enum BookSortOrder: String, CaseIterable {
    case canonical
    case timeline
    case alphabetical
    
    var displayName: String {
        switch self {
        case .canonical: return "Canonical"
        case .alphabetical: return "A-Z"
        case .timeline: return "Time"
        }
    }
    
    func displayName(for language: LanguageMode) -> String {
        switch language {
        case .kr:
            switch self {
            case .canonical: return "목차순"
            case .alphabetical: return "ㄱㄴㄷ"
            case .timeline: return "연대순"
            }
        case .en:
            return displayName
        }
    }
    
    var icon: String {
        switch self {
        case .canonical: return "book.closed"
        case .alphabetical: return "textformat.abc"
        case .timeline: return "clock"
        }
    }
}

import Foundation

// MARK: - Bible Translation Model
struct BibleTranslation: Identifiable, Codable, Hashable {
    let id: String           // e.g., "KRV", "KJV"
    let name: String         // e.g., "Korean Revised Version"
    let shortName: String    // e.g., "개역한글", "KJV"
    let language: String     // e.g., "Korean", "English"
    let languageCode: String // e.g., "ko", "en"
    
    var displayName: String {
        "\(shortName) (\(id))"
    }
}

// MARK: - Selected Book (Translation) for Settings
struct SelectedBibleBook: Identifiable, Codable, Hashable {
    let id: String
    let translationId: String
    let translationName: String
    let languageCode: String
    
    init(translation: BibleTranslation) {
        self.id = translation.id
        self.translationId = translation.id
        self.translationName = translation.shortName
        self.languageCode = translation.languageCode
    }
}

// MARK: - API Response Models for bolls.life
struct BollsLanguageResponse: Codable {
    let language: String
    let code: String?
}

struct BollsTranslationResponse: Codable {
    let shortName: String
    let fullName: String
    let language: String
}

// MARK: - Default Translations
extension BibleTranslation {
    static let krv = BibleTranslation(
        id: "KRV",
        name: "Korean Revised Version",
        shortName: "개역한글",
        language: "Korean",
        languageCode: "ko"
    )
    
    static let kjv = BibleTranslation(
        id: "KJV",
        name: "King James Version",
        shortName: "KJV",
        language: "English",
        languageCode: "en"
    )
    
    static let esv = BibleTranslation(
        id: "ESV",
        name: "English Standard Version",
        shortName: "ESV",
        language: "English",
        languageCode: "en"
    )
    
    static let niv = BibleTranslation(
        id: "NIV",
        name: "New International Version",
        shortName: "NIV",
        language: "English",
        languageCode: "en"
    )
    
    // All available translations (hardcoded for now, can be fetched from API)
    static let allTranslations: [BibleTranslation] = [
        // Korean
        krv,
        BibleTranslation(id: "NKRV", name: "New Korean Revised Version", shortName: "개역개정", language: "Korean", languageCode: "ko"),
        BibleTranslation(id: "KLB", name: "Korean Living Bible", shortName: "현대인의성경", language: "Korean", languageCode: "ko"),
        
        // English
        kjv,
        esv,
        niv,
        BibleTranslation(id: "NASB", name: "New American Standard Bible", shortName: "NASB", language: "English", languageCode: "en"),
        BibleTranslation(id: "NLT", name: "New Living Translation", shortName: "NLT", language: "English", languageCode: "en"),
        BibleTranslation(id: "ASV", name: "American Standard Version", shortName: "ASV", language: "English", languageCode: "en"),
        BibleTranslation(id: "WEB", name: "World English Bible", shortName: "WEB", language: "English", languageCode: "en"),
        
        // Spanish
        BibleTranslation(id: "RVR1960", name: "Reina Valera 1960", shortName: "RVR60", language: "Spanish", languageCode: "es"),
        BibleTranslation(id: "NVI", name: "Nueva Versión Internacional", shortName: "NVI", language: "Spanish", languageCode: "es"),
        
        // Chinese
        BibleTranslation(id: "CUNP", name: "Chinese Union Version (Traditional)", shortName: "和合本", language: "Chinese", languageCode: "zh"),
        BibleTranslation(id: "CUNPS", name: "Chinese Union Version (Simplified)", shortName: "和合本(简)", language: "Chinese", languageCode: "zh"),
        
        // Japanese
        BibleTranslation(id: "JLB", name: "Japanese Living Bible", shortName: "リビングバイブル", language: "Japanese", languageCode: "ja"),
        
        // German
        BibleTranslation(id: "LUTH", name: "Luther Bible", shortName: "Luther", language: "German", languageCode: "de"),
        
        // French
        BibleTranslation(id: "LSG", name: "Louis Segond", shortName: "LSG", language: "French", languageCode: "fr"),
        
        // Portuguese
        BibleTranslation(id: "ARA", name: "Almeida Revista e Atualizada", shortName: "ARA", language: "Portuguese", languageCode: "pt"),
    ]
    
    static var translationsByLanguage: [String: [BibleTranslation]] {
        Dictionary(grouping: allTranslations, by: { $0.language })
    }
    
    static var availableLanguages: [String] {
        Array(Set(allTranslations.map { $0.language })).sorted()
    }
}

import Foundation

// MARK: - API Response Models
struct BollsTranslation: Codable, Identifiable {
    let translation: String      // e.g., "KRV", "KJV"
    let abbreviation: String?    // Short form
    let name: String?            // Full name
    let language: String         // e.g., "Korean", "English"
    
    var id: String { translation }
    
    var displayName: String {
        name ?? abbreviation ?? translation
    }
}

// MARK: - Translation Service
actor TranslationService {
    static let shared = TranslationService()
    
    private let session: URLSession
    private var cachedTranslations: [BollsTranslation]?
    private var lastFetchTime: Date?
    private let cacheExpiration: TimeInterval = 3600 * 24 // 24 hours
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
    }
    
    /// Fetch all available translations from bolls.life API
    func fetchAvailableTranslations() async -> [BollsTranslation] {
        // Return cached if valid
        if let cached = cachedTranslations,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheExpiration {
            return cached
        }
        
        // Try fetching from API
        do {
            let translations = try await fetchTranslationsFromAPI()
            cachedTranslations = translations
            lastFetchTime = Date()
            
            // Save to UserDefaults for offline access
            saveTranslationsToCache(translations)
            
            return translations
        } catch {
            print("⚠️ Failed to fetch translations: \(error.localizedDescription)")
            // Return cached or fallback
            return loadTranslationsFromCache() ?? getDefaultTranslations()
        }
    }
    
    private func fetchTranslationsFromAPI() async throws -> [BollsTranslation] {
        // bolls.life API endpoint for translations
        guard let url = URL(string: "https://bolls.life/static/bolls/app/views/languages.json") else {
            throw BibleAPIError.invalidURL
        }
        
        print("🔍 Fetching translations from: \(url.absoluteString)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BibleAPIError.noData
        }
        
        // Parse the nested structure: { "languages": [ { "language": "...", "translations": [...] } ] }
        let result = try JSONDecoder().decode(BollsLanguagesResponse.self, from: data)
        
        var allTranslations: [BollsTranslation] = []
        for languageGroup in result.languages {
            for translation in languageGroup.translations {
                allTranslations.append(BollsTranslation(
                    translation: translation.translation,
                    abbreviation: translation.abbreviation,
                    name: translation.name,
                    language: languageGroup.language
                ))
            }
        }
        
        print("✓ Loaded \(allTranslations.count) translations from API")
        return allTranslations
    }
    
    // MARK: - Cache Management
    private func saveTranslationsToCache(_ translations: [BollsTranslation]) {
        if let encoded = try? JSONEncoder().encode(translations) {
            UserDefaults.standard.set(encoded, forKey: "cachedBollsTranslations")
            UserDefaults.standard.set(Date(), forKey: "cachedBollsTranslationsDate")
        }
    }
    
    private func loadTranslationsFromCache() -> [BollsTranslation]? {
        guard let data = UserDefaults.standard.data(forKey: "cachedBollsTranslations"),
              let translations = try? JSONDecoder().decode([BollsTranslation].self, from: data) else {
            return nil
        }
        return translations
    }
    
    /// Fallback translations if API fails
    private func getDefaultTranslations() -> [BollsTranslation] {
        return [
            // Korean
            BollsTranslation(translation: "KRV", abbreviation: "개역한글", name: "Korean Revised Version", language: "Korean"),
            BollsTranslation(translation: "NKRV", abbreviation: "개역개정", name: "New Korean Revised Version", language: "Korean"),
            
            // English
            BollsTranslation(translation: "KJV", abbreviation: "KJV", name: "King James Version", language: "English"),
            BollsTranslation(translation: "ASV", abbreviation: "ASV", name: "American Standard Version", language: "English"),
            BollsTranslation(translation: "WEB", abbreviation: "WEB", name: "World English Bible", language: "English"),
            
            // Japanese
            BollsTranslation(translation: "JLB", abbreviation: "リビングバイブル", name: "Japanese Living Bible", language: "Japanese"),
            
            // Chinese
            BollsTranslation(translation: "CUNP", abbreviation: "和合本", name: "Chinese Union Version", language: "Chinese"),
            
            // Spanish
            BollsTranslation(translation: "RVR1960", abbreviation: "RVR60", name: "Reina Valera 1960", language: "Spanish"),
            
            // German
            BollsTranslation(translation: "LUTH1545", abbreviation: "Luther", name: "Luther Bible 1545", language: "German"),
            
            // French
            BollsTranslation(translation: "LSG", abbreviation: "LSG", name: "Louis Segond", language: "French"),
        ]
    }
    
    /// Convert BollsTranslation to BibleTranslation
    nonisolated func toBibleTranslation(_ bolls: BollsTranslation) -> BibleTranslation {
        let languageCode = Self.languageCodeFor(bolls.language)
        return BibleTranslation(
            id: bolls.translation,
            name: bolls.name ?? bolls.translation,
            shortName: bolls.abbreviation ?? bolls.translation,
            language: bolls.language,
            languageCode: languageCode
        )
    }
    
    private static func languageCodeFor(_ language: String) -> String {
        switch language.lowercased() {
        case "korean": return "ko"
        case "english": return "en"
        case "japanese": return "ja"
        case "chinese": return "zh"
        case "spanish": return "es"
        case "german": return "de"
        case "french": return "fr"
        case "portuguese": return "pt"
        case "italian": return "it"
        case "russian": return "ru"
        default: return "en"
        }
    }
}

// MARK: - API Response Structure
private struct BollsLanguagesResponse: Codable {
    let languages: [BollsLanguageGroup]
}

private struct BollsLanguageGroup: Codable {
    let language: String
    let translations: [BollsTranslationItem]
}

private struct BollsTranslationItem: Codable {
    let translation: String
    let abbreviation: String?
    let name: String?
}

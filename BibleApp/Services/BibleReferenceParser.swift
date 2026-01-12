import Foundation
import NaturalLanguage

/// Parsed result from voice input
struct ParsedBibleReference {
    let book: BibleBook?
    let chapter: Int?
    let verse: Int?
    let detectedLanguage: LanguageMode
    let rawTranscript: String
    let confidence: ParseConfidence
    let alternativeBooks: [BibleBook]  // Other possible matches when ambiguous
    
    var isValid: Bool {
        book != nil && chapter != nil
    }
    
    var isComplete: Bool {
        book != nil && chapter != nil && verse != nil
    }
    
    var isAmbiguous: Bool {
        !alternativeBooks.isEmpty
    }
    
    init(book: BibleBook?, chapter: Int?, verse: Int?, detectedLanguage: LanguageMode, rawTranscript: String, confidence: ParseConfidence, alternativeBooks: [BibleBook] = []) {
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.detectedLanguage = detectedLanguage
        self.rawTranscript = rawTranscript
        self.confidence = confidence
        self.alternativeBooks = alternativeBooks
    }
}

enum ParseConfidence {
    case high      // Exact match found
    case medium    // Fuzzy match with good score
    case low       // Uncertain, might need AI fallback
}

/// Parses natural language Bible references into structured data
final class BibleReferenceParser {
    
    static let shared = BibleReferenceParser()
    
    // MARK: - Book Name Mappings
    
    /// All possible ways to refer to each book (lowercase for matching)
    private lazy var bookAliasMap: [String: String] = {
        var map: [String: String] = [:]
        
        for book in BibleData.books {
            // Primary names
            map[book.id.lowercased()] = book.id
            map[book.nameEn.lowercased()] = book.id
            map[book.nameKr] = book.id
            
            // English abbreviations
            map[String(book.nameEn.prefix(3)).lowercased()] = book.id
            
            // Korean short forms (first 2 characters)
            if book.nameKr.count >= 2 {
                map[String(book.nameKr.prefix(2))] = book.id
            }
        }
        
        // Add common variations and aliases
        let additionalAliases: [String: String] = [
            // English variations
            "gen": "genesis",
            "ex": "exodus", 
            "exod": "exodus",
            "lev": "leviticus",
            "num": "numbers",
            "deut": "deuteronomy",
            "josh": "joshua",
            "judg": "judges",
            "1 sam": "1samuel", "1sam": "1samuel", "first samuel": "1samuel",
            "2 sam": "2samuel", "2sam": "2samuel", "second samuel": "2samuel",
            "1 kings": "1kings", "1kings": "1kings", "first kings": "1kings",
            "2 kings": "2kings", "2kings": "2kings", "second kings": "2kings",
            "1 chron": "1chronicles", "1chron": "1chronicles",
            "2 chron": "2chronicles", "2chron": "2chronicles",
            "neh": "nehemiah",
            "esth": "esther",
            "ps": "psalms", "psalm": "psalms", "psa": "psalms",
            "prov": "proverbs", "pro": "proverbs",
            "eccl": "ecclesiastes", "ecc": "ecclesiastes",
            "song": "songofsolomon", "song of songs": "songofsolomon", "sos": "songofsolomon",
            "isa": "isaiah",
            "jer": "jeremiah",
            "lam": "lamentations",
            "ezek": "ezekiel", "eze": "ezekiel",
            "dan": "daniel",
            "hos": "hosea",
            "joe": "joel",
            "amo": "amos",
            "obad": "obadiah", "oba": "obadiah",
            "jon": "jonah",
            "mic": "micah",
            "nah": "nahum",
            "hab": "habakkuk",
            "zeph": "zephaniah", "zep": "zephaniah",
            "hag": "haggai",
            "zech": "zechariah", "zec": "zechariah",
            "mal": "malachi",
            "matt": "matthew", "mat": "matthew",
            "mar": "mark", "mk": "mark",
            "luk": "luke", "lk": "luke",
            "joh": "john", "jn": "john",
            "act": "acts",
            "rom": "romans",
            "1 cor": "1corinthians", "1cor": "1corinthians", "first corinthians": "1corinthians",
            "2 cor": "2corinthians", "2cor": "2corinthians", "second corinthians": "2corinthians",
            "gal": "galatians",
            "eph": "ephesians",
            "phil": "philippians", "php": "philippians",
            "col": "colossians",
            "1 thess": "1thessalonians", "1thess": "1thessalonians",
            "2 thess": "2thessalonians", "2thess": "2thessalonians",
            "1 tim": "1timothy", "1tim": "1timothy", "first timothy": "1timothy",
            "2 tim": "2timothy", "2tim": "2timothy", "second timothy": "2timothy",
            "tit": "titus",
            "phm": "philemon", "phlm": "philemon",
            "heb": "hebrews",
            "jas": "james", "jam": "james",
            "1 pet": "1peter", "1pet": "1peter", "first peter": "1peter",
            "2 pet": "2peter", "2pet": "2peter", "second peter": "2peter",
            "1 jn": "1john", "1jn": "1john", "first john": "1john",
            "2 jn": "2john", "2jn": "2john", "second john": "2john",
            "3 jn": "3john", "3jn": "3john", "third john": "3john",
            "jud": "jude",
            "rev": "revelation", "revelations": "revelation",
            
            // Korean variations and short forms
            // Explicit partial names - default to first book (상) when ambiguous
            "사무엘": "1samuel",      // 사무엘 -> 사무엘상
            "열왕기": "1kings",       // 열왕기 -> 열왕기상
            "역대": "1chronicles",    // 역대 -> 역대상
            "고린도": "1corinthians", // 고린도 -> 고린도전서
            "데살로니가": "1thessalonians", // 데살로니가 -> 데살로니가전서
            "디모데": "1timothy",     // 디모데 -> 디모데전서
            "베드로": "1peter",       // 베드로 -> 베드로전서
            "요한서": "1john",        // 요한서 -> 요한일서
            
            "창세": "genesis",
            "출애굽": "exodus", "출": "exodus",
            "레위": "leviticus",
            "민수": "numbers",
            "신명": "deuteronomy",
            "여호수아": "joshua", "여호": "joshua",
            "사사": "judges",
            "룻": "ruth",
            "사무엘상": "1samuel", "삼상": "1samuel",
            "사무엘하": "2samuel", "삼하": "2samuel",
            "열왕기상": "1kings", "왕상": "1kings",
            "열왕기하": "2kings", "왕하": "2kings",
            "역대상": "1chronicles", "대상": "1chronicles",
            "역대하": "2chronicles", "대하": "2chronicles",
            "에스라": "ezra", "스라": "ezra",
            "느헤미야": "nehemiah", "느혜": "nehemiah",
            "에스더": "esther",
            "욥": "job",
            "시편": "psalms", "시": "psalms",
            "잠언": "proverbs", "잠": "proverbs",
            "전도서": "ecclesiastes", "전도": "ecclesiastes",
            "아가": "songofsolomon",
            "이사야": "isaiah", "사야": "isaiah",
            "예레미야": "jeremiah", "렘": "jeremiah",
            "예레미야애가": "lamentations", "애가": "lamentations",
            "에스겔": "ezekiel", "겔": "ezekiel",
            "다니엘": "daniel", "단": "daniel",
            "호세아": "hosea",
            "요엘": "joel",
            "아모스": "amos",
            "오바댜": "obadiah",
            "요나": "jonah",
            "미가": "micah",
            "나훔": "nahum",
            "하박국": "habakkuk",
            "스바냐": "zephaniah",
            "학개": "haggai",
            "스가랴": "zechariah",
            "말라기": "malachi",
            "마태복음": "matthew", "마태": "matthew", "마": "matthew",
            "마가복음": "mark", "마가": "mark", "막": "mark",
            "누가복음": "luke", "누가": "luke", "눅": "luke",
            "요한복음": "john", "요한": "john", "요": "john",
            "사도행전": "acts", "행전": "acts", "행": "acts",
            "로마서": "romans", "롬": "romans",
            "고린도전서": "1corinthians", "고전": "1corinthians",
            "고린도후서": "2corinthians", "고후": "2corinthians",
            "갈라디아서": "galatians", "갈": "galatians",
            "에베소서": "ephesians", "엡": "ephesians",
            "빌립보서": "philippians", "빌": "philippians",
            "골로새서": "colossians", "골": "colossians",
            "데살로니가전서": "1thessalonians", "살전": "1thessalonians",
            "데살로니가후서": "2thessalonians", "살후": "2thessalonians",
            "디모데전서": "1timothy", "딤전": "1timothy",
            "디모데후서": "2timothy", "딤후": "2timothy",
            "디도서": "titus", "딛": "titus",
            "빌레몬서": "philemon", "몬": "philemon",
            "히브리서": "hebrews", "히": "hebrews",
            "야고보서": "james", "약": "james",
            "베드로전서": "1peter", "벧전": "1peter",
            "베드로후서": "2peter", "벧후": "2peter",
            "요한일서": "1john", "요일": "1john",
            "요한이서": "2john", "요이": "2john",
            "요한삼서": "3john", "요삼": "3john",
            "유다서": "jude", "유": "jude",
            "요한계시록": "revelation", "계시록": "revelation", "계": "revelation"
        ]
        
        for (alias, bookId) in additionalAliases {
            map[alias] = bookId
        }
        
        return map
    }()
    
    /// Korean number words to digits
    private let koreanNumbers: [String: Int] = [
        "일": 1, "이": 2, "삼": 3, "사": 4, "오": 5,
        "육": 6, "칠": 7, "팔": 8, "구": 9, "십": 10,
        "십일": 11, "십이": 12, "십삼": 13, "십사": 14, "십오": 15,
        "십육": 16, "십칠": 17, "십팔": 18, "십구": 19, "이십": 20,
        "하나": 1, "둘": 2, "셋": 3, "넷": 4, "다섯": 5,
        "여섯": 6, "일곱": 7, "여덟": 8, "아홉": 9, "열": 10
    ]
    
    /// English number words to digits
    private let englishNumbers: [String: Int] = [
        "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
        "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
        "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14, "fifteen": 15,
        "sixteen": 16, "seventeen": 17, "eighteen": 18, "nineteen": 19, "twenty": 20,
        "first": 1, "second": 2, "third": 3
    ]
    
    // MARK: - Main Parse Function
    
    /// Parse a transcript into book, chapter, and verse
    func parse(_ transcript: String) -> ParsedBibleReference {
        let language = detectLanguage(transcript)
        let normalizedText = normalizeText(transcript, language: language)
        
        // Try different parsing strategies in order of specificity
        if let result = tryPatternParsing(normalizedText, language: language, rawTranscript: transcript) {
            return result
        }
        
        if let result = tryFuzzyParsing(normalizedText, language: language, rawTranscript: transcript) {
            return result
        }
        
        // Try book-only parsing (e.g., just "창세기" or "Genesis")
        if let result = tryBookOnlyParsing(normalizedText, language: language, rawTranscript: transcript) {
            return result
        }
        
        // Couldn't parse - return empty result with low confidence
        return ParsedBibleReference(
            book: nil,
            chapter: nil,
            verse: nil,
            detectedLanguage: language,
            rawTranscript: transcript,
            confidence: .low
        )
    }
    
    // MARK: - Language Detection
    
    private func detectLanguage(_ text: String) -> LanguageMode {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        if let dominantLanguage = recognizer.dominantLanguage {
            return dominantLanguage == .korean ? .kr : .en
        }
        
        // Fallback: check for Korean characters
        let koreanRange = text.range(of: "[\u{AC00}-\u{D7AF}\u{1100}-\u{11FF}]", options: .regularExpression)
        return koreanRange != nil ? .kr : .en
    }
    
    // MARK: - Text Normalization
    
    private func normalizeText(_ text: String, language: LanguageMode) -> String {
        var normalized = text.lowercased()
        
        // Remove common filler words
        let fillerWords = language == .kr
            ? ["보여줘", "보여주세요", "찾아줘", "찾아주세요", "로 가줘", "가줘", "으로", "의", "을", "를"]
            : ["show me", "go to", "find", "take me to", "please", "the", "book of"]
        
        for filler in fillerWords {
            normalized = normalized.replacingOccurrences(of: filler, with: " ")
        }
        
        // Normalize whitespace
        normalized = normalized.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        return normalized.trimmingCharacters(in: .whitespaces)
    }
    
    // MARK: - Pattern-Based Parsing
    
    private func tryPatternParsing(_ text: String, language: LanguageMode, rawTranscript: String) -> ParsedBibleReference? {
        
        let patterns: [(pattern: String, groups: (book: Int, chapter: Int, verse: Int?))]
        
        if language == .kr {
            patterns = [
                // "요한복음 3장 16절" - full format
                (#"(.+?)\s*(\d+)\s*장\s*(\d+)\s*절"#, (1, 2, 3)),
                // "시편 23편 1절" - Psalms format
                (#"(.+?)\s*(\d+)\s*편\s*(\d+)\s*절"#, (1, 2, 3)),
                // "요한복음 3장" - chapter only
                (#"(.+?)\s*(\d+)\s*장"#, (1, 2, nil)),
                // "시편 23편" - Psalms chapter only
                (#"(.+?)\s*(\d+)\s*편"#, (1, 2, nil)),
                // "요한 3 16" or "요한 3:16" - numeric format
                (#"(.+?)\s+(\d+)\s*[:\s]\s*(\d+)"#, (1, 2, 3)),
                // "요한 3" - book and chapter only
                (#"(.+?)\s+(\d+)$"#, (1, 2, nil))
            ]
        } else {
            patterns = [
                // "John 3:16" - standard format
                (#"(.+?)\s+(\d+)\s*:\s*(\d+)"#, (1, 2, 3)),
                // "John chapter 3 verse 16"
                (#"(.+?)\s+chapter\s+(\d+)\s+verse\s+(\d+)"#, (1, 2, 3)),
                // "John 3 16" - space separated
                (#"(.+?)\s+(\d+)\s+(\d+)$"#, (1, 2, 3)),
                // "John 3" - chapter only
                (#"(.+?)\s+(\d+)$"#, (1, 2, nil)),
                // "John chapter 3"
                (#"(.+?)\s+chapter\s+(\d+)"#, (1, 2, nil))
            ]
        }
        
        for (pattern, groups) in patterns {
            if let result = matchPattern(pattern, in: text, groups: groups, language: language, rawTranscript: rawTranscript) {
                return result
            }
        }
        
        return nil
    }
    
    private func matchPattern(
        _ pattern: String,
        in text: String,
        groups: (book: Int, chapter: Int, verse: Int?),
        language: LanguageMode,
        rawTranscript: String
    ) -> ParsedBibleReference? {
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        
        // Extract book name
        guard let bookRange = Range(match.range(at: groups.book), in: text) else {
            return nil
        }
        let bookText = String(text[bookRange]).trimmingCharacters(in: .whitespaces)
        
        // Extract chapter
        guard let chapterRange = Range(match.range(at: groups.chapter), in: text),
              let chapter = Int(text[chapterRange]) else {
            return nil
        }
        
        // Extract verse (optional)
        var verse: Int? = nil
        if let verseGroup = groups.verse,
           let verseRange = Range(match.range(at: verseGroup), in: text) {
            verse = Int(text[verseRange])
        }
        
        // Find matching book
        let matchResult = findBook(bookText, language: language)
        
        // Validate chapter is within range
        if let book = matchResult.book, chapter > book.chapterCount {
            return nil
        }
        
        return ParsedBibleReference(
            book: matchResult.book,
            chapter: chapter,
            verse: verse,
            detectedLanguage: language,
            rawTranscript: rawTranscript,
            confidence: matchResult.book != nil ? matchResult.confidence : .low,
            alternativeBooks: matchResult.alternatives
        )
    }
    
    // MARK: - Book-Only Parsing (e.g., just "창세기" or "Genesis")
    
    private func tryBookOnlyParsing(_ text: String, language: LanguageMode, rawTranscript: String) -> ParsedBibleReference? {
        // Try to find a book match for the entire text (no numbers required)
        let matchResult = findBook(text, language: language)
        
        guard let book = matchResult.book, matchResult.confidence != .low else {
            return nil
        }
        
        return ParsedBibleReference(
            book: book,
            chapter: nil,  // Will default to 1 in ViewModel
            verse: nil,    // Will default to 1 in ViewModel
            detectedLanguage: language,
            rawTranscript: rawTranscript,
            confidence: matchResult.confidence,
            alternativeBooks: matchResult.alternatives
        )
    }
    
    // MARK: - Fuzzy Parsing (Fallback)
    
    private func tryFuzzyParsing(_ text: String, language: LanguageMode, rawTranscript: String) -> ParsedBibleReference? {
        // Try to extract numbers and remaining text
        var numbers: [Int] = []
        var bookCandidate = ""
        
        // Convert number words to digits
        var processedText = text
        let numberMap = language == .kr ? koreanNumbers : englishNumbers
        for (word, num) in numberMap {
            processedText = processedText.replacingOccurrences(of: word, with: " \(num) ")
        }
        
        // Extract all numbers
        let numberPattern = #"\d+"#
        if let regex = try? NSRegularExpression(pattern: numberPattern) {
            let matches = regex.matches(in: processedText, range: NSRange(processedText.startIndex..., in: processedText))
            for match in matches {
                if let range = Range(match.range, in: processedText),
                   let num = Int(processedText[range]) {
                    numbers.append(num)
                }
            }
        }
        
        // Remove numbers to get book name
        bookCandidate = processedText.replacingOccurrences(of: #"\d+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        guard !bookCandidate.isEmpty, !numbers.isEmpty else {
            return nil
        }
        
        let matchResult = findBook(bookCandidate, language: language)
        
        let chapter = numbers.first
        let verse = numbers.count > 1 ? numbers[1] : nil
        
        // Validate
        if let book = matchResult.book, let chapter = chapter, chapter > book.chapterCount {
            return nil
        }
        
        return ParsedBibleReference(
            book: matchResult.book,
            chapter: chapter,
            verse: verse,
            detectedLanguage: language,
            rawTranscript: rawTranscript,
            confidence: matchResult.book != nil ? matchResult.confidence : .low,
            alternativeBooks: matchResult.alternatives
        )
    }
    
    // MARK: - Book Matching
    
    /// Result of book matching - includes primary match and alternatives
    struct BookMatchResult {
        let book: BibleBook?
        let confidence: ParseConfidence
        let alternatives: [BibleBook]  // Other possible matches
    }
    
    private func findBook(_ text: String, language: LanguageMode) -> BookMatchResult {
        let searchText = text.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Skip if too short
        guard searchText.count >= 1 else {
            return BookMatchResult(book: nil, confidence: .low, alternatives: [])
        }
        
        // 1. Try exact match first
        if let bookId = bookAliasMap[searchText],
           let book = BibleData.book(by: bookId) {
            return BookMatchResult(book: book, confidence: .high, alternatives: [])
        }
        
        // 2. Try prefix match - collect ALL matches
        var prefixMatches: [BibleBook] = []
        var matchedIds = Set<String>()
        
        for (alias, bookId) in bookAliasMap {
            if alias.hasPrefix(searchText) || searchText.hasPrefix(alias) {
                if !matchedIds.contains(bookId), let book = BibleData.book(by: bookId) {
                    prefixMatches.append(book)
                    matchedIds.insert(bookId)
                }
            }
        }
        
        // If we have prefix matches, sort by order and return
        if !prefixMatches.isEmpty {
            // Sort by Bible order (earlier books first: 상 before 하)
            prefixMatches.sort { $0.order < $1.order }
            let primary = prefixMatches.removeFirst()
            return BookMatchResult(book: primary, confidence: .medium, alternatives: prefixMatches)
        }
        
        // 3. Try contains match - if search text contains a book name or vice versa
        var containsMatches: [BibleBook] = []
        matchedIds.removeAll()
        
        for (alias, bookId) in bookAliasMap {
            if searchText.contains(alias) || alias.contains(searchText) {
                if !matchedIds.contains(bookId), let book = BibleData.book(by: bookId) {
                    containsMatches.append(book)
                    matchedIds.insert(bookId)
                }
            }
        }
        
        if !containsMatches.isEmpty {
            containsMatches.sort { $0.order < $1.order }
            let primary = containsMatches.removeFirst()
            return BookMatchResult(book: primary, confidence: .medium, alternatives: containsMatches)
        }
        
        // 4. Fuzzy matching with Levenshtein distance
        // Only accept matches within a reasonable distance threshold
        let maxAllowedDistance = max(2, searchText.count / 2)  // Allow up to half the characters to be wrong
        
        var fuzzyMatches: [(book: BibleBook, distance: Int, alias: String)] = []
        
        for (alias, bookId) in bookAliasMap {
            let distance = levenshteinDistance(searchText, alias)
            
            // Only consider matches within the threshold
            if distance <= maxAllowedDistance {
                if let book = BibleData.book(by: bookId) {
                    // Keep the best distance for each book
                    if let existingIdx = fuzzyMatches.firstIndex(where: { $0.book.id == book.id }) {
                        if distance < fuzzyMatches[existingIdx].distance {
                            fuzzyMatches[existingIdx] = (book, distance, alias)
                        }
                    } else {
                        fuzzyMatches.append((book, distance, alias))
                    }
                }
            }
        }
        
        // If no fuzzy matches found, return no match
        guard !fuzzyMatches.isEmpty else {
            return BookMatchResult(book: nil, confidence: .low, alternatives: [])
        }
        
        // Sort by distance (best match first), then by Bible order
        fuzzyMatches.sort { 
            if $0.distance != $1.distance {
                return $0.distance < $1.distance
            }
            return $0.book.order < $1.book.order
        }
        
        let best = fuzzyMatches.removeFirst()
        
        // Get alternatives with same or similar distance (within 1)
        let alternatives = fuzzyMatches
            .filter { $0.distance <= best.distance + 1 }
            .prefix(5)  // Limit to top 5 alternatives
            .map { $0.book }
        
        // Determine confidence based on distance
        let confidence: ParseConfidence
        if best.distance == 0 {
            confidence = .high
        } else if best.distance <= 1 {
            confidence = .medium
        } else {
            confidence = .low
        }
        
        return BookMatchResult(
            book: best.book,
            confidence: confidence,
            alternatives: Array(alternatives)
        )
    }
    
    // MARK: - Levenshtein Distance
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1 = Array(s1)
        let s2 = Array(s2)
        let m = s1.count
        let n = s2.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }
        
        for i in 1...m {
            for j in 1...n {
                let cost = s1[i-1] == s2[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }
        
        return matrix[m][n]
    }
}

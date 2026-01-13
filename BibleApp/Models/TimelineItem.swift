import Foundation

// MARK: - Timeline Data Models

struct TimelineData: Codable {
    let timelineData: [TimelineItem]
    let metadata: TimelineMetadata
    let categories: [String: LocalizedText]
    let types: [String: LocalizedText]
    
    enum CodingKeys: String, CodingKey {
        case timelineData = "timeline_data"
        case metadata, categories, types
    }
}

struct TimelineMetadata: Codable {
    let version: String
    let lastUpdated: String
    let totalBooks: Int
    let totalHistoricalEvents: Int
    let totalEras: Int
    let notes: LocalizedText
    
    enum CodingKeys: String, CodingKey {
        case version
        case lastUpdated = "last_updated"
        case totalBooks = "total_books"
        case totalHistoricalEvents = "total_historical_events"
        case totalEras = "total_eras"
        case notes
    }
}

struct LocalizedText: Codable, Equatable {
    let ko: String
    let en: String
    
    func text(for language: LanguageMode) -> String {
        switch language {
        case .kr: return ko
        case .en: return en
        }
    }
}

struct TimelineItem: Codable, Identifiable, Equatable {
    let id: String
    let type: TimelineItemType
    let startYear: Int
    let endYear: Int?
    let title: LocalizedText
    let description: LocalizedText
    let testament: String?
    let category: String?
    let bookId: Int?
    let relatedHistoricalEvents: [String]?
    
    static func == (lhs: TimelineItem, rhs: TimelineItem) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, description, testament, category
        case startYear = "start_year"
        case endYear = "end_year"
        case bookId = "book_id"
        case relatedHistoricalEvents = "related_historical_events"
    }
    
    // Computed properties for display
    var displayYear: String {
        let startStr = formatYear(startYear)
        if let end = endYear {
            return "\(startStr) – \(formatYear(end))"
        }
        return startStr
    }
    
    private func formatYear(_ year: Int) -> String {
        if year < 0 {
            return "BC \(abs(year))"
        } else {
            return "AD \(year)"
        }
    }
    
    var isHistoricalEvent: Bool {
        type == .historicalEvent
    }
    
    var isBibleBook: Bool {
        type == .bibleBookContext
    }
    
    var isEra: Bool {
        type == .era
    }
}

enum TimelineItemType: String, Codable {
    case era = "ERA"
    case historicalEvent = "HISTORICAL_EVENT"
    case bibleBookContext = "BIBLE_BOOK_CONTEXT"
    
    var displayName: LocalizedText {
        switch self {
        case .era:
            return LocalizedText(ko: "시대", en: "Era")
        case .historicalEvent:
            return LocalizedText(ko: "역사", en: "History")
        case .bibleBookContext:
            return LocalizedText(ko: "성경", en: "Bible")
        }
    }
    
    var iconName: String {
        switch self {
        case .era:
            return "calendar.badge.clock"
        case .historicalEvent:
            return "building.columns"
        case .bibleBookContext:
            return "book.closed"
        }
    }
}

// MARK: - Timeline Group (for era-based grouping)

struct TimelineEraGroup: Identifiable {
    let id: String
    let era: TimelineItem
    let items: [TimelineItem]
    
    var sortedItems: [TimelineItem] {
        items.sorted { $0.startYear < $1.startYear }
    }
}

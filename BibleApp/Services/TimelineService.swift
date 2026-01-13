import Foundation

/// Service to load and manage timeline data
final class TimelineService {
    static let shared = TimelineService()
    
    private var cachedData: TimelineData?
    
    private init() {}
    
    // MARK: - Load Data
    
    func loadTimelineData() -> TimelineData? {
        if let cached = cachedData {
            return cached
        }
        
        // Try with "Timeline" subdirectory first (matching ChapterSummaries pattern)
        if let url = Bundle.main.url(forResource: "timeline_data", withExtension: "json", subdirectory: "Timeline") {
            return loadFromURL(url)
        }
        
        // Fallback: try without subdirectory
        if let flatUrl = Bundle.main.url(forResource: "timeline_data", withExtension: "json") {
            return loadFromURL(flatUrl)
        }
        
        print("❌ Timeline: Could not find timeline_data.json")
        return nil
    }
    
    private func loadFromURL(_ url: URL) -> TimelineData? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let timelineData = try decoder.decode(TimelineData.self, from: data)
            cachedData = timelineData
            print("✅ Timeline: Loaded \(timelineData.timelineData.count) items")
            return timelineData
        } catch {
            print("❌ Timeline: Failed to decode - \(error)")
            return nil
        }
    }
    
    // MARK: - Filtered Data
    
    /// Get all items sorted by start year
    func getAllItems() -> [TimelineItem] {
        guard let data = loadTimelineData() else { return [] }
        return data.timelineData.sorted { $0.startYear < $1.startYear }
    }
    
    /// Get only historical events
    func getHistoricalEvents() -> [TimelineItem] {
        getAllItems().filter { $0.type == .historicalEvent }
    }
    
    /// Get only Bible book contexts
    func getBibleBookContexts() -> [TimelineItem] {
        getAllItems().filter { $0.type == .bibleBookContext }
    }
    
    /// Get only eras
    func getEras() -> [TimelineItem] {
        getAllItems().filter { $0.type == .era }
    }
    
    /// Get items grouped by era
    func getItemsGroupedByEra() -> [TimelineEraGroup] {
        let eras = getEras().sorted { $0.startYear < $1.startYear }
        let allItems = getAllItems().filter { !$0.isEra }
        
        var groups: [TimelineEraGroup] = []
        
        for (index, era) in eras.enumerated() {
            let eraStart = era.startYear
            let eraEnd: Int
            
            if index < eras.count - 1 {
                eraEnd = eras[index + 1].startYear
            } else {
                eraEnd = 200 // End of NT era
            }
            
            let itemsInEra = allItems.filter { item in
                item.startYear >= eraStart && item.startYear < eraEnd
            }
            
            let group = TimelineEraGroup(
                id: era.id,
                era: era,
                items: itemsInEra
            )
            groups.append(group)
        }
        
        return groups
    }
    
    /// Get items for timeline display (excluding eras, sorted by year)
    func getTimelineItems() -> [TimelineItem] {
        getAllItems().filter { !$0.isEra }.sorted { $0.startYear < $1.startYear }
    }
    
    /// Find item by ID
    func findItem(by id: String) -> TimelineItem? {
        getAllItems().first { $0.id == id }
    }
    
    /// Get related historical events for a Bible book
    func getRelatedEvents(for bookItem: TimelineItem) -> [TimelineItem] {
        guard let relatedIds = bookItem.relatedHistoricalEvents else { return [] }
        return relatedIds.compactMap { findItem(by: $0) }
    }
}

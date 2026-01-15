import SwiftUI

struct BibleTimelineView: View {
    let languageMode: LanguageMode
    var safeAreaTop: CGFloat = 0
    var safeAreaBottom: CGFloat = 0
    var onClose: (() -> Void)?
    var onBookSelect: ((Int) -> Void)? // book_id from timeline data
    
    @State private var timelineItems: [TimelineItem] = []
    @State private var eras: [TimelineItem] = []
    @State private var selectedItem: TimelineItem?
    @State private var showDetail: Bool = false
    @State private var glowAnimating = false
    
    // Layout constants
    private let axisWidth: CGFloat = 2
    private let cardWidth: CGFloat = 150
    private let yearLabelWidth: CGFloat = 60
    private let verticalSpacing: CGFloat = 16
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Title
                        titleSection
                            .padding(.top, safeAreaTop + 16)
                        
                        // Era-based timeline
                        timelineContent
                            .padding(.bottom, 120)
                    }
                }
            }
            
            // Bottom close button
            bottomBar
                .padding(.horizontal, 24)
                .padding(.bottom, safeAreaBottom - 4)
        }
        .background(Color.black)
        .onAppear {
            loadData()
        }
        .sheet(item: $selectedItem) { item in
            TimelineDetailSheet(
                item: item,
                languageMode: languageMode,
                relatedEvents: TimelineService.shared.getRelatedEvents(for: item)
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        Image("AppIcon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(glowAnimating ? 0.38 : 0.25), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 25
                        )
                    )
                    .blur(radius: 8)
                    .scaleEffect(glowAnimating ? 1.15 : 1.0)
                    .allowsHitTesting(false)
            )
            .padding(.bottom, 24)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    glowAnimating = true
                }
            }
    }
    
    // MARK: - Timeline Content
    private var timelineContent: some View {
        ZStack(alignment: .top) {
            // Central axis line
            GeometryReader { geo in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: axisWidth)
                    .frame(maxHeight: .infinity)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            
            // Timeline items
            VStack(spacing: 0) {
                ForEach(eras, id: \.id) { era in
                    eraSection(era: era)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Era Section
    private func eraSection(era: TimelineItem) -> some View {
        let itemsInEra = getItemsForEra(era)
        
        return VStack(spacing: 0) {
            // Era header
            eraHeader(era)
                .id(era.id)
            
            // Items in this era
            ForEach(itemsInEra, id: \.id) { item in
                timelineRow(item: item)
            }
        }
    }
    
    // MARK: - Era Header
    private func eraHeader(_ era: TimelineItem) -> some View {
        VStack(spacing: 8) {
            // Era badge
            Text(era.title.text(for: languageMode))
                .font(languageMode == .kr
                    ? FontManager.koreanSans(size: 14, weight: .bold)
                    : .system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            
            // Era date range
            Text(era.displayYear)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
            
            // Era description
            Text(era.description.text(for: languageMode))
                .font(languageMode == .kr
                    ? FontManager.koreanSans(size: 12, weight: .regular)
                    : .system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Timeline Row
    private func timelineRow(item: TimelineItem) -> some View {
        HStack(alignment: .center, spacing: 0) {
            // Left side (Historical Events)
            if item.isHistoricalEvent {
                eventCard(item: item, alignment: .trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
            
            // Center - Year indicator on axis
            yearIndicator(year: item.startYear, type: item.type)
                .frame(width: yearLabelWidth + 20)
            
            // Right side (Bible Books)
            if item.isBibleBook {
                eventCard(item: item, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, verticalSpacing / 2)
    }
    
    // MARK: - Event Card
    private func eventCard(item: TimelineItem, alignment: HorizontalAlignment) -> some View {
        Button {
            selectedItem = item
            HapticManager.shared.selection()
        } label: {
            VStack(alignment: alignment == .leading ? .leading : .trailing, spacing: 6) {
                // Type tag
                Text(item.type.displayName.text(for: languageMode))
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(cardAccentColor(for: item))
                
                // Title
                Text(item.title.text(for: languageMode))
                    .font(languageMode == .kr
                        ? FontManager.koreanSans(size: 13, weight: .semibold)
                        : .system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
                    .lineLimit(2)
                
                // Description
                Text(item.description.text(for: languageMode))
                    .font(languageMode == .kr
                        ? FontManager.koreanSans(size: 11, weight: .regular)
                        : .system(size: 11, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
                    .lineLimit(2)
                
                // Date
                Text(item.displayYear)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(12)
            .frame(width: cardWidth, alignment: alignment == .leading ? .leading : .trailing)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(cardBackground(for: item))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(cardBorderColor(for: item), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Year Indicator
    private func yearIndicator(year: Int, type: TimelineItemType) -> some View {
        ZStack {
            // Connector line
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 30, height: 1)
            
            // Year dot
            Circle()
                .fill(type == .historicalEvent ? Color.amber : Color.cyan)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        HStack {
            // Legend
            HStack(spacing: 16) {
                legendItem(color: .amber, text: languageMode == .kr ? "역사" : "History")
                legendItem(color: .cyan, text: languageMode == .kr ? "성경" : "Bible")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassBackground(.capsule, intensity: .ultraThin)
            
            Spacer()
            
            // Close button
            Button {
                onClose?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.glassCircle)
        }
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadData() {
        eras = TimelineService.shared.getEras()
        timelineItems = TimelineService.shared.getTimelineItems()
    }
    
    private func getItemsForEra(_ era: TimelineItem) -> [TimelineItem] {
        let eraIndex = eras.firstIndex { $0.id == era.id } ?? 0
        let nextEraStart: Int
        
        if eraIndex < eras.count - 1 {
            nextEraStart = eras[eraIndex + 1].startYear
        } else {
            nextEraStart = 200 // End of NT era
        }
        
        return timelineItems
            .filter { $0.startYear >= era.startYear && $0.startYear < nextEraStart }
            .sorted { $0.startYear < $1.startYear }
    }
    
    private func cardBackground(for item: TimelineItem) -> Color {
        if item.isHistoricalEvent {
            return Color(red: 0.15, green: 0.12, blue: 0.08) // Warm brown
        } else {
            return Color(red: 0.08, green: 0.12, blue: 0.15) // Cool blue
        }
    }
    
    private func cardBorderColor(for item: TimelineItem) -> Color {
        if item.isHistoricalEvent {
            return Color.amber.opacity(0.3)
        } else {
            return Color.cyan.opacity(0.3)
        }
    }
    
    private func cardAccentColor(for item: TimelineItem) -> Color {
        if item.isHistoricalEvent {
            return .amber
        } else {
            return .cyan
        }
    }
}

// MARK: - Color Extensions

extension Color {
    static let amber = Color(red: 0.95, green: 0.75, blue: 0.3)
    static let cyan = Color(red: 0.3, green: 0.8, blue: 0.9)
}

// MARK: - Timeline Detail Sheet

struct TimelineDetailSheet: View {
    let item: TimelineItem
    let languageMode: LanguageMode
    let relatedEvents: [TimelineItem]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection
                    
                    // Description
                    descriptionSection
                    
                    // Related events (for Bible books)
                    if item.isBibleBook && !relatedEvents.isEmpty {
                        relatedEventsSection
                    }
                    
                    // Book info (for Bible books)
                    if item.isBibleBook {
                        bookInfoSection
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
            }
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(item.title.text(for: languageMode))
                .font(languageMode == .kr
                    ? FontManager.koreanSans(size: 24, weight: .bold)
                    : .system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Date
            Text(item.displayYear)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var descriptionSection: some View {
        Text(item.description.text(for: languageMode))
            .font(languageMode == .kr
                ? FontManager.koreanSans(size: 16, weight: .regular)
                : .system(size: 16, weight: .regular))
            .foregroundStyle(.white.opacity(0.9))
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var relatedEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageMode == .kr ? "관련 역사적 사건" : "Related Historical Events")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
            
            ForEach(relatedEvents, id: \.id) { event in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.amber)
                        .frame(width: 6, height: 6)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.title.text(for: languageMode))
                            .font(languageMode == .kr
                                ? FontManager.koreanSans(size: 14, weight: .medium)
                                : .system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                        
                        Text(event.displayYear)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    Spacer()
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.05))
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var bookInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageMode == .kr ? "성경 정보" : "Book Info")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
            
            HStack(spacing: 16) {
                if let testament = item.testament {
                    infoChip(
                        label: languageMode == .kr ? "구분" : "Testament",
                        value: testament == "OT"
                            ? (languageMode == .kr ? "구약" : "Old Testament")
                            : (languageMode == .kr ? "신약" : "New Testament")
                    )
                }
                
                if let category = item.category {
                    infoChip(
                        label: languageMode == .kr ? "분류" : "Category",
                        value: categoryDisplayName(category)
                    )
                }
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func infoChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            
            Text(value)
                .font(languageMode == .kr
                    ? FontManager.koreanSans(size: 13, weight: .medium)
                    : .system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func categoryDisplayName(_ category: String) -> String {
        let categoryMap: [String: (ko: String, en: String)] = [
            "PENTATEUCH": ("모세 오경", "Pentateuch"),
            "HISTORY": ("역사서", "History"),
            "WISDOM": ("지혜서", "Wisdom"),
            "MAJOR_PROPHETS": ("대선지서", "Major Prophets"),
            "MINOR_PROPHETS": ("소선지서", "Minor Prophets"),
            "GOSPELS": ("복음서", "Gospels"),
            "PAULINE_EPISTLES": ("바울 서신", "Pauline Epistles"),
            "GENERAL_EPISTLES": ("공동 서신", "General Epistles"),
            "APOCALYPTIC": ("묵시록", "Apocalyptic")
        ]
        
        if let names = categoryMap[category] {
            return languageMode == .kr ? names.ko : names.en
        }
        return category
    }
}

// MARK: - Embeddable Timeline Content View (without bottom bar)

// Preference key to track visible eras
private struct VisibleEraPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

struct BibleTimelineContentView: View {
    let languageMode: LanguageMode
    var topPadding: CGFloat = 0
    var currentBook: BibleBook? = nil
    var searchText: String = ""
    @Binding var scrollToBottomTrigger: Bool
    var onBookSelect: ((BibleBook) -> Void)? // Called when a Bible book is tapped
    
    @State private var timelineItems: [TimelineItem] = []
    @State private var eras: [TimelineItem] = []
    @State private var selectedItem: TimelineItem? // For historical events only
    @State private var hasRestoredScrollPosition = false
    @State private var glowAnimating = false
    
    init(
        languageMode: LanguageMode,
        topPadding: CGFloat = 0,
        currentBook: BibleBook? = nil,
        searchText: String = "",
        scrollToBottomTrigger: Binding<Bool> = .constant(false),
        onBookSelect: ((BibleBook) -> Void)? = nil
    ) {
        self.languageMode = languageMode
        self.topPadding = topPadding
        self.currentBook = currentBook
        self.searchText = searchText
        self._scrollToBottomTrigger = scrollToBottomTrigger
        self.onBookSelect = onBookSelect
    }
    
    // Layout constants
    private let axisWidth: CGFloat = 2
    private let yearLabelWidth: CGFloat = 60
    private let verticalSpacing: CGFloat = 16
    
    // Filtered items based on search
    private var filteredTimelineItems: [TimelineItem] {
        guard !searchText.isEmpty else { return timelineItems }
        
        return timelineItems.filter { item in
            // Always keep historical events
            if item.type == .historicalEvent {
                return true
            }
            // Filter Bible books by name (한글 초성/부분 검색 지원)
            let titleMatch = item.title.en.localizedCaseInsensitiveContains(searchText) ||
                            KoreanSearchHelper.matches(query: searchText, target: item.title.ko)
            return titleMatch
        }
    }
    
    // Eras that have at least one item (for search filtering)
    private var filteredEras: [TimelineItem] {
        guard !searchText.isEmpty else { return eras }
        return eras.filter { era in
            !getItemsForEra(era).isEmpty
        }
    }
    
    // First matching Bible book for auto-scrolling
    private var firstMatchingBibleBook: TimelineItem? {
        guard !searchText.isEmpty else { return nil }
        return filteredTimelineItems
            .filter { $0.isBibleBook }
            .sorted { $0.startYear < $1.startYear }
            .first
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Title
                    titleSection
                        .padding(.top, topPadding + 16)
                    
                    // Era-based timeline
                    timelineContent
                    
                    // Bottom anchor for scroll-to-bottom
                    Color.clear
                        .frame(height: 1)
                        .id("timelineBottom")
                        .padding(.bottom, 120)  // Space for bottom bar
                }
            }
            .coordinateSpace(name: "timelineScroll")
            .onChange(of: searchText) { _, newValue in
                // Scroll to first matching Bible book when searching
                // Use custom anchor to account for safe area and title
                if !newValue.isEmpty, let firstBook = firstMatchingBibleBook {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("book_\(firstBook.id)", anchor: UnitPoint(x: 0.5, y: 0.15))
                    }
                }
            }
            .onChange(of: eras) { _, _ in
                // Always start at the top
                hasRestoredScrollPosition = true
            }
            .onChange(of: scrollToBottomTrigger) { _, _ in
                // Scroll to bottom when triggered
                withAnimation(.easeOut(duration: 0.4)) {
                    proxy.scrollTo("timelineBottom", anchor: .bottom)
                }
            }
        }
        .onAppear {
            loadData()
        }
        .sheet(item: $selectedItem) { item in
            TimelineDetailSheet(
                item: item,
                languageMode: languageMode,
                relatedEvents: TimelineService.shared.getRelatedEvents(for: item)
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        Image("AppIcon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(glowAnimating ? 0.38 : 0.25), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 25
                        )
                    )
                    .blur(radius: 8)
                    .scaleEffect(glowAnimating ? 1.15 : 1.0)
                    .allowsHitTesting(false)
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    glowAnimating = true
                }
            }
    }
    
    // MARK: - Timeline Content
    private var timelineContent: some View {
        ZStack(alignment: .top) {
            // Central axis line (solid 1pt)
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            
            // Timeline items
            VStack(spacing: 0) {
                ForEach(filteredEras, id: \.id) { era in
                    eraSection(era: era)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Era Section
    private func eraSection(era: TimelineItem) -> some View {
        let yearGroups = getYearGroupsForEra(era)
        
        return VStack(spacing: 0) {
            // Era header
            eraHeader(era)
                .id(era.id)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: VisibleEraPreferenceKey.self,
                            value: [era.id: geo.frame(in: .named("timelineScroll")).minY]
                        )
                    }
                )
            
            // Items grouped by year
            ForEach(yearGroups, id: \.year) { group in
                timelineYearRow(group: group)
            }
        }
    }
    
    // MARK: - Era Header
    private func eraHeader(_ era: TimelineItem) -> some View {
        HStack(alignment: .center, spacing: 0) {
            // Left side - Era name and description
            VStack(alignment: .trailing, spacing: 4) {
                Text(era.title.text(for: languageMode))
                    .font(languageMode == .kr
                        ? FontManager.koreanSans(size: 15, weight: .bold)
                        : .system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                Text(era.description.text(for: languageMode))
                    .font(languageMode == .kr
                        ? FontManager.koreanSans(size: 12, weight: .regular)
                        : .system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.leading, 4)
            
            // Center - White dot
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .frame(width: yearLabelWidth + 30)
            
            // Right side - Empty
            Spacer()
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
    }
    
    // Group items by year for aligned display
    private struct YearGroup: Equatable {
        let year: Int
        let displayYear: String
        let historicalEvents: [TimelineItem]
        let bibleBooks: [TimelineItem]
        
        static func == (lhs: YearGroup, rhs: YearGroup) -> Bool {
            lhs.year == rhs.year
        }
    }
    
    private func getYearGroupsForEra(_ era: TimelineItem) -> [YearGroup] {
        let itemsInEra = getItemsForEra(era)
        
        // Get unique years and sort them
        let uniqueYears = Set(itemsInEra.map { $0.startYear }).sorted()
        
        return uniqueYears.map { year in
            let itemsForYear = itemsInEra.filter { $0.startYear == year }
            let historicalEvents = itemsForYear.filter { $0.isHistoricalEvent }
            let bibleBooks = itemsForYear.filter { $0.isBibleBook }
            
            // Format year display
            let displayYear = year < 0 ? "BC \(abs(year))" : "AD \(year)"
            
            return YearGroup(
                year: year,
                displayYear: displayYear,
                historicalEvents: historicalEvents,
                bibleBooks: bibleBooks
            )
        }
    }
    
    // MARK: - Timeline Year Row (groups items by year)
    private func timelineYearRow(group: YearGroup) -> some View {
        HStack(alignment: .center, spacing: 0) {
            // Left side (Historical Events)
            if !group.historicalEvents.isEmpty {
                VStack(alignment: .trailing, spacing: 8) {
                    ForEach(group.historicalEvents, id: \.id) { item in
                        historyEventCard(item: item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
            
            // Center - Year indicator on axis
            yearIndicator(year: group.year, displayYear: group.displayYear, hasHistory: !group.historicalEvents.isEmpty, hasBible: !group.bibleBooks.isEmpty)
                .frame(width: yearLabelWidth + 30)
            
            // Right side (Bible Books) - use BookCell
            if !group.bibleBooks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(group.bibleBooks, id: \.id) { item in
                        if let book = findBibleBook(for: item) {
                            bibleBookCell(book: book)
                                .id("book_\(item.id)")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, verticalSpacing / 2)
    }
    
    // MARK: - Bible Book Cell (same style as BookCell in grid)
    private func bibleBookCell(book: BibleBook) -> some View {
        BookCell(
            book: book,
            language: languageMode,
            isSelected: book == currentBook
        )
        .frame(maxWidth: .infinity)
        .padding(.trailing, 4)
        .onTapGesture {
            onBookSelect?(book)
            HapticManager.shared.selection()
        }
    }
    
    // MARK: - History Event Card
    private func historyEventCard(item: TimelineItem) -> some View {
        Button {
            selectedItem = item
            HapticManager.shared.selection()
        } label: {
            if item.hasImage {
                // Image card (same style as BookCell)
                historyImageCard(item: item)
            } else {
                // Text-only card
                Text(item.title.text(for: languageMode))
                    .font(languageMode == .kr
                        ? FontManager.koreanSans(size: 12, weight: .regular)
                        : .system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.leading, 4)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - History Image Card
    private func historyImageCard(item: TimelineItem) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            // Image with rounded corners
            Image(item.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Title below image (same size as other history cards)
            Text(item.title.text(for: languageMode))
                .font(languageMode == .kr
                    ? FontManager.koreanSans(size: 12, weight: .regular)
                    : .system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    
    // MARK: - Year Indicator
    private func yearIndicator(year: Int, displayYear: String, hasHistory: Bool, hasBible: Bool) -> some View {
        Text(displayYear)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.vertical, 4)
            .background(Color.black)
    }
    
    // MARK: - Helper Methods
    
    private func loadData() {
        eras = TimelineService.shared.getEras()
        timelineItems = TimelineService.shared.getTimelineItems()
    }
    
    private func getItemsForEra(_ era: TimelineItem) -> [TimelineItem] {
        let eraIndex = eras.firstIndex { $0.id == era.id } ?? 0
        let nextEraStart: Int
        
        if eraIndex < eras.count - 1 {
            nextEraStart = eras[eraIndex + 1].startYear
        } else {
            nextEraStart = 200 // End of NT era
        }
        
        return filteredTimelineItems
            .filter { $0.startYear >= era.startYear && $0.startYear < nextEraStart }
            .sorted { $0.startYear < $1.startYear }
    }
    
    private func findBibleBook(for item: TimelineItem) -> BibleBook? {
        guard let bookId = item.bookId else { return nil }
        return BibleData.book(at: bookId)
    }
}

// MARK: - Preview

#Preview("Timeline Content") {
    ZStack {
        Color.black.ignoresSafeArea()
        BibleTimelineContentView(
            languageMode: .kr,
            topPadding: 100
        )
    }
}

#Preview("Full Timeline") {
    BibleTimelineView(
        languageMode: .kr,
        safeAreaTop: 59,
        safeAreaBottom: 34,
        onClose: {}
    )
}

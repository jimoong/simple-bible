//
//  FavoritesReadingView.swift
//  BibleApp
//
//  Reading view for favorite (liked) verses collection
//

import SwiftUI

struct FavoritesReadingView: View {
    let language: LanguageMode
    var safeAreaTop: CGFloat = 0
    var safeAreaBottom: CGFloat = 0
    let onClose: () -> Void
    var onBack: (() -> Void)? = nil
    let onNavigateToVerse: (FavoriteVerse) -> Void
    let onEditFavorite: (FavoriteVerse) -> Void
    @Binding var isFilterExpanded: Bool  // Expose to parent to hide back button
    @Binding var isInMultiSelectMode: Bool  // Expose to parent to hide back button
    var scrollToId: String? = nil  // Scroll to specific favorite on appear
    
    @State private var favorites: [FavoriteVerse] = []
    @State private var glowAnimating = false
    @State private var selectedBookFilter: String? = nil // nil = All
    
    // Multi-select mode
    @State private var isMultiSelectMode = false {
        didSet {
            isInMultiSelectMode = isMultiSelectMode
        }
    }
    @State private var selectedFavoriteIds: Set<String> = []
    @State private var showDeleteConfirmation = false
    @State private var showDeleteAllConfirmation = false
    
    // Compact view mode
    @State private var isCompactMode = false
    
    // Filtered favorites based on selection
    private var filteredFavorites: [FavoriteVerse] {
        guard let bookId = selectedBookFilter else {
            return favorites
        }
        return favorites.filter { $0.bookId == bookId }
    }
    
    // Time-based sections
    private var groupedFavorites: [(label: String, favorites: [FavoriteVerse])] {
        let now = Date()
        let calendar = Calendar.current
        
        // Define time boundaries
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday)!
        let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfToday)!
        let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfToday)!
        let startOf6MonthsAgo = calendar.date(byAdding: .month, value: -6, to: startOfToday)!
        let startOfLastYear = calendar.date(byAdding: .year, value: -1, to: startOfToday)!
        
        // "Just now" is within 5 minutes
        let fiveMinutesAgo = now.addingTimeInterval(-5 * 60)
        
        var sections: [(label: String, favorites: [FavoriteVerse])] = []
        
        // Sort favorites by likedAt descending (newest first)
        let sorted = filteredFavorites.sorted { $0.likedAt > $1.likedAt }
        
        // Group by time period
        var justNow: [FavoriteVerse] = []
        var today: [FavoriteVerse] = []
        var yesterday: [FavoriteVerse] = []
        var lastWeek: [FavoriteVerse] = []
        var lastMonth: [FavoriteVerse] = []
        var sixMonthsAgo: [FavoriteVerse] = []
        var lastYear: [FavoriteVerse] = []
        var older: [FavoriteVerse] = []
        
        for favorite in sorted {
            let date = favorite.likedAt
            
            if date >= fiveMinutesAgo {
                justNow.append(favorite)
            } else if date >= startOfToday {
                today.append(favorite)
            } else if date >= startOfYesterday {
                yesterday.append(favorite)
            } else if date >= startOfLastWeek {
                lastWeek.append(favorite)
            } else if date >= startOfLastMonth {
                lastMonth.append(favorite)
            } else if date >= startOf6MonthsAgo {
                sixMonthsAgo.append(favorite)
            } else if date >= startOfLastYear {
                lastYear.append(favorite)
            } else {
                older.append(favorite)
            }
        }
        
        // Build sections (only include non-empty ones)
        if !justNow.isEmpty {
            sections.append((label: language == .kr ? "방금" : "Just Now", favorites: justNow))
        }
        if !today.isEmpty {
            sections.append((label: language == .kr ? "오늘" : "Today", favorites: today))
        }
        if !yesterday.isEmpty {
            sections.append((label: language == .kr ? "어제" : "Yesterday", favorites: yesterday))
        }
        if !lastWeek.isEmpty {
            sections.append((label: language == .kr ? "지난 주" : "Last Week", favorites: lastWeek))
        }
        if !lastMonth.isEmpty {
            sections.append((label: language == .kr ? "지난 달" : "Last Month", favorites: lastMonth))
        }
        if !sixMonthsAgo.isEmpty {
            sections.append((label: language == .kr ? "6개월 전" : "6 Months Ago", favorites: sixMonthsAgo))
        }
        if !lastYear.isEmpty {
            sections.append((label: language == .kr ? "작년" : "Last Year", favorites: lastYear))
        }
        if !older.isEmpty {
            sections.append((label: language == .kr ? "오래 전" : "Older", favorites: older))
        }
        
        return sections
    }
    
    // Book counts for filter menu
    private var bookCounts: [(bookId: String, bookName: String, count: Int)] {
        var counts: [String: Int] = [:]
        var names: [String: String] = [:]
        
        for fav in favorites {
            counts[fav.bookId, default: 0] += 1
            if names[fav.bookId] == nil {
                names[fav.bookId] = fav.bookName(for: language)
            }
        }
        
        return counts.map { (bookId: $0.key, bookName: names[$0.key] ?? "", count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    var body: some View {
        ZStack {
            // Black background (app system view)
            Color.black
            
            if favorites.isEmpty {
                emptyView
            } else if filteredFavorites.isEmpty {
                // When filter returns no results
                noFilterResultsView
            } else {
                // Main content - favorites scroll view
                favoritesScrollView
            }
            
            // Bottom right button: Menu or Done
            if !favorites.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        if isMultiSelectMode {
                            // Done button - pill glass style
                            Button {
                                exitMultiSelectMode()
                            } label: {
                                Text(language == .kr ? "완료" : "Done")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.glass)
                            .padding(.trailing, 20)
                            .padding(.bottom, safeAreaBottom - 4)
                        } else {
                            // Menu button
                            Menu {
                                Button {
                                    enterMultiSelectMode()
                                } label: {
                                    Label(
                                        language == .kr ? "선택하기" : "Select",
                                        systemImage: "checkmark.circle"
                                    )
                                }
                                
                                Button {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        isCompactMode.toggle()
                                    }
                                } label: {
                                    Label(
                                        isCompactMode
                                            ? (language == .kr ? "크게 보기" : "Large View")
                                            : (language == .kr ? "작게 보기" : "Compact View"),
                                        systemImage: isCompactMode ? "rectangle.portrait" : "rectangle.grid.1x2"
                                    )
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    FavoriteService.shared.populateMockData()
                                    loadFavorites()
                                } label: {
                                    Label(language == .kr ? "테스트 데이터로 교체" : "Replace with Test Data", systemImage: "testtube.2")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 48, height: 48)
                            }
                            .buttonStyle(.glassCircle)
                            .padding(.trailing, 20)
                            .padding(.bottom, safeAreaBottom - 4)
                        }
                    }
                }
            }
            
            // Filter FAB - only show when not in multi-select mode
            if !favorites.isEmpty && !isMultiSelectMode {
                VStack {
                    Spacer()
                    FilterFAB(
                        language: language,
                        selectedBookId: $selectedBookFilter,
                        bookCounts: bookCounts,
                        totalCount: favorites.count,
                        isExpanded: $isFilterExpanded
                    )
                    .padding(.bottom, safeAreaBottom - 4)
                }
            }
            
            // Bottom delete button in multi-select mode (same position as filter FAB)
            if isMultiSelectMode {
                VStack {
                    Spacer()
                    deleteActionButton
                        .padding(.bottom, safeAreaBottom - 4)
                }
            }
        }
        .onAppear {
            loadFavorites()
        }
        .onChange(of: FavoriteService.shared.favorites) { _, _ in
            loadFavorites()
        }
        .confirmationDialog(
            language == .kr ? "모든 저장된 구절을 삭제하시겠습니까?" : "Delete all saved verses?",
            isPresented: $showDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button(language == .kr ? "모두 삭제" : "Delete All", role: .destructive) {
                deleteAllFavorites()
            }
            Button(language == .kr ? "취소" : "Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            language == .kr ? "선택한 \(selectedFavoriteIds.count)개의 구절을 삭제하시겠습니까?" : "Delete \(selectedFavoriteIds.count) selected verses?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(language == .kr ? "삭제" : "Delete", role: .destructive) {
                deleteSelectedFavorites()
            }
            Button(language == .kr ? "취소" : "Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - No Filter Results View
    private var noFilterResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white.opacity(0.3))
            
            Text(language == .kr
                 ? "필터 결과가 없습니다"
                 : "No results for this filter")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white.opacity(0.3))
            
            Text(language == .kr 
                 ? "아직 좋아요한 구절이 없습니다"
                 : "No favorite verses yet")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Text(language == .kr
                 ? "구절을 길게 눌러 좋아요를 추가하세요"
                 : "Long press on a verse to add it to favorites")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
            
            // Test data button
            Button {
                FavoriteService.shared.populateMockData()
                loadFavorites()
            } label: {
                Text(language == .kr ? "테스트 데이터 채우기" : "Add Test Data")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.glass)
            .padding(.top, 24)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Title Section (like bookshelf/timeline)
    private var titleSection: some View {
        ZStack {
            // Heart icon with glow
            Image(systemName: "heart.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 48, height: 48)
        .background(
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(glowAnimating ? 0.25 : 0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .blur(radius: 8)
                .scaleEffect(glowAnimating ? 1.15 : 1.0)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowAnimating = true
            }
        }
    }
    
    // MARK: - Favorites Scroll View
    private var favoritesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // Title - positioned below back button row
                    titleSection
                        .padding(.top, safeAreaTop + 72)
                    
                    // Favorites list (grouped by time)
                    LazyVStack(spacing: isCompactMode ? 4 : 10) {
                        ForEach(groupedFavorites, id: \.label) { section in
                            // Section header
                            sectionHeader(section.label)
                            
                            // Section items
                            ForEach(section.favorites) { favorite in
                                Group {
                                    if isCompactMode {
                                        CompactFavoriteRow(
                                            favorite: favorite,
                                            language: language,
                                            isMultiSelectMode: isMultiSelectMode,
                                            isSelected: selectedFavoriteIds.contains(favorite.id),
                                            onTap: {
                                                if isMultiSelectMode {
                                                    toggleSelection(favorite.id)
                                                } else {
                                                    onEditFavorite(favorite)
                                                }
                                            },
                                            onShare: {
                                                shareVerse(favorite)
                                            },
                                            onDelete: {
                                                deleteFavorite(favorite)
                                            }
                                        )
                                    } else {
                                        FavoriteVerseRow(
                                            favorite: favorite,
                                            language: language,
                                            isMultiSelectMode: isMultiSelectMode,
                                            isSelected: selectedFavoriteIds.contains(favorite.id),
                                            onTap: {
                                                if isMultiSelectMode {
                                                    toggleSelection(favorite.id)
                                                } else {
                                                    onEditFavorite(favorite)
                                                }
                                            },
                                            onShare: {
                                                shareVerse(favorite)
                                            },
                                            onDelete: {
                                                deleteFavorite(favorite)
                                            }
                                        )
                                    }
                                }
                                .id("\(favorite.id)_\(isCompactMode)")  // Force re-render on mode change
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .animation(.easeOut(duration: 0.25), value: isCompactMode)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: safeAreaBottom + 100)
            }
            .scrollIndicators(.visible)
            .onAppear {
                // Scroll to specific favorite if requested
                if let targetId = scrollToId {
                    // Delay to ensure ScrollView layout is complete on first load
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            proxy.scrollTo(targetId, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Section Header
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 4)
    }
    
    // MARK: - Helper Methods
    private func loadFavorites() {
        favorites = FavoriteService.shared.getAllFavorites()
    }
    
    private func deleteFavorite(_ favorite: FavoriteVerse) {
        withAnimation(.easeOut(duration: 0.25)) {
            FavoriteService.shared.removeFavorite(id: favorite.id)
            favorites = FavoriteService.shared.getAllFavorites()
        }
    }
    
    private func shareVerse(_ favorite: FavoriteVerse) {
        let text = favorite.text(for: language)
        let reference = favorite.referenceText(for: language)
        let shareText = "\(text)\n— \(reference)"
        
        // Present iOS native share sheet
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // Get the current window scene and present
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // Handle iPad popover
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootViewController.present(activityVC, animated: true)
        }
        HapticManager.shared.selection()
    }
    
    // MARK: - Multi-Select Mode
    private func enterMultiSelectMode() {
        withAnimation(.easeOut(duration: 0.2)) {
            isMultiSelectMode = true
            selectedFavoriteIds.removeAll()
        }
        HapticManager.shared.selection()
    }
    
    private func exitMultiSelectMode() {
        withAnimation(.easeOut(duration: 0.2)) {
            isMultiSelectMode = false
            selectedFavoriteIds.removeAll()
        }
        HapticManager.shared.selection()
    }
    
    private func toggleSelection(_ id: String) {
        if selectedFavoriteIds.contains(id) {
            selectedFavoriteIds.remove(id)
        } else {
            selectedFavoriteIds.insert(id)
        }
        HapticManager.shared.selection()
    }
    
    private func deleteSelectedFavorites() {
        withAnimation(.easeOut(duration: 0.25)) {
            for id in selectedFavoriteIds {
                FavoriteService.shared.removeFavorite(id: id)
            }
            favorites = FavoriteService.shared.getAllFavorites()
            selectedFavoriteIds.removeAll()
        }
        
        // Exit multi-select if no favorites left
        if favorites.isEmpty {
            exitMultiSelectMode()
        }
        HapticManager.shared.success()
    }
    
    private func deleteAllFavorites() {
        withAnimation(.easeOut(duration: 0.25)) {
            for favorite in filteredFavorites {
                FavoriteService.shared.removeFavorite(id: favorite.id)
            }
            favorites = FavoriteService.shared.getAllFavorites()
            selectedFavoriteIds.removeAll()
        }
        exitMultiSelectMode()
        HapticManager.shared.success()
    }
    
    // MARK: - Delete Action Button
    private var deleteActionButton: some View {
        Button {
            if selectedFavoriteIds.isEmpty {
                showDeleteAllConfirmation = true
            } else {
                showDeleteConfirmation = true
            }
        } label: {
            HStack(spacing: 6) {
                Text(language == .kr ? (selectedFavoriteIds.isEmpty ? "모두 삭제" : "삭제") : (selectedFavoriteIds.isEmpty ? "Delete All" : "Delete"))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                
                if !selectedFavoriteIds.isEmpty {
                    Text("\(selectedFavoriteIds.count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.white.opacity(0.12))
                        )
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
        }
        .buttonStyle(.glass)
    }
}

// MARK: - Favorite Verse Row
struct FavoriteVerseRow: View {
    let favorite: FavoriteVerse
    let language: LanguageMode
    var isMultiSelectMode: Bool = false
    var isSelected: Bool = false
    let onTap: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    
    @ObservedObject private var fontSizeSettings = FontSizeSettings.shared
    
    // Get the specific book's theme - used for card styling (matches FavoriteNoteOverlay)
    private var bookTheme: BookTheme {
        BookThemes.theme(for: favorite.bookId)
    }
    
    // Font size: passages use scroll mode fixed size, single verses use dynamic sizing
    private var fontSize: CGFloat {
        // Passages (multi-verse) always use scroll mode settings
        if favorite.isPassage {
            return fontSizeSettings.mode.scrollBodySize
        }
        
        // Single verse: dynamic font sizing based on character count (tap mode style)
        let text = favorite.text(for: language)
        let count = text.count
        
        if language == .kr {
            if count > 300 { return 17 }
            if count > 225 { return 18 }
            if count > 160 { return 20 }
            if count > 35  { return 24 }
            return 30
        } else {
            if count > 600 { return 17 }
            if count > 450 { return 18 }
            if count > 320 { return 20 }
            if count > 200 { return 24 }
            if count > 70  { return 28 }
            return 32
        }
    }
    
    private var verseLineSpacing: CGFloat {
        // Passages (multi-verse) always use scroll mode settings
        if favorite.isPassage {
            return fontSizeSettings.mode.scrollLineSpacing
        }
        
        // Single verse: dynamic line spacing
        let text = favorite.text(for: language)
        let count = text.count
        
        if language == .kr {
            if count > 225 { return 6 }
            if count > 160 { return 8 }
            if count > 35  { return 12 }
            return 14
        } else {
            if count > 450 { return 5 }
            if count > 320 { return 6 }
            if count > 200 { return 7 }
            if count > 70  { return 9 }
            return 11
        }
    }
    
    // Parse verse text into paragraphs (for non-continuous display)
    private var verseParagraphs: [String] {
        favorite.text(for: language).components(separatedBy: "\n\n")
    }
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Reference
                Text(favorite.referenceText(for: language))
                    .font(bookTheme.verseNumber(12, language: language))
                    .foregroundStyle(bookTheme.textSecondary.opacity(0.6))
                
                // Verse text - show with spacing for non-continuous passages
                if favorite.isNonContinuous,
                   let verseNumbers = favorite.verseNumbers,
                   verseParagraphs.count == verseNumbers.count {
                    // Non-continuous: show each verse with number on right (scroll mode layout)
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(verseParagraphs.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 4) {
                                Text(verseParagraphs[index])
                                    .font(bookTheme.verseText(fontSize, language: language))
                                    .foregroundStyle(bookTheme.textPrimary)
                                    .lineSpacing(verseLineSpacing)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("\(verseNumbers[index])")
                                    .font(bookTheme.verseNumber(12, language: language))
                                    .foregroundStyle(bookTheme.textSecondary.opacity(0.6))
                                    .frame(width: 18, alignment: .trailing)
                            }
                        }
                    }
                } else {
                    // Single verse or continuous passage - normal display
                    Text(favorite.text(for: language))
                        .font(bookTheme.verseText(fontSize, language: language))
                        .foregroundStyle(bookTheme.textPrimary)
                        .lineSpacing(verseLineSpacing)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Note (if exists) - no icon, just text
                if let note = favorite.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 14))
                        .foregroundStyle(bookTheme.textSecondary.opacity(0.8))
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 16)
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 60)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(bookTheme.background)
            )
            .overlay(alignment: .topLeading) {
                // Selection checkbox in multi-select mode
                if isMultiSelectMode {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.white : Color.clear)
                            .frame(width: 28, height: 28)
                        
                        Circle()
                            .stroke(Color.white.opacity(isSelected ? 0 : 0.5), lineWidth: 2)
                            .frame(width: 28, height: 28)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(bookTheme.background)
                        }
                    }
                    .padding(16)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu(isMultiSelectMode ? nil : ContextMenu {
            Button {
                onShare()
            } label: {
                Label(
                    language == .kr ? "공유" : "Share",
                    systemImage: "square.and.arrow.up"
                )
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(
                    language == .kr ? "삭제" : "Delete",
                    systemImage: "trash"
                )
            }
        })
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Compact Favorite Row (ChapterToast style)
struct CompactFavoriteRow: View {
    let favorite: FavoriteVerse
    let language: LanguageMode
    var isMultiSelectMode: Bool = false
    var isSelected: Bool = false
    let onTap: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void
    
    // Get the specific book's theme
    private var bookTheme: BookTheme {
        BookThemes.theme(for: favorite.bookId)
    }
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                // Selection checkbox (only in multi-select mode)
                if isMultiSelectMode {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.white : Color.clear)
                            .frame(width: 24, height: 24)
                        
                        Circle()
                            .stroke(Color.white.opacity(isSelected ? 0 : 0.4), lineWidth: 1.5)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(bookTheme.surface)
                        }
                    }
                }
                
                // Content - slides right in multi-select mode
                VStack(alignment: .leading, spacing: 6) {
                    // Reference (secondary text)
                    Text(favorite.referenceText(for: language))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(bookTheme.textSecondary)
                    
                    // Verse text (max 2 lines)
                    Text(favorite.text(for: language))
                        .font(bookTheme.verseText(14, language: language))
                        .foregroundStyle(bookTheme.textPrimary)
                        .lineLimit(2)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, isMultiSelectMode ? 16 : 0)
                .transaction { transaction in
                    // Disable text reflow animation - only animate position
                    transaction.animation = nil
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(bookTheme.background)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu(isMultiSelectMode ? nil : ContextMenu {
            Button {
                onShare()
            } label: {
                Label(
                    language == .kr ? "공유" : "Share",
                    systemImage: "square.and.arrow.up"
                )
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(
                    language == .kr ? "삭제" : "Delete",
                    systemImage: "trash"
                )
            }
        })
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .animation(.easeOut(duration: 0.2), value: isMultiSelectMode)
    }
}

// MARK: - Filter FAB
struct FilterFAB: View {
    let language: LanguageMode
    @Binding var selectedBookId: String?
    let bookCounts: [(bookId: String, bookName: String, count: Int)]
    let totalCount: Int
    @Binding var isExpanded: Bool
    
    @State private var searchText = ""
    
    // Layout constants (collapsedHeight matches actionButton in ContentView)
    private let collapsedHeight: CGFloat = 48
    private let expandedWidth: CGFloat = 260
    private let expandedMaxHeight: CGFloat = 380
    private let menuItemHeight: CGFloat = 44
    
    // Filtered books for search
    private var filteredBookCounts: [(bookId: String, bookName: String, count: Int)] {
        guard !searchText.isEmpty else { return bookCounts }
        return bookCounts.filter { $0.bookName.localizedCaseInsensitiveContains(searchText) }
    }
    
    // Current display label
    private var displayLabel: String {
        if let bookId = selectedBookId,
           let book = bookCounts.first(where: { $0.bookId == bookId }) {
            return book.bookName
        }
        return language == .kr ? "전체" : "All"
    }
    
    // Current count
    private var displayCount: Int {
        if let bookId = selectedBookId,
           let book = bookCounts.first(where: { $0.bookId == bookId }) {
            return book.count
        }
        return totalCount
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if isExpanded {
                // Backdrop to dismiss
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeMenu()
                    }
            }
            
            // FAB/Menu container
            VStack(spacing: 0) {
                if isExpanded {
                    expandedMenu
                } else {
                    collapsedFAB
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isExpanded)
        }
    }
    
    // MARK: - Collapsed FAB
    private var collapsedFAB: some View {
        Button {
            openMenu()
        } label: {
            HStack(spacing: 6) {
                Text(displayLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                
                Text("\(displayCount)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.12))
                    )
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(.horizontal, 14)
            .frame(height: collapsedHeight)
            .fixedSize(horizontal: true, vertical: false)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: .black.opacity(0.25),
                radius: 8,
                y: 4
            )
        }
        .buttonStyle(FilterFABButtonStyle())
    }
    
    // MARK: - Expanded Menu
    private var expandedMenu: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                
                TextField(
                    language == .kr ? "찾기" : "Search",
                    text: $searchText
                )
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .tint(.white)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(0.08))
            )
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Divider()
                .background(.white.opacity(0.1))
                .padding(.horizontal, 12)
            
            // Menu items
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // "All" option
                    filterMenuItem(
                        label: language == .kr ? "전체" : "All",
                        count: totalCount,
                        isSelected: selectedBookId == nil
                    ) {
                        selectFilter(nil)
                    }
                    
                    // Book options
                    ForEach(filteredBookCounts, id: \.bookId) { item in
                        filterMenuItem(
                            label: item.bookName,
                            count: item.count,
                            isSelected: selectedBookId == item.bookId
                        ) {
                            selectFilter(item.bookId)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
            .frame(maxHeight: expandedMaxHeight - 80) // Account for search field
        }
        .frame(width: expandedWidth)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: .black.opacity(0.35),
            radius: 16,
            y: 8
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9, anchor: .bottomTrailing).combined(with: .opacity),
            removal: .scale(scale: 0.95, anchor: .bottomTrailing).combined(with: .opacity)
        ))
    }
    
    // MARK: - Filter Menu Item
    private func filterMenuItem(
        label: String,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 12) {
                // Checkmark for selected item
                Image(systemName: isSelected ? "checkmark" : "")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 20)
                
                Text(label)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(.white.opacity(isSelected ? 1.0 : 0.85))
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(.white.opacity(isSelected ? 0.15 : 0.08))
                    )
            }
            .padding(.horizontal, 14)
            .frame(height: menuItemHeight)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(isSelected ? 0.1 : 0))
            )
            .padding(.horizontal, 6)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helpers
    private func openMenu() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            isExpanded = true
        }
        HapticManager.shared.selection()
    }
    
    private func closeMenu() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            isExpanded = false
        }
        searchText = ""
    }
    
    private func selectFilter(_ bookId: String?) {
        selectedBookId = bookId
        closeMenu()
        HapticManager.shared.selection()
    }
}

// MARK: - Filter FAB Button Style
private struct FilterFABButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    FavoritesReadingView(
        language: .kr,
        onClose: {},
        onNavigateToVerse: { _ in },
        onEditFavorite: { _ in },
        isFilterExpanded: .constant(false),
        isInMultiSelectMode: .constant(false)
    )
}

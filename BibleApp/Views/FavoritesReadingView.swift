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
    var scrollToId: String? = nil  // Scroll to specific favorite on appear
    
    @State private var favorites: [FavoriteVerse] = []
    @State private var glowAnimating = false
    @State private var selectedBookFilter: String? = nil // nil = All
    
    // Filtered favorites based on selection
    private var filteredFavorites: [FavoriteVerse] {
        guard let bookId = selectedBookFilter else {
            return favorites
        }
        return favorites.filter { $0.bookId == bookId }
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
            
            // Filter FAB - only show when there are favorites
            // Positioned to align with the back button from ContentView
            if !favorites.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FilterFAB(
                            language: language,
                            selectedBookId: $selectedBookFilter,
                            bookCounts: bookCounts,
                            totalCount: favorites.count,
                            isExpanded: $isFilterExpanded
                        )
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, safeAreaBottom - 4)
                }
            }
        }
        .onAppear {
            loadFavorites()
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
                    // Title (same position as bookshelf)
                    titleSection
                        .padding(.top, safeAreaTop + 16)
                    
                    // Favorites list (filtered)
                    LazyVStack(spacing: 10) {
                        ForEach(filteredFavorites) { favorite in
                            FavoriteVerseRow(
                                favorite: favorite,
                                language: language,
                                onTap: {
                                    onNavigateToVerse(favorite)
                                },
                                onCopy: {
                                    copyVerse(favorite)
                                },
                                onEdit: {
                                    onEditFavorite(favorite)
                                },
                                onDelete: {
                                    deleteFavorite(favorite)
                                }
                            )
                            .id(favorite.id)  // For ScrollViewReader
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .padding(.bottom, safeAreaBottom + 100)
            }
            .scrollIndicators(.visible)
            .onAppear {
                // Scroll to specific favorite if requested
                if let targetId = scrollToId {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            proxy.scrollTo(targetId, anchor: .center)
                        }
                    }
                }
            }
        }
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
    
    private func copyVerse(_ favorite: FavoriteVerse) {
        let text = favorite.text(for: language)
        let reference = favorite.referenceText(for: language)
        UIPasteboard.general.string = "\(text)\n— \(reference)"
        HapticManager.shared.success()
    }
}

// MARK: - Favorite Verse Row
struct FavoriteVerseRow: View {
    let favorite: FavoriteVerse
    let language: LanguageMode
    let onTap: () -> Void
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    // Get the specific book's theme - used for card styling (matches FavoriteNoteOverlay)
    private var bookTheme: BookTheme {
        BookThemes.theme(for: favorite.bookId)
    }
    
    // Dynamic font sizing based on character count (same as tap mode)
    private var fontSize: CGFloat {
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
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Reference
                Text(favorite.referenceText(for: language))
                    .font(bookTheme.verseNumber(12, language: language))
                    .foregroundStyle(bookTheme.textSecondary.opacity(0.6))
                
                // Verse text - dynamic font size based on length
                Text(favorite.text(for: language))
                    .font(bookTheme.verseText(fontSize, language: language))
                    .foregroundStyle(bookTheme.textPrimary)
                    .lineSpacing(verseLineSpacing)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
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
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onCopy()
            } label: {
                Label(
                    language == .kr ? "복사" : "Copy",
                    systemImage: "doc.on.doc"
                )
            }
            
            Button {
                onEdit()
            } label: {
                Label(
                    language == .kr ? "수정" : "Edit",
                    systemImage: "pencil"
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
        }
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
        isFilterExpanded: .constant(false)
    )
}

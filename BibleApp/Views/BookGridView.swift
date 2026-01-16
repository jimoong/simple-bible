import SwiftUI

struct BookGridView: View {
    @Bindable var viewModel: BibleViewModel
    @Binding var searchText: String
    var maxHeight: CGFloat = .infinity
    var safeAreaTop: CGFloat = 0
    var safeAreaBottom: CGFloat = 0
    var topPadding: CGFloat = 0  // Space for elements above
    var isFullscreen: Bool = false
    var startInSearchMode: Bool = false  // Start with search active and keyboard open
    var onClose: (() -> Void)? = nil
    var onBookSelect: ((BibleBook) -> Void)? = nil
    var onFavoritesSelect: (() -> Void)? = nil
    var onNavigate: ((BibleBook, Int, Int?) -> Void)? = nil  // Called when search navigates: (book, chapter, verse?)
    
    @State private var isSearchActive = false
    @FocusState private var isSearchFocused: Bool
    @State private var glowAnimating = false
    @State private var searchSelectedBook: BibleBook? = nil  // Book selected via search autocomplete
    @State private var searchSelectedChapter: Int? = nil     // Chapter selected via search autocomplete
    @State private var searchSelectedVerse: Int? = nil       // Verse selected via search autocomplete
    @State private var searchVerses: [BibleVerse] = []       // Loaded verses for verse selection
    @State private var isLoadingVerses: Bool = false
    @State private var bookGridScrollTrigger: Bool = false   // Trigger to scroll book grid
    @State private var bookGridScrollToBottom: Bool = true   // true = scroll to bottom, false = scroll to top
    @State private var timelineScrollTrigger: Bool = false   // Trigger to scroll timeline
    @State private var timelineScrollToBottom: Bool = true   // true = scroll to bottom, false = scroll to top
    @State private var keyboardHeight: CGFloat = 0          // Current keyboard height
    
    // Bottom padding for search mode content (accounts for keyboard + search bar)
    private var searchModeBottomPadding: CGFloat {
        let searchBarHeight: CGFloat = 72  // Search bar + padding
        let baseBottom: CGFloat = 120
        
        if keyboardHeight > 0 {
            // Keyboard is visible: keyboard height + search bar height
            return keyboardHeight + searchBarHeight
        } else {
            return baseBottom
        }
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    // 2-column layout for list view (목차순) - centered items with equal spacing
    private let listColumns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    // Each cell is ~70pt height + 10pt spacing
    private let cellHeight: CGFloat = 70
    private let cellSpacing: CGFloat = 10
    private let headerHeight: CGFloat = 60
    
    // Chapter grid columns (5 columns like ChapterGridView)
    private let chapterColumns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
    
    // Theme for search selected book
    private var searchBookTheme: BookTheme? {
        guard let book = searchSelectedBook else { return nil }
        return BookThemes.theme(for: book.id)
    }
    
    // MARK: - Search Text Parsing
    
    /// Extract the chapter number query from search text (after book name)
    private var chapterNumberQuery: String? {
        guard let book = searchSelectedBook else { return nil }
        let bookName = book.name(for: viewModel.uiLanguage)
        let prefix = bookName + " "
        
        guard searchText.hasPrefix(prefix) else { return nil }
        let afterBook = String(searchText.dropFirst(prefix.count))
        
        // If chapter is already selected (has "장 " or just space after number in English)
        if searchSelectedChapter != nil {
            return nil
        }
        
        // Extract only digits from remaining text
        let digits = afterBook.filter { $0.isNumber }
        return digits.isEmpty ? nil : digits
    }
    
    /// Extract the verse number query from search text (after chapter)
    private var verseNumberQuery: String? {
        guard let book = searchSelectedBook,
              let chapter = searchSelectedChapter else { return nil }
        
        let bookName = book.name(for: viewModel.uiLanguage)
        let chapterSuffix = viewModel.uiLanguage == .kr ? "장 " : " "
        let expectedPrefix = "\(bookName) \(chapter)\(chapterSuffix)"
        
        guard searchText.hasPrefix(expectedPrefix) else { return nil }
        
        // If verse is already selected, no more query
        if searchSelectedVerse != nil {
            return nil
        }
        
        let afterChapter = String(searchText.dropFirst(expectedPrefix.count))
        let digits = afterChapter.filter { $0.isNumber }
        return digits.isEmpty ? nil : digits
    }
    
    /// Filtered chapters based on number query
    private var filteredChapters: [Int] {
        guard let book = searchSelectedBook else { return [] }
        let allChapters = Array(1...book.chapterCount)
        
        guard let query = chapterNumberQuery, !query.isEmpty else {
            return allChapters
        }
        
        return allChapters.filter { String($0).hasPrefix(query) }
    }
    
    /// Filtered verses based on number query
    private var filteredVerses: [BibleVerse] {
        guard searchSelectedChapter != nil else { return [] }
        
        // If verse is already selected, show only that verse
        if let selectedVerse = searchSelectedVerse {
            return searchVerses.filter { $0.verseNumber == selectedVerse }
        }
        
        guard let query = verseNumberQuery, !query.isEmpty else {
            return searchVerses
        }
        
        return searchVerses.filter { String($0.verseNumber).hasPrefix(query) }
    }
    
    var filteredBooks: [BibleBook] {
        let sorted = viewModel.sortedBooks
        
        if searchText.isEmpty {
            return sorted
        }
        
        return sorted.filter { book in
            // 영어 검색
            book.nameEn.localizedCaseInsensitiveContains(searchText) ||
            // 한글 초성/부분 검색
            KoreanSearchHelper.matches(query: searchText, target: book.nameKr) ||
            // 한글 약어 매칭
            KoreanSearchHelper.matches(query: searchText, target: book.abbrKr)
        }
    }
    
    var oldTestamentBooks: [BibleBook] {
        filteredBooks.filter { $0.isOldTestament }
    }
    
    var newTestamentBooks: [BibleBook] {
        filteredBooks.filter { $0.isNewTestament }
    }
    
    // Calculate content height based on number of rows (including safe area)
    private var contentHeight: CGFloat {
        let bookCount = filteredBooks.count
        let rowCount = ceil(Double(bookCount) / 3.0)
        let gridHeight = CGFloat(rowCount) * cellHeight + CGFloat(max(0, rowCount - 1)) * cellSpacing
        let totalHeight = safeAreaTop + headerHeight + gridHeight + 20  // 20 for bottom padding
        return min(totalHeight, maxHeight)
    }
    
    var body: some View {
        if isFullscreen {
            fullscreenView
        } else {
            compactView
        }
    }
    
    // MARK: - Fullscreen View (for books grid)
    private var fullscreenView: some View {
        ZStack(alignment: .bottom) {
            // Content area - switches between book grid and timeline
            if viewModel.sortOrder == .timeline && !isSearchActive {
                // Timeline content (scrollable) - hidden during search
                BibleTimelineContentView(
                    languageMode: viewModel.uiLanguage,
                    topPadding: topPadding,
                    currentBook: viewModel.currentBook,
                    searchText: searchText,
                    scrollTrigger: $timelineScrollTrigger,
                    scrollToBottom: $timelineScrollToBottom,
                    onBookSelect: { book in
                        // Navigate to chapter grid when tapped in timeline
                        if let onBookSelect {
                            onBookSelect(book)
                        } else {
                            viewModel.selectBook(book)
                        }
                    }
                )
                .transition(.opacity)
            } else if isSearchActive {
                // Search mode: minimal UI with only book grid
                searchModeContent
                    .transition(.opacity)
            } else {
                // Normal mode: Books grid with sections (title scrolls with content)
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Top anchor for scroll-to-top
                            Color.clear
                                .frame(height: 1)
                                .id("bookGridTop")
                            
                            // Title (scrollable)
                            titleBar
                                .padding(.top, topPadding + 16)
                            
                            // Favorites section (only if has favorites)
                            if FavoriteService.shared.hasFavorites && searchText.isEmpty {
                                favoritesSection
                                    .padding(.top, 24)
                            }
                            
                            // Old Testament section
                            if !oldTestamentBooks.isEmpty {
                                bookSection(
                                    title: viewModel.uiLanguage == .kr ? "구약" : "Old Testament",
                                    books: oldTestamentBooks
                                )
                                .padding(.top, 24)
                            }
                            
                            // New Testament section
                            if !newTestamentBooks.isEmpty {
                                bookSection(
                                    title: viewModel.uiLanguage == .kr ? "신약" : "New Testament",
                                    books: newTestamentBooks
                                )
                                .padding(.top, 24)
                            }
                            
                            // Bottom anchor for scroll-to-bottom
                            Color.clear
                                .frame(height: 1)
                                .id("bookGridBottom")
                        }
                        .padding(.bottom, 120)  // Space for bottom controls
                    }
                    .onChange(of: bookGridScrollTrigger) { _, _ in
                        withAnimation(.easeOut(duration: 0.4)) {
                            if bookGridScrollToBottom {
                                proxy.scrollTo("bookGridBottom", anchor: .bottom)
                            } else {
                                proxy.scrollTo("bookGridTop", anchor: .top)
                            }
                        }
                    }
                }
                .transition(.opacity)
            }
            
            // Bottom bar - always visible
            bottomBar
                .padding(.horizontal, keyboardHeight > 0 ? 8 : 28)
                .padding(.bottom, safeAreaBottom - 4 + (keyboardHeight > 0 ? 12 : 0))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(searchBookTheme?.background ?? Color.black)
        .animation(.easeOut(duration: 0.3), value: viewModel.sortOrder)
        .animation(.easeOut(duration: 0.3), value: isSearchActive)
        .onAppear {
            if startInSearchMode && !isSearchActive {
                activateSearchMode()
            }
        }
        .onChange(of: startInSearchMode) { _, newValue in
            if newValue && !isSearchActive {
                activateSearchMode()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }
    
    /// Activate search mode with keyboard focus
    private func activateSearchMode() {
        isSearchActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isSearchFocused = true
        }
    }
    
    // MARK: - Search Mode Content (minimal UI)
    private var searchModeContent: some View {
        Group {
            if let selectedBook = searchSelectedBook, let theme = searchBookTheme {
                if searchSelectedChapter != nil {
                    // Verse selection mode - show verse list
                    searchVerseList(book: selectedBook, theme: theme)
                } else {
                    // Chapter selection mode - show chapter grid with book's theme
                    searchChapterGrid(book: selectedBook, theme: theme)
                }
            } else {
                // Book selection mode - show filtered books
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(filteredBooks) { book in
                            BookCell(
                                book: book,
                                language: viewModel.uiLanguage,
                                isSelected: book == viewModel.currentBook
                            )
                            .onTapGesture {
                                if let onBookSelect {
                                    onBookSelect(book)
                                } else {
                                    viewModel.selectBook(book)
                                }
                                HapticManager.shared.selection()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, topPadding + 20)
                    .padding(.bottom, searchModeBottomPadding)
                }
            }
        }
    }
    
    // MARK: - Search Chapter Grid (with book's theme)
    private func searchChapterGrid(book: BibleBook, theme: BookTheme) -> some View {
        let isFiltering = chapterNumberQuery != nil && !chapterNumberQuery!.isEmpty
        let firstFilteredChapter = filteredChapters.first
        
        return ScrollView {
            LazyVGrid(columns: chapterColumns, spacing: 10) {
                ForEach(filteredChapters, id: \.self) { chapter in
                    let isFirstFiltered = isFiltering && chapter == firstFilteredChapter
                    
                    Text("\(chapter)")
                        .font(.system(size: 18, weight: book == viewModel.currentBook && chapter == viewModel.currentChapter ? .bold : .medium))
                        .foregroundStyle(
                            book == viewModel.currentBook && chapter == viewModel.currentChapter
                                ? theme.background
                                : (ReadingProgressTracker.shared.isChapterRead(bookId: book.id, chapter: chapter)
                                    ? theme.textPrimary.opacity(0.6)
                                    : theme.textPrimary)
                        )
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(chapterCellBackground(book: book, chapter: chapter, theme: theme))
                        )
                        .overlay(
                            // Highlight first filtered item
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isFirstFiltered ? theme.accent.opacity(0.15) : Color.clear)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // Navigate to selected chapter
                            HapticManager.shared.selection()
                            onClose?()
                            Task {
                                await viewModel.navigateTo(book: book, chapter: chapter)
                                onNavigate?(book, chapter, nil)  // Call after navigation completes
                            }
                        }
                }
            }
            .frame(maxWidth: 350)
            .frame(maxWidth: .infinity)
            .padding(.top, topPadding + 20)
            .padding(.bottom, searchModeBottomPadding)
        }
    }
    
    /// Background color for chapter cell
    private func chapterCellBackground(book: BibleBook, chapter: Int, theme: BookTheme) -> Color {
        let isCurrentChapter = book == viewModel.currentBook && chapter == viewModel.currentChapter
        let isRead = ReadingProgressTracker.shared.isChapterRead(bookId: book.id, chapter: chapter)
        
        if isCurrentChapter {
            return theme.accent
        } else if isRead {
            return Color.black.opacity(0.3)
        } else {
            return theme.surface
        }
    }
    
    // MARK: - Search Verse List
    private func searchVerseList(book: BibleBook, theme: BookTheme) -> some View {
        let isFiltering = verseNumberQuery != nil && !verseNumberQuery!.isEmpty
        let firstFilteredVerse = filteredVerses.first
        
        return ScrollView {
            if isLoadingVerses {
                ProgressView()
                    .tint(theme.textSecondary)
                    .padding(.top, 100)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(filteredVerses) { verse in
                        let isFirstFiltered = isFiltering && verse.verseNumber == firstFilteredVerse?.verseNumber
                        
                        searchVerseRow(verse: verse, theme: theme, isHighlighted: isFirstFiltered)
                            .onTapGesture {
                                // Navigate to selected verse
                                HapticManager.shared.selection()
                                viewModel.isNavigating = true  // Set before closing to prevent race condition
                                onClose?()
                                Task {
                                    await viewModel.navigateTo(book: book, chapter: verse.chapter, verse: verse.verseNumber)
                                    onNavigate?(book, verse.chapter, verse.verseNumber)  // Call after navigation completes
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, topPadding + 20)
        .padding(.bottom, searchModeBottomPadding)
    }
    
    // MARK: - Search Verse Row (single line with ellipsis)
    private func searchVerseRow(verse: BibleVerse, theme: BookTheme, isHighlighted: Bool = false) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Verse number (full opacity for better legibility)
            Text("\(verse.verseNumber)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textSecondary)
                .frame(width: 28, alignment: .trailing)
            
            // Verse text (single line with ellipsis)
            Text(verse.text(for: viewModel.languageMode))
                .font(theme.verseText(16, language: viewModel.languageMode))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHighlighted ? theme.accent.opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
    }
    
    // MARK: - Bottom Bar (iOS Photos style)
    private var bottomBar: some View {
        Group {
            if isSearchActive {
                // Search mode: Search input + close button
                searchInputBar
            } else {
                // Normal mode: Close + Segmented + Search
                normalBottomBar
            }
        }
    }
    
    // MARK: - Normal Bottom Bar
    private var normalBottomBar: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Close button (left)
            Button {
                onClose?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.glassCircle)
            
            // Segmented sort control - fills remaining space
            sortSegmentedControl
            
            // Search button (right)
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    isSearchActive = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
                HapticManager.shared.selection()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.glassCircle)
        }
    }
    
    // MARK: - Search Input Bar
    private var searchInputBar: some View {
        HStack(spacing: 12) {
            // Search input field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                
                TextField(
                    viewModel.uiLanguage == .kr ? "검색" : "Search",
                    text: $searchText
                )
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .focused($isSearchFocused)
                .onSubmit {
                    // Enter/Return: Navigate based on current search state
                    handleSearchEnter()
                }
                .onChange(of: searchText) { oldValue, newValue in
                    // Spacebar: Autocomplete
                    let didAutocomplete = handleSpacebarAutocomplete(oldValue: oldValue, newValue: newValue)
                    
                    // If text is modified (and not from autocomplete), reset states as needed
                    if !didAutocomplete {
                        validateAndResetSearchState(newValue: newValue)
                    }
                }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        resetAllSearchState()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .glassBackground(.capsule, intensity: .regular)
            
            // Close search button
            Button {
                if startInSearchMode {
                    // Came from reading view search button - go back to reading view
                    onClose?()
                } else {
                    // Came from bookshelf - just exit search mode
                    withAnimation(.easeOut(duration: 0.25)) {
                        isSearchActive = false
                        searchText = ""
                        isSearchFocused = false
                    }
                    resetAllSearchState()
                }
                HapticManager.shared.selection()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.glassCircle)
        }
    }
    
    /// Reset all search-related state
    private func resetAllSearchState() {
        searchSelectedBook = nil
        searchSelectedChapter = nil
        searchSelectedVerse = nil
        searchVerses = []
        isLoadingVerses = false
    }
    
    // MARK: - Search Keyboard Helpers
    
    /// Navigate based on current search state (Enter key)
    private func handleSearchEnter() {
        guard let book = searchSelectedBook else {
            // Book selection mode - navigate to first filtered book
            guard let firstBook = filteredBooks.first else { return }
            HapticManager.shared.selection()
            if let onBookSelect {
                onBookSelect(firstBook)
            } else {
                viewModel.selectBook(firstBook)
            }
            return
        }
        
        if let chapter = searchSelectedChapter {
            // Verse or chapter+verse selection mode
            let targetVerse = searchSelectedVerse ?? filteredVerses.first?.verseNumber ?? 1
            HapticManager.shared.selection()
            viewModel.isNavigating = true  // Set before closing to prevent race condition
            onClose?()
            Task {
                await viewModel.navigateTo(book: book, chapter: chapter, verse: targetVerse)
                onNavigate?(book, chapter, targetVerse)  // Call after navigation completes
            }
        } else {
            // Chapter selection mode - navigate to first filtered chapter
            guard let firstChapter = filteredChapters.first else { return }
            HapticManager.shared.selection()
            onClose?()
            Task {
                await viewModel.navigateTo(book: book, chapter: firstChapter)
                onNavigate?(book, firstChapter, nil)  // Call after navigation completes
            }
        }
    }
    
    /// Autocomplete search text when spacebar is pressed
    /// Returns true if autocomplete was performed
    @discardableResult
    private func handleSpacebarAutocomplete(oldValue: String, newValue: String) -> Bool {
        // Check if user just typed a space
        guard newValue.hasSuffix(" "),
              !oldValue.hasSuffix(" "),
              !oldValue.isEmpty else { return false }
        
        // Stage 3: Verse autocomplete (after chapter is selected)
        if let book = searchSelectedBook, let chapter = searchSelectedChapter, searchSelectedVerse == nil {
            // Check if we're in verse selection mode (after chapter autocomplete)
            let bookName = book.name(for: viewModel.uiLanguage)
            let chapterSuffix = viewModel.uiLanguage == .kr ? "장 " : " "
            let chapterPrefix = "\(bookName) \(chapter)\(chapterSuffix)"
            
            if newValue.hasPrefix(chapterPrefix) {
                let afterChapter = String(newValue.dropFirst(chapterPrefix.count).dropLast()) // remove trailing space
                let digits = afterChapter.filter { $0.isNumber }
                
                if !digits.isEmpty, let firstVerse = filteredVerses.first {
                    let verseSuffix = viewModel.uiLanguage == .kr ? "절 " : " "
                    searchText = "\(chapterPrefix)\(firstVerse.verseNumber)\(verseSuffix)"
                    searchSelectedVerse = firstVerse.verseNumber
                    HapticManager.shared.selection()
                    return true
                }
            }
            return false
        }
        
        // Stage 2: Chapter autocomplete (after book is selected)
        if let book = searchSelectedBook, searchSelectedChapter == nil {
            let bookName = book.name(for: viewModel.uiLanguage)
            let bookPrefix = bookName + " "
            
            if newValue.hasPrefix(bookPrefix) {
                let afterBook = String(newValue.dropFirst(bookPrefix.count).dropLast()) // remove trailing space
                let digits = afterBook.filter { $0.isNumber }
                
                if !digits.isEmpty, let firstChapter = filteredChapters.first {
                    let chapterSuffix = viewModel.uiLanguage == .kr ? "장 " : " "
                    searchText = "\(bookPrefix)\(firstChapter)\(chapterSuffix)"
                    searchSelectedChapter = firstChapter
                    
                    // Load verses for this chapter
                    loadVersesForChapter(book: book, chapter: firstChapter)
                    
                    HapticManager.shared.selection()
                    return true
                }
            }
            return false
        }
        
        // Stage 1: Book autocomplete
        let query = String(newValue.dropLast())
        
        let matchingBooks = viewModel.sortedBooks.filter { book in
            book.nameEn.localizedCaseInsensitiveContains(query) ||
            KoreanSearchHelper.matches(query: query, target: book.nameKr) ||
            KoreanSearchHelper.matches(query: query, target: book.abbrKr)
        }
        
        if let firstMatch = matchingBooks.first {
            let bookName = firstMatch.name(for: viewModel.uiLanguage)
            searchText = bookName + " "
            searchSelectedBook = firstMatch
            HapticManager.shared.selection()
            return true
        }
        return false
    }
    
    /// Load verses for a specific chapter
    private func loadVersesForChapter(book: BibleBook, chapter: Int) {
        isLoadingVerses = true
        Task {
            do {
                let verses = try await BibleAPIService.shared.fetchChapter(book: book, chapter: chapter)
                await MainActor.run {
                    searchVerses = verses
                    isLoadingVerses = false
                }
            } catch {
                await MainActor.run {
                    searchVerses = []
                    isLoadingVerses = false
                }
            }
        }
    }
    
    /// Validate search text and reset states if needed
    private func validateAndResetSearchState(newValue: String) {
        guard let book = searchSelectedBook else { return }
        
        let bookName = book.name(for: viewModel.uiLanguage)
        let bookPrefix = bookName + " "
        
        // Check if book name is still valid
        if !newValue.hasPrefix(bookPrefix) && newValue != bookName {
            // Reset everything
            searchSelectedBook = nil
            searchSelectedChapter = nil
            searchSelectedVerse = nil
            searchVerses = []
            return
        }
        
        // If chapter is selected, check if chapter part is still valid
        if let chapter = searchSelectedChapter {
            let chapterSuffix = viewModel.uiLanguage == .kr ? "장 " : " "
            let chapterPrefix = "\(bookPrefix)\(chapter)\(chapterSuffix)"
            
            if !newValue.hasPrefix(chapterPrefix) {
                // Reset chapter and verse
                searchSelectedChapter = nil
                searchSelectedVerse = nil
                searchVerses = []
                return
            }
            
            // If verse is selected, check if verse part is still valid
            if let verse = searchSelectedVerse {
                let verseSuffix = viewModel.uiLanguage == .kr ? "절 " : " "
                let versePrefix = "\(chapterPrefix)\(verse)\(verseSuffix)"
                
                if !newValue.hasPrefix(versePrefix) {
                    // Reset verse only
                    searchSelectedVerse = nil
                }
            }
        }
    }
    
    // MARK: - Segmented Sort Control
    private var sortSegmentedControl: some View {
        HStack(spacing: 0) {
            // Temporarily hide alphabetical (A-Z) option
            ForEach(BookSortOrder.allCases.filter { $0 != .alphabetical }, id: \.self) { order in
                Button {
                    if isOrderSelected(order) {
                        // Already selected - toggle scroll between top and bottom
                        if order == .timeline {
                            timelineScrollTrigger.toggle()
                            // Toggle direction for next tap
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                timelineScrollToBottom.toggle()
                            }
                        } else {
                            bookGridScrollTrigger.toggle()
                            // Toggle direction for next tap
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                bookGridScrollToBottom.toggle()
                            }
                        }
                    } else {
                        // Switch to this order - reset scroll direction to bottom
                        bookGridScrollToBottom = true
                        timelineScrollToBottom = true
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.sortOrder = order
                        }
                    }
                    HapticManager.shared.selection()
                } label: {
                    Text(order.displayName(for: viewModel.uiLanguage))
                        .font(.system(size: 14, weight: isOrderSelected(order) ? .semibold : .regular))
                        .foregroundStyle(isOrderSelected(order) ? .white : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(isOrderSelected(order) ? Color.white.opacity(0.15) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity)
        .glassBackground(.capsule, intensity: .regular)
    }
    
    private func isOrderSelected(_ order: BookSortOrder) -> Bool {
        return viewModel.sortOrder == order
    }
    
    // MARK: - Favorites Section (styled like BookCell)
    private var favoritesSection: some View {
        Group {
            if viewModel.sortOrder == .canonical {
                // 2-column layout matching book cards
                LazyVGrid(columns: listColumns, spacing: 30) {
                    Button {
                        onFavoritesSelect?()
                        HapticManager.shared.selection()
                    } label: {
                        VStack(spacing: 6) {
                            // Heart icon (like book abbreviation)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                            
                            // Counter (like book full name)
                            Text("\(FavoriteService.shared.count)")
                                .font(viewModel.uiLanguage == .kr 
                                    ? FontManager.koreanSans(size: 12, weight: .medium)
                                    : .system(size: 12, weight: .medium, design: .default))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                        .frame(width: BookListCell.bookWidth, height: BookListCell.bookHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
            } else {
                // 3-column layout
                LazyVGrid(columns: columns, spacing: 10) {
                    Button {
                        onFavoritesSelect?()
                        HapticManager.shared.selection()
                    } label: {
                        VStack(spacing: 6) {
                            // Heart icon (like book abbreviation)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                            
                            // Counter (like book full name)
                            Text("\(FavoriteService.shared.count)")
                                .font(viewModel.uiLanguage == .kr 
                                    ? FontManager.koreanSans(size: 12, weight: .medium)
                                    : .system(size: 12, weight: .medium, design: .default))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Book Section
    private func bookSection(title: String, books: [BibleBook]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text(title)
                .font(viewModel.uiLanguage == .kr 
                    ? FontManager.koreanSans(size: 13, weight: .semibold)
                    : .system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 20)
            
            // Books grid - 2-column for canonical, 3-column for others
            if viewModel.sortOrder == .canonical {
                // 2-column list view with summary (book-like cards)
                LazyVGrid(columns: listColumns, spacing: 30) {
                    ForEach(books) { book in
                        BookListCell(
                            book: book,
                            language: viewModel.uiLanguage,
                            isSelected: book == viewModel.currentBook
                        )
                        .onTapGesture {
                            if let onBookSelect {
                                onBookSelect(book)
                            } else {
                                viewModel.selectBook(book)
                            }
                            HapticManager.shared.selection()
                        }
                    }
                }
                .padding(.horizontal, 24)
            } else {
                // 3-column compact grid
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(books) { book in
                        BookCell(
                            book: book,
                            language: viewModel.uiLanguage,
                            isSelected: book == viewModel.currentBook
                        )
                        .onTapGesture {
                            if let onBookSelect {
                                onBookSelect(book)
                            } else {
                                viewModel.selectBook(book)
                            }
                            HapticManager.shared.selection()
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Title
    private var titleBar: some View {
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
            .padding(.bottom, 8)  // Match timeline view
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    glowAnimating = true
                }
            }
    }
    
    // MARK: - Compact View (for panel)
    private var compactView: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 24) {
                    // Old Testament section
                    if !oldTestamentBooks.isEmpty {
                        compactBookSection(
                            title: viewModel.uiLanguage == .kr ? "구약" : "Old Testament",
                            books: oldTestamentBooks
                        )
                    }
                    
                    // New Testament section
                    if !newTestamentBooks.isEmpty {
                        compactBookSection(
                            title: viewModel.uiLanguage == .kr ? "신약" : "New Testament",
                            books: newTestamentBooks
                        )
                    }
                }
            }
        }
        .padding(.top, safeAreaTop + 16)
        .frame(height: contentHeight)
        .background(Color.black)
    }
    
    // MARK: - Compact Book Section
    private func compactBookSection(title: String, books: [BibleBook]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text(title)
                .font(viewModel.uiLanguage == .kr 
                    ? FontManager.koreanSans(size: 13, weight: .semibold)
                    : .system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 20)
            
            // Books grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(books) { book in
                    BookCell(
                        book: book,
                        language: viewModel.uiLanguage,
                        isSelected: book == viewModel.currentBook
                    )
                    .onTapGesture {
                        viewModel.selectBook(book)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Circular Progress Indicator (Pie Chart Style)
struct CircularProgressIndicator: View {
    let progress: Double  // 0.0 to 1.0
    let size: CGFloat
    let lineWidth: CGFloat
    
    init(progress: Double, size: CGFloat = 16, lineWidth: CGFloat = 2) {
        self.progress = progress
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            // Background circle (track)
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: lineWidth)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.white,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Checkmark for completed
            if progress >= 1.0 {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
    }
}

struct BookCell: View {
    let book: BibleBook
    let language: LanguageMode
    let isSelected: Bool
    
    private var theme: BookTheme {
        BookThemes.theme(for: book.id)
    }
    
    private var isFullyRead: Bool {
        ReadingProgressTracker.shared.isBookFullyRead(book: book)
    }
    
    private var readProgress: Double {
        let readCount = ReadingProgressTracker.shared.readChapterCount(for: book)
        return Double(readCount) / Double(book.chapterCount)
    }
    
    // Very dark grey for fully read books (slightly brighter than pure black)
    private var cellBackground: Color {
        if isFullyRead {
            return Color(red: 0.12, green: 0.12, blue: 0.12)
        } else {
            return theme.surface
        }
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                Text(book.abbreviation(for: language))
                    .font(theme.display(24, language: language))
                    .foregroundStyle(isFullyRead ? theme.textPrimary.opacity(0.5) : theme.textPrimary)
                
                Text(book.name(for: language))
                    .font(language == .kr 
                        ? FontManager.koreanSans(size: 12, weight: .medium)
                        : .system(size: 12, weight: .medium, design: .default))
                    .foregroundStyle(isFullyRead ? theme.textSecondary.opacity(0.5) : theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cellBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 2)
            )
            
            // Progress indicator (only show if there's any progress)
            if readProgress > 0 {
                CircularProgressIndicator(progress: readProgress, size: 14, lineWidth: 1.5)
                    .padding(.top, 12)
                    .padding(.trailing, 12)
            }
        }
    }
}

// MARK: - Book List Cell (2-column view with summary)
struct BookListCell: View {
    let book: BibleBook
    let language: LanguageMode
    let isSelected: Bool
    
    // Fixed book-like dimensions (width:height ≈ 2:3 ratio)
    static let bookWidth: CGFloat = 150
    static let bookHeight: CGFloat = 195
    
    private var theme: BookTheme {
        BookThemes.theme(for: book.id)
    }
    
    private var isFullyRead: Bool {
        ReadingProgressTracker.shared.isBookFullyRead(book: book)
    }
    
    private var readProgress: Double {
        let readCount = ReadingProgressTracker.shared.readChapterCount(for: book)
        return Double(readCount) / Double(book.chapterCount)
    }
    
    private var cellBackground: Color {
        if isFullyRead {
            return Color(red: 0.12, green: 0.12, blue: 0.12)
        } else {
            return theme.surface
        }
    }
    
    private var bookSummary: BibleBookSummary? {
        BibleBookSummaries.summary(for: book.id)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                // Title section: Abbreviation + Name (centered like BookCell)
                Text(book.abbreviation(for: language))
                    .font(theme.display(22, language: language))
                    .foregroundStyle(isFullyRead ? theme.textPrimary.opacity(0.5) : theme.textPrimary)
                
                Text(book.name(for: language))
                    .font(language == .kr 
                        ? FontManager.koreanSans(size: 11, weight: .medium)
                        : .system(size: 11, weight: .medium, design: .default))
                    .foregroundStyle(isFullyRead ? theme.textSecondary.opacity(0.5) : theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.bottom, 20)
                
                // Summary section
                if let summary = bookSummary {
                    Text(language == .kr ? summary.summaryKo : summary.summaryEn)
                        .font(language == .kr 
                            ? FontManager.koreanSans(size: 10, weight: .regular)
                            : .system(size: 10, weight: .regular))
                        .foregroundStyle(isFullyRead ? theme.textSecondary.opacity(0.5) : theme.textSecondary)
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .frame(width: Self.bookWidth, height: Self.bookHeight)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cellBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 2)
            )
            
            // Progress indicator (only show if there's any progress)
            if readProgress > 0 {
                CircularProgressIndicator(progress: readProgress, size: 16, lineWidth: 2)
                    .padding(.top, 12)
                    .padding(.trailing, 12)
            }
        }
        .frame(maxWidth: .infinity) // Center in column
    }
}

#Preview("Fullscreen") {
    BookGridView(
        viewModel: BibleViewModel(),
        searchText: .constant(""),
        topPadding: 100,
        isFullscreen: true,
        onClose: {}
    )
    .ignoresSafeArea()
}

#Preview("Compact") {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            BookGridView(viewModel: BibleViewModel(), searchText: .constant(""), maxHeight: 400, safeAreaTop: 59)
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }
}

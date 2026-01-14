import SwiftUI

struct ContentView: View {
    @State private var viewModel = BibleViewModel()
    @State private var searchText: String = ""
    @State private var voiceSearchViewModel = VoiceSearchViewModel()
    @State private var fullscreenSelectedBook: BibleBook? = nil  // Book selected within fullscreen bookshelf
    @State private var showSettings = false
    @State private var showChapterToast = false
    @State private var currentChapterSummary: ChapterSummary? = nil
    @State private var isSettingsFABExpanded = false
    
    // Favorites system state
    @State private var showFavoritesInBookshelf = false  // Inline in bookshelf (same level as chapter grid)
    @State private var selectedVerseForMenu: BibleVerse? = nil
    @State private var editingFavorite: FavoriteVerse? = nil
    @State private var isFavoritesFilterExpanded = false  // Hide back button when filter menu is open
    
    // Search mode
    @State private var openSearchOnBookshelf = false  // Open bookshelf with search mode active
    
    private var theme: BookTheme {
        viewModel.currentTheme
    }
    
    // Fullscreen bookshelf panel (books, chapters, or favorites)
    private var isShowingFullscreenBookshelf: Bool {
        viewModel.showBookshelf && viewModel.selectedBookForChapter == nil
    }
    
    // Currently showing favorites view in bookshelf
    private var isShowingFavoritesInBookshelf: Bool {
        isShowingFullscreenBookshelf && showFavoritesInBookshelf
    }
    
    // Top panel chapter grid (from header tap)
    private var isShowingTopPanelChapters: Bool {
        viewModel.showBookshelf && viewModel.selectedBookForChapter != nil
    }
    
    var body: some View {
        GeometryReader { geometry in
            let maxPanelHeight = geometry.size.height * 0.8
            
            ZStack {
                // Main reading view - switches based on reading mode
                Group {
                    if viewModel.readingMode == .tap {
                        SlotMachineView(viewModel: viewModel, onHeaderTap: {
                            handleHeaderTap()
                        }, onSaveVerse: { verse in
                            handleSaveVerse(verse)
                        }, onCopyVerse: { verse in
                            handleCopyVerse(verse)
                        })
                    } else {
                        BookReadingView(viewModel: viewModel, onHeaderTap: {
                            handleHeaderTap()
                        }, onSaveVerse: { verse in
                            handleSaveVerse(verse)
                        }, onCopyVerse: { verse in
                            handleCopyVerse(verse)
                        })
                    }
                }
                
                // Chapter toast (below header, above content)
                if !viewModel.showBookshelf && !voiceSearchViewModel.showOverlay {
                    VStack {
                        ChapterToastContainer(
                            isVisible: $showChapterToast,
                            chapterSummary: currentChapterSummary,
                            languageMode: viewModel.uiLanguage,
                            theme: theme,
                            onTap: {
                                markCurrentChapterToastSeen()
                                viewModel.openBookshelf(showChapters: true)
                            },
                            onDismiss: {
                                markCurrentChapterToastSeen()
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, geometry.safeAreaInsets.top - 24)
                        
                        Spacer()
                    }
                    .zIndex(1)
                }
                
                // Dimmed background - tap to dismiss (only for top panel chapter grid)
                if isShowingTopPanelChapters {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissBookshelf()
                        }
                        .zIndex(1)
                }
                
                // Fullscreen bookshelf panel (books grid, chapters grid, or favorites)
                if isShowingFullscreenBookshelf {
                    // Solid background to prevent reading view visibility during transitions
                    let panelTheme = fullscreenSelectedBook != nil 
                        ? BookThemes.theme(for: fullscreenSelectedBook!.id)
                        : theme
                    
                    // Use black for favorites, theme background for others
                    Group {
                        if showFavoritesInBookshelf {
                            Color.black
                        } else {
                            panelTheme.background
                        }
                    }
                    .ignoresSafeArea()
                    
                    ZStack {
                        // Books grid
                        if fullscreenSelectedBook == nil && !showFavoritesInBookshelf {
                            BookGridView(
                                viewModel: viewModel,
                                searchText: $searchText,
                                safeAreaBottom: geometry.safeAreaInsets.bottom,
                                topPadding: geometry.safeAreaInsets.top,
                                isFullscreen: true,
                                startInSearchMode: openSearchOnBookshelf,
                                onClose: { dismissBookshelf() },
                                onBookSelect: { book in
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        fullscreenSelectedBook = book
                                    }
                                },
                                onFavoritesSelect: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        showFavoritesInBookshelf = true
                                    }
                                }
                            )
                            .transition(.opacity)
                            .onDisappear {
                                // Reset search mode flag when bookshelf closes
                                openSearchOnBookshelf = false
                            }
                        }
                        
                        // Chapters grid (same fullscreen panel)
                        if fullscreenSelectedBook != nil && !showFavoritesInBookshelf {
                            FullscreenChapterGridView(
                                viewModel: viewModel,
                                book: $fullscreenSelectedBook,
                                topPadding: geometry.safeAreaInsets.top,
                                onClose: { dismissBookshelf() },
                                onChapterSelect: { book, chapter in
                                    dismissBookshelf()
                                    Task {
                                        await viewModel.navigateTo(book: book, chapter: chapter)
                                    }
                                }
                            )
                            .transition(.opacity)
                        }
                        
                        // Favorites view (same fullscreen panel, same level as chapters)
                        if showFavoritesInBookshelf {
                            FavoritesReadingView(
                                language: viewModel.uiLanguage,
                                safeAreaTop: geometry.safeAreaInsets.top,
                                safeAreaBottom: geometry.safeAreaInsets.bottom,
                                onClose: { dismissBookshelf() },
                                onBack: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        showFavoritesInBookshelf = false
                                    }
                                },
                                onNavigateToVerse: { favorite in
                                    // Navigate to the verse location
                                    if let book = BibleData.book(by: favorite.bookId) {
                                        dismissBookshelf()
                                        Task {
                                            await viewModel.navigateTo(book: book, chapter: favorite.chapter, verse: favorite.verseNumber)
                                        }
                                    }
                                },
                                onEditFavorite: { favorite in
                                    // Create a BibleVerse from the favorite for editing
                                    editingFavorite = favorite
                                    selectedVerseForMenu = BibleVerse(
                                        bookName: favorite.bookNameEn,
                                        chapter: favorite.chapter,
                                        verseNumber: favorite.verseNumber,
                                        textEn: favorite.textEn,
                                        textKr: favorite.textKr
                                    )
                                },
                                isFilterExpanded: $isFavoritesFilterExpanded
                            )
                            .transition(.opacity)
                        }
                    }
                    .ignoresSafeArea()
                    .zIndex(2)
                }
                
                // Chapter info panel - top panel (from header tap)
                if isShowingTopPanelChapters {
                    VStack(spacing: 0) {
                        ChapterInfoPanel(
                            viewModel: viewModel,
                            maxHeight: maxPanelHeight,
                            safeAreaTop: geometry.safeAreaInsets.top
                        )
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 0,
                                bottomLeadingRadius: 20,
                                bottomTrailingRadius: 20,
                                topTrailingRadius: 0,
                                style: .continuous
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 20, y: 5)
                        
                        Spacer()
                    }
                    .ignoresSafeArea(edges: .top)
                    .transition(.move(edge: .top))
                    .zIndex(2)
                }
                
                // Full-screen tap overlay to close FAB menu (blocks all other interactions)
                if isSettingsFABExpanded {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                isSettingsFABExpanded = false
                            }
                        }
                        .ignoresSafeArea()
                        .zIndex(2.5)
                }
                
                // Floating controls at bottom (hidden when in books grid, but shown in chapters/favorites)
                if !(isShowingFullscreenBookshelf && fullscreenSelectedBook == nil && !showFavoritesInBookshelf) {
                    VStack {
                        Spacer()
                        
                        // Bottom: Action buttons (left) + Expandable menu (right)
                        HStack(alignment: .bottom) {
                            leftActionButtons
                            Spacer()
                            // Hide menu when in fullscreen chapter grid or favorites
                            if !(isShowingFullscreenBookshelf && (fullscreenSelectedBook != nil || showFavoritesInBookshelf)) {
                                ExpandableFAB(
                                    languageMode: $viewModel.languageMode,
                                    readingMode: $viewModel.readingMode,
                                    theme: theme,
                                    primaryLanguageCode: viewModel.primaryLanguageCode,
                                    secondaryLanguageCode: viewModel.secondaryLanguageCode,
                                    uiLanguage: viewModel.uiLanguage,
                                    onLanguageToggle: {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            viewModel.toggleLanguage()
                                        }
                                    },
                                    onReadingModeToggle: {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            viewModel.readingMode = viewModel.readingMode == .tap ? .scroll : .tap
                                        }
                                    },
                                    onSettings: {
                                        showSettings = true
                                    },
                                    isExpanded: $isSettingsFABExpanded,
                                    useBlurBackground: viewModel.readingMode == .scroll
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                    }
                    .ignoresSafeArea()
                    .zIndex(3)
                }
                
                // Voice search overlay
                if voiceSearchViewModel.showOverlay {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            voiceSearchViewModel.close()
                        }
                        .zIndex(4)
                    
                    VStack {
                        Spacer()
                        
                        VoiceSearchOverlay(
                            viewModel: voiceSearchViewModel,
                            theme: theme,
                            languageMode: viewModel.uiLanguage
                        )
                        .frame(height: maxPanelHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.move(edge: .bottom))
                    .zIndex(10)
                }
                
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.showBookshelf)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.selectedBookForChapter)
            .animation(.easeOut(duration: 0.25), value: voiceSearchViewModel.showOverlay)
            .onAppear {
                setupVoiceSearchNavigation()
                showChapterToastIfAvailable()
            }
            .onChange(of: viewModel.currentChapter) { _, _ in
                // Quick dismiss current toast when chapter changes (user swiped)
                if showChapterToast {
                    withAnimation(.easeOut(duration: 0.08)) {
                        showChapterToast = false
                    }
                    markCurrentChapterToastSeen()
                }
                showChapterToastIfAvailable()
            }
            .onChange(of: viewModel.currentBook) { _, _ in
                // Quick dismiss current toast when book changes
                if showChapterToast {
                    withAnimation(.easeOut(duration: 0.08)) {
                        showChapterToast = false
                    }
                    markCurrentChapterToastSeen()
                }
                showChapterToastIfAvailable()
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView(
                    languageMode: $viewModel.languageMode,
                    readingMode: $viewModel.readingMode,
                    viewModel: viewModel,
                    onDismiss: {
                        showSettings = false
                        // Reload verses with new translation settings
                        Task {
                            await viewModel.reloadCurrentChapter()
                        }
                    }
                )
            }
            .fullScreenCover(item: $selectedVerseForMenu) { verse in
                // Use book from editing favorite if available, otherwise use current book
                let book = editingFavorite.flatMap { BibleData.book(by: $0.bookId) } ?? viewModel.currentBook
                FavoriteNoteOverlay(
                    verse: verse,
                    book: book,
                    language: viewModel.uiLanguage,
                    existingFavorite: editingFavorite,
                    onSave: { note in
                        if let existing = editingFavorite {
                            // Update existing favorite note
                            FavoriteService.shared.updateNote(id: existing.id, note: note)
                        } else {
                            // Add new favorite
                            FavoriteService.shared.addFavorite(
                                verse: verse,
                                book: book,
                                note: note
                            )
                        }
                        selectedVerseForMenu = nil
                        editingFavorite = nil
                    },
                    onCancel: {
                        selectedVerseForMenu = nil
                        editingFavorite = nil
                    }
                )
            }
        }
    }
    
    private func setupVoiceSearchNavigation() {
        voiceSearchViewModel.onNavigate = { book, chapter, verse in
            await viewModel.navigateTo(book: book, chapter: chapter, verse: verse)
        }
    }
    
    private func showChapterToastIfAvailable() {
        // Small delay to let the view settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Don't show if bookshelf is open
            guard !viewModel.showBookshelf else { return }
            
            // Check if we should show toast for this chapter (not seen in last 6 months)
            guard ChapterToastTracker.shared.shouldShowToast(
                bookId: viewModel.currentBook.id,
                chapter: viewModel.currentChapter
            ) else { return }
            
            // Get chapter summary
            if let summary = ChapterDataManager.shared.chapterSummary(
                bookId: viewModel.currentBook.id,
                chapter: viewModel.currentChapter
            ) {
                currentChapterSummary = summary
                showChapterToast = true
            }
        }
    }
    
    private func markCurrentChapterToastSeen() {
        ChapterToastTracker.shared.markAsSeen(
            bookId: viewModel.currentBook.id,
            chapter: viewModel.currentChapter
        )
    }
    
    private func dismissBookshelf() {
        viewModel.isSearchActive = false
        searchText = ""
        fullscreenSelectedBook = nil
        showFavoritesInBookshelf = false
        viewModel.dismissBookshelf()
        HapticManager.shared.selection()
    }
    
    private func handleHeaderTap() {
        // Header tap action - toggle bookshelf (shows chapters for current book)
        if viewModel.showBookshelf {
            dismissBookshelf()
        } else {
            // Mark toast as seen when opening chapter info panel
            markCurrentChapterToastSeen()
            showChapterToast = false
            viewModel.openBookshelf(showChapters: true)
        }
        HapticManager.shared.selection()
    }
    
    private func handleSaveVerse(_ verse: BibleVerse) {
        editingFavorite = nil
        selectedVerseForMenu = verse
    }
    
    private func handleCopyVerse(_ verse: BibleVerse) {
        let text = verse.text(for: viewModel.uiLanguage)
        let reference = "\(viewModel.currentBook.name(for: viewModel.uiLanguage)) \(verse.chapter):\(verse.verseNumber)"
        UIPasteboard.general.string = "\(text)\n— \(reference)"
        HapticManager.shared.success()
    }
    
    // MARK: - Left Action Buttons
    
    @ViewBuilder
    private var leftActionButtons: some View {
        if isShowingFullscreenBookshelf && (fullscreenSelectedBook != nil || showFavoritesInBookshelf) {
            // In fullscreen chapters or favorites - show back button
            // Hide when favorites filter menu is expanded
            actionButton(icon: "chevron.left") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if showFavoritesInBookshelf {
                        showFavoritesInBookshelf = false
                    } else {
                        fullscreenSelectedBook = nil
                    }
                }
                HapticManager.shared.selection()
            }
            .opacity(isFavoritesFilterExpanded ? 0 : 1)
            .animation(.easeOut(duration: 0.2), value: isFavoritesFilterExpanded)
        } else {
            HStack(spacing: 12) {
                // Bookshelf button - directly opens bookshelf
                NavigateFAB(
                    theme: theme,
                    onBookshelf: {
                        if viewModel.showBookshelf {
                            dismissBookshelf()
                        } else {
                            viewModel.openBookshelf()
                        }
                    },
                    useBlurBackground: viewModel.readingMode == .scroll
                )
                
                // Search button - opens bookshelf with search mode
                searchButton
            }
            .opacity(isSettingsFABExpanded ? 0 : 1)
            .animation(.easeOut(duration: 0.2), value: isSettingsFABExpanded)
        }
    }
    
    private var searchButton: some View {
        Button {
            openSearchOnBookshelf = true
            viewModel.openBookshelf()
            HapticManager.shared.selection()
        } label: {
            ZStack {
                searchButtonBackground
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 52, height: 52)
        }
        .buttonStyle(BookshelfButtonStyle())
    }
    
    // Match NavigateFAB's glass background exactly
    @ViewBuilder
    private var searchButtonBackground: some View {
        if viewModel.readingMode == .scroll {
            // Regular material for scroll mode (same as NavigateFAB)
            Circle()
                .fill(.regularMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: .black.opacity(0.15),
                    radius: 6,
                    y: 3
                )
        } else {
            // Clear glass for tap mode (same as NavigateFAB)
            Circle()
                .fill(Color.white.opacity(0.08))
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: .black.opacity(0.12),
                    radius: 4,
                    y: 2
                )
        }
    }
    
    private func actionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.glassCircle)
    }
}

#Preview {
    ContentView()
}

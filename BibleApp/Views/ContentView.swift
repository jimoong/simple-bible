import SwiftUI

struct ContentView: View {
    @State private var viewModel = BibleViewModel()
    @State private var searchText: String = ""
    @State private var voiceSearchViewModel = VoiceSearchViewModel()
    @State private var gamalielViewModel = GamalielViewModel()  // AI chatbot
    @State private var listeningViewModel = ListeningViewModel()  // TTS listening mode
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
    @State private var isFavoritesMultiSelectMode = false  // Hide back button when in multi-select mode
    @State private var scrollToFavoriteId: String? = nil  // Scroll to specific favorite on open
    @State private var favoritesOpenedFromReading = false  // Track if favorites was opened directly from reading view
    
    // Clean reading mode - hide controls while scrolling
    @State private var hideControlsWhileScrolling = false
    
    // Multi-select mode state
    @State private var isMultiSelectMode = false
    @State private var selectedVerseIndices: Set<Int> = []
    @State private var showMultiSelectSaveOverlay = false
    
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
        // Force SwiftUI to observe listeningViewModel properties (fixes cold start issue)
        let _ = listeningViewModel.verseReadPositions.count
        let _ = listeningViewModel.highlightedRange
        
        GeometryReader { geometry in
            let maxPanelHeight = geometry.size.height * 0.8
            
            ZStack {
                // Main reading view - switches based on reading mode
                Group {
                    if viewModel.readingMode == .tap {
                        SlotMachineView(
                            viewModel: viewModel,
                            isMultiSelectMode: isMultiSelectMode,
                            selectedVerseIndices: $selectedVerseIndices,
                            onHeaderTap: {
                                handleHeaderTap()
                            },
                            onSaveVerse: { verse in
                                handleSaveVerse(verse)
                            },
                            onCopyVerse: { verse in
                                handleCopyVerse(verse)
                            },
                            onAskVerse: { verse in
                                handleAskVerse(verse)
                            },
                            onListenFromVerse: { verseIndex in
                                enterListeningMode(fromVerseIndex: verseIndex)
                            },
                            onMultiSelectVerse: { verseIndex in
                                enterMultiSelectModeWithVerse(verseIndex)
                            }
                        )
                    } else {
                        BookReadingView(
                            viewModel: viewModel,
                            isMultiSelectMode: isMultiSelectMode,
                            selectedVerseIndices: $selectedVerseIndices,
                            onHeaderTap: {
                                handleHeaderTap()
                            },
                            onSaveVerse: { verse in
                                handleSaveVerse(verse)
                            },
                            onCopyVerse: { verse in
                                handleCopyVerse(verse)
                            },
                            onAskVerse: { verse in
                                handleAskVerse(verse)
                            },
                            onListenFromVerse: { verseIndex in
                                enterListeningMode(fromVerseIndex: verseIndex)
                            },
                            onMultiSelectVerse: { verseIndex in
                                enterMultiSelectModeWithVerse(verseIndex)
                            },
                            onScrollStateChange: { isScrolling in
                                withAnimation(.easeOut(duration: 0.25)) {
                                    hideControlsWhileScrolling = isScrolling
                                }
                            },
                            externalControlsHidden: hideControlsWhileScrolling
                        )
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
                
                // Floating counter for multi-select mode (top center, same position as favorites list)
                if isMultiSelectMode && !selectedVerseIndices.isEmpty && !isShowingFullscreenBookshelf {
                    VStack {
                        Text(viewModel.uiLanguage == .kr 
                             ? "\(selectedVerseIndices.count)절 선택됨" 
                             : "\(selectedVerseIndices.count) verses selected")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .environment(\.colorScheme, .dark)
                            )
                            .padding(.top, geometry.safeAreaInsets.top + 16)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .zIndex(50)  // High zIndex to be above everything
                }
                
                // Dimmed background - tap to dismiss (only for top panel chapter grid)
                if isShowingTopPanelChapters {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissBookshelf()
                        }
                        .zIndex(26)  // Above listening mode (25) so panel appears on top
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
                                startInSearchMode: viewModel.isSearchActive,
                                onClose: { dismissBookshelf() },
                                onBookSelect: { book in
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        fullscreenSelectedBook = book
                                    }
                                },
                                onFavoritesSelect: {
                                    // Set state immediately, then animate the transition
                                    showFavoritesInBookshelf = true
                                    favoritesOpenedFromReading = false  // Opened from bookshelf, not reading view
                                },
                                onNavigate: { book, chapter, verse in
                                    // Restart listening mode with new chapter if was listening
                                    // This is called AFTER navigation completes, so verses are loaded
                                    if listeningViewModel.isActive {
                                        listeningViewModel.start(verses: viewModel.verses, language: viewModel.languageMode)
                                    }
                                }
                            )
                            .transition(.opacity)
                        }
                        
                        // Chapters grid (same fullscreen panel)
                        if fullscreenSelectedBook != nil && !showFavoritesInBookshelf {
                            FullscreenChapterGridView(
                                viewModel: viewModel,
                                book: $fullscreenSelectedBook,
                                topPadding: geometry.safeAreaInsets.top,
                                onClose: { dismissBookshelf() },
                                onChapterSelect: { book, chapter in
                                    let wasInListeningMode = listeningViewModel.isActive
                                    dismissBookshelf()
                                    Task {
                                        await viewModel.navigateTo(book: book, chapter: chapter)
                                        // Restart listening mode with new chapter if was listening
                                        if wasInListeningMode {
                                            listeningViewModel.start(verses: viewModel.verses, language: viewModel.languageMode)
                                        }
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
                                        let wasInListeningMode = listeningViewModel.isActive
                                        // Navigate FIRST, then dismiss bookshelf
                                        // This ensures the correct verse position is set before the reading view appears
                                        Task {
                                            await viewModel.navigateTo(book: book, chapter: favorite.chapter, verse: favorite.verseNumber)
                                            // Now dismiss bookshelf after navigation is complete
                                            dismissBookshelf()
                                            // Restart listening mode with new chapter if was listening
                                            if wasInListeningMode {
                                                listeningViewModel.start(verses: viewModel.verses, language: viewModel.languageMode)
                                            }
                                        }
                                    }
                                },
                                onEditFavorite: { favorite in
                                    // Create a BibleVerse from the favorite for editing
                                    // First dismiss if already showing, then reopen with new data
                                    if selectedVerseForMenu != nil {
                                        selectedVerseForMenu = nil
                                        editingFavorite = nil
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            editingFavorite = favorite
                                            selectedVerseForMenu = BibleVerse(
                                                bookName: favorite.bookNameEn,
                                                chapter: favorite.chapter,
                                                verseNumber: favorite.verseNumber,
                                                textEn: favorite.textEn,
                                                textKr: favorite.textKr
                                            )
                                        }
                                    } else {
                                        editingFavorite = favorite
                                        selectedVerseForMenu = BibleVerse(
                                            bookName: favorite.bookNameEn,
                                            chapter: favorite.chapter,
                                            verseNumber: favorite.verseNumber,
                                            textEn: favorite.textEn,
                                            textKr: favorite.textKr
                                        )
                                    }
                                },
                                isFilterExpanded: $isFavoritesFilterExpanded,
                                isInMultiSelectMode: $isFavoritesMultiSelectMode,
                                scrollToId: scrollToFavoriteId
                            )
                            .transition(.opacity)
                            .onAppear {
                                // Clear scrollToId after view appears (so it doesn't scroll again on re-appear)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    scrollToFavoriteId = nil
                                }
                            }
                        }
                        
                        // Back button - bottom left for chapter grid and favorites
                        if fullscreenSelectedBook != nil {
                            // Chapter grid: bottom left
                            VStack {
                                Spacer()
                                HStack {
                                    topLeftBackButton
                                        .padding(.bottom, geometry.safeAreaInsets.bottom - 4)
                                        .padding(.leading, 20)
                                    Spacer()
                                }
                            }
                        } else if showFavoritesInBookshelf {
                            // Favorites: bottom left
                            VStack {
                                Spacer()
                                HStack {
                                    topLeftBackButton
                                        .padding(.bottom, geometry.safeAreaInsets.bottom - 4)
                                        .padding(.leading, 20)
                                        .opacity(isFavoritesFilterExpanded || isFavoritesMultiSelectMode ? 0 : 1)
                                        .animation(.easeOut(duration: 0.2), value: isFavoritesFilterExpanded)
                                        .animation(.easeOut(duration: 0.2), value: isFavoritesMultiSelectMode)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .ignoresSafeArea()
                    .zIndex(27)  // Above listening mode (25) so bookshelf appears on top
                }
                
                // Chapter info panel - top panel (from header tap)
                if isShowingTopPanelChapters {
                    VStack(spacing: 0) {
                        ChapterInfoPanel(
                            viewModel: viewModel,
                            maxHeight: maxPanelHeight,
                            safeAreaTop: geometry.safeAreaInsets.top,
                            onNavigate: {
                                // Restart listening mode with new chapter if was listening
                                if listeningViewModel.isActive {
                                    listeningViewModel.start(verses: viewModel.verses, language: viewModel.languageMode)
                                }
                            }
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
                    .zIndex(28)  // Above listening mode (25) so panel appears on top
                }
                
                // Full-screen tap overlay to close FAB menu (blocks other interactions but NOT the FAB itself)
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
                        .zIndex(28.5)  // Below floating controls (29) but above chapter info panel (28)
                }
                
                // Floating controls at bottom (hidden when in books grid, top panel chapters, or listening mode)
                if !(isShowingFullscreenBookshelf && fullscreenSelectedBook == nil && !showFavoritesInBookshelf) && !isShowingTopPanelChapters && !listeningViewModel.isActive {
                    VStack {
                        Spacer()
                        
                        // Multi-select mode action bar OR normal bottom controls
                        if isMultiSelectMode {
                            MultiSelectActionBar(
                                selectedCount: selectedVerseIndices.count,
                                languageMode: viewModel.uiLanguage,
                                useBlurBackground: viewModel.readingMode == .scroll,
                                onSave: {
                                    handleMultiSelectSave()
                                },
                                onAsk: {
                                    handleMultiSelectAsk()
                                },
                                onClose: {
                                    exitMultiSelectMode()
                                },
                                onNoSelectionTap: {
                                    FeedbackManager.shared.showInfo(
                                        viewModel.uiLanguage == .kr ? "구절을 선택하세요" : "Select verses first"
                                    )
                                }
                            )
                            .padding(.horizontal, 20)
                            .padding(.bottom, geometry.safeAreaInsets.bottom - 4)
                        } else if isShowingFullscreenBookshelf && fullscreenSelectedBook != nil && !showFavoritesInBookshelf {
                            // Chapter grid view - show book navigation at bottom right
                            HStack {
                                Spacer()
                                bookNavigationButtons
                                    .padding(.trailing, 20)
                                    .padding(.bottom, geometry.safeAreaInsets.bottom - 4)
                            }
                        } else if !isShowingFullscreenBookshelf {
                            // Normal reading view - Bottom: Action buttons (left) + Expandable menu (right)
                            HStack(alignment: .bottom) {
                                leftActionButtons
                                    .animation(.easeOut(duration: 0.25), value: isSettingsFABExpanded)
                                Spacer()
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
                                            hideControlsWhileScrolling = false  // Reset on mode change
                                        }
                                    },
                                    onSettings: {
                                        showSettings = true
                                    },
                                    onListening: {
                                        enterListeningMode()
                                    },
                                    onMultiSelect: {
                                        enterMultiSelectMode()
                                    },
                                    isExpanded: $isSettingsFABExpanded,
                                    useBlurBackground: viewModel.readingMode == .scroll
                                )
                            }
                            .padding(.horizontal, 28)
                            .padding(.bottom, geometry.safeAreaInsets.bottom - 4)
                            // Hide controls while scrolling in scroll mode (clean reading experience)
                            .opacity(hideControlsWhileScrolling && viewModel.readingMode == .scroll ? 0 : 1)
                        }
                    }
                    .ignoresSafeArea()
                    .zIndex(29)  // Above bookshelf (27) and chapter info panel (28)
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
                
                // Gamaliel AI chat - Full screen with fade in
                if gamalielViewModel.showOverlay {
                    GamalielChatView(
                        viewModel: gamalielViewModel,
                        languageMode: viewModel.uiLanguage,
                        safeAreaTop: geometry.safeAreaInsets.top,
                        safeAreaBottom: geometry.safeAreaInsets.bottom,
                        onNavigateToVerse: { book, chapter, verse in
                            let wasInListeningMode = listeningViewModel.isActive
                            Task {
                                await viewModel.navigateTo(book: book, chapter: chapter, verse: verse ?? 1)
                                // Restart listening mode with new chapter if was listening
                                if wasInListeningMode {
                                    listeningViewModel.start(verses: viewModel.verses, language: viewModel.languageMode)
                                }
                            }
                        }
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(30)  // Above listening mode (25) so chat appears on top
                }
                
                // Listening mode - Full screen overlay
                if listeningViewModel.isActive {
                    ListeningModeView(
                        viewModel: listeningViewModel,
                        bibleViewModel: viewModel,
                        theme: theme,
                        safeAreaTop: geometry.safeAreaInsets.top,
                        safeAreaBottom: geometry.safeAreaInsets.bottom,
                        onExit: {
                            exitListeningMode()
                        },
                        onHeaderTap: {
                            // Same as handleHeaderTap() - opens chapter info panel
                            listeningViewModel.pauseForNavigation()
                            if viewModel.showBookshelf {
                                dismissBookshelf()
                            } else {
                                viewModel.openBookshelf(showChapters: true)
                            }
                            HapticManager.shared.selection()
                        },
                        onBookshelf: {
                            listeningViewModel.pauseForNavigation()
                            viewModel.openBookshelf()
                        },
                        onSearch: {
                            listeningViewModel.pauseForNavigation()
                            viewModel.openBookshelf(withSearch: true)
                        },
                        onChat: {
                            listeningViewModel.pauseForNavigation()
                            gamalielViewModel.open(with: viewModel.uiLanguage, readingContext: currentReadingContext)
                        }
                    )
                    .id(listeningViewModel.sessionId)  // Force complete view recreation on each session
                    .transition(.opacity)
                    .zIndex(25)
                }
                
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.showBookshelf)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.selectedBookForChapter)
            .animation(.easeOut(duration: 0.25), value: voiceSearchViewModel.showOverlay)
            .animation(.easeOut(duration: 0.25), value: gamalielViewModel.showOverlay)
            .animation(.easeOut(duration: 0.3), value: listeningViewModel.isActive)
            .onAppear {
                setupVoiceSearchNavigation()
                showChapterToastIfAvailable()
                // Warm up services on app launch to fix cold start issues
                _ = TTSService.shared
                _ = FavoriteService.shared
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
                
                // Clear multi-select when chapter changes
                if isMultiSelectMode {
                    selectedVerseIndices.removeAll()
                }
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
                
                // Exit multi-select mode when book changes
                if isMultiSelectMode {
                    exitMultiSelectMode()
                }
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
                // Capture editing favorite first, then derive book from it
                let currentEditingFavorite = editingFavorite  // Capture current value
                // Try to get book from: 1) editing favorite, 2) verse bookName, 3) current book
                let book = currentEditingFavorite.flatMap { BibleData.book(by: $0.bookId) }
                    ?? BibleData.books.first { $0.nameEn == verse.bookName }
                    ?? viewModel.currentBook
                FavoriteNoteOverlay(
                    verse: verse,
                    book: book,
                    language: viewModel.uiLanguage,
                    existingFavorite: currentEditingFavorite,
                    onSave: { note in
                        let isNewFavorite = currentEditingFavorite == nil
                        if let existing = currentEditingFavorite {
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
                        
                        // Show success toast with action (only for new saves)
                        if isNewFavorite {
                            FeedbackManager.shared.showSuccess(
                                viewModel.uiLanguage == .kr ? "저장했어요" : "Saved",
                                actionLabel: viewModel.uiLanguage == .kr ? "목록 보기" : "View",
                                action: { [self] in
                                    openFavoritesList()
                                }
                            )
                        }
                    },
                    onCancel: {
                        selectedVerseForMenu = nil
                        editingFavorite = nil
                    },
                    onViewInBible: currentEditingFavorite != nil ? {
                        // Navigate to verse in reading view
                        if let favorite = currentEditingFavorite,
                           let book = BibleData.book(by: favorite.bookId) {
                            selectedVerseForMenu = nil
                            editingFavorite = nil
                            
                            // Close favorites list and navigate
                            showFavoritesInBookshelf = false
                            Task {
                                await viewModel.navigateTo(
                                    book: book,
                                    chapter: favorite.chapter,
                                    verse: favorite.verseNumber
                                )
                            }
                            dismissBookshelf()
                        }
                    } : nil
                )
                .id(currentEditingFavorite?.id ?? verse.id)  // Force view recreation on favorite change
            }
            .fullScreenCover(isPresented: $showMultiSelectSaveOverlay) {
                let selectedVerses = selectedVerseIndices.sorted().compactMap { index -> BibleVerse? in
                    guard index < viewModel.verses.count else { return nil }
                    return viewModel.verses[index]
                }
                
                MultiSelectSaveOverlay(
                    verses: selectedVerses,
                    book: viewModel.currentBook,
                    chapter: viewModel.currentChapter,
                    language: viewModel.uiLanguage,
                    onSave: { note in
                        // Save all selected verses as a single passage
                        FavoriteService.shared.addFavoritePassage(
                            verses: selectedVerses,
                            book: viewModel.currentBook,
                            note: note
                        )
                        showMultiSelectSaveOverlay = false
                        exitMultiSelectMode()
                        
                        // Show success toast with action
                        FeedbackManager.shared.showSuccess(
                            viewModel.uiLanguage == .kr ? "저장했어요" : "Saved",
                            actionLabel: viewModel.uiLanguage == .kr ? "목록 보기" : "View",
                            action: { [self] in
                                openFavoritesList()
                            }
                        )
                    },
                    onCancel: {
                        showMultiSelectSaveOverlay = false
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
        // Check if already saved
        let favoriteId = "\(viewModel.currentBook.id)_\(verse.chapter)_\(verse.verseNumber)"
        if FavoriteService.shared.isFavorite(verse: verse, book: viewModel.currentBook) {
            // Already saved - navigate to favorites list scrolled to this item
            navigateToFavorite(id: favoriteId)
        } else {
            // Not saved - open note overlay to save
            editingFavorite = nil
            selectedVerseForMenu = verse
        }
    }
    
    private func navigateToFavorite(id: String) {
        // Set scroll target
        scrollToFavoriteId = id
        favoritesOpenedFromReading = true  // Mark that we came from reading view
        hideControlsWhileScrolling = false  // Reset controls visibility
        
        // Check if bookshelf is already open
        if viewModel.showBookshelf {
            // Bookshelf already open - just switch to favorites view
            withAnimation(.easeInOut(duration: 0.25)) {
                fullscreenSelectedBook = nil
                viewModel.selectedBookForChapter = nil
                showFavoritesInBookshelf = true
            }
        } else {
            // Bookshelf not open - set all states together in one animation block
            // This ensures SwiftUI processes all state changes atomically
            withAnimation(.easeInOut(duration: 0.25)) {
                fullscreenSelectedBook = nil
                viewModel.selectedBookForChapter = nil
                showFavoritesInBookshelf = true
                viewModel.showBookshelf = true
            }
        }
        HapticManager.shared.selection()
    }
    
    private func openFavoritesList() {
        // Open favorites list without scrolling to specific item
        scrollToFavoriteId = nil
        favoritesOpenedFromReading = true  // Mark that we came from reading view
        hideControlsWhileScrolling = false  // Reset controls visibility
        
        // Set all states together in one animation block
        withAnimation(.easeInOut(duration: 0.25)) {
            fullscreenSelectedBook = nil
            viewModel.selectedBookForChapter = nil
            showFavoritesInBookshelf = true
            viewModel.showBookshelf = true
        }
        HapticManager.shared.selection()
    }
    
    private func handleCopyVerse(_ verse: BibleVerse) {
        let text = verse.text(for: viewModel.uiLanguage)
        let reference = "\(viewModel.currentBook.name(for: viewModel.uiLanguage)) \(verse.chapter):\(verse.verseNumber)"
        UIPasteboard.general.string = "\(text)\n— \(reference)"
        HapticManager.shared.success()
        FeedbackManager.shared.showSuccess(viewModel.uiLanguage == .kr ? "클립보드에 복사했어요" : "Copied")
    }
    
    private func handleAskVerse(_ verse: BibleVerse) {
        let attachedVerse = AttachedVerse(
            book: viewModel.currentBook,
            chapter: verse.chapter,
            verseNumber: verse.verseNumber,
            text: verse.text(for: viewModel.uiLanguage)
        )
        let context = currentReadingContext
        gamalielViewModel.openWithVerse(attachedVerse, languageMode: viewModel.uiLanguage, readingContext: context)
        HapticManager.shared.selection()
    }
    
    /// Current reading context based on reading mode and position
    private var currentReadingContext: ReadingContext {
        ReadingContext(
            book: viewModel.currentBook,
            chapter: viewModel.currentChapter,
            verseNumber: viewModel.readingMode == .tap ? (viewModel.currentVerseIndex + 1) : nil,
            readingMode: viewModel.readingMode
        )
    }
    
    // MARK: - Multi-Select Mode
    
    private func enterMultiSelectMode() {
        withAnimation(.easeOut(duration: 0.2)) {
            // Force switch to scroll mode for multi-select (tap mode uses taps for navigation)
            if viewModel.readingMode == .tap {
                viewModel.readingMode = .scroll
            }
            isMultiSelectMode = true
            selectedVerseIndices.removeAll()
        }
        HapticManager.shared.selection()
    }
    
    private func enterMultiSelectModeWithVerse(_ verseIndex: Int) {
        // No animation - prevents visual glitch with background expansion
        // Force switch to scroll mode for multi-select (tap mode uses taps for navigation)
        if viewModel.readingMode == .tap {
            viewModel.readingMode = .scroll
        }
        isMultiSelectMode = true
        selectedVerseIndices.removeAll()
        selectedVerseIndices.insert(verseIndex)  // Pre-select the verse
        HapticManager.shared.selection()
    }
    
    private func exitMultiSelectMode() {
        withAnimation(.easeOut(duration: 0.2)) {
            isMultiSelectMode = false
            selectedVerseIndices.removeAll()
        }
        HapticManager.shared.selection()
    }
    
    private func handleMultiSelectSave() {
        guard !selectedVerseIndices.isEmpty else { return }
        showMultiSelectSaveOverlay = true
        HapticManager.shared.selection()
    }
    
    private func handleMultiSelectCopy() {
        guard !selectedVerseIndices.isEmpty else { return }
        
        // Sort indices and get verses
        let sortedIndices = selectedVerseIndices.sorted()
        let selectedVerses = sortedIndices.compactMap { index -> BibleVerse? in
            guard index < viewModel.verses.count else { return nil }
            return viewModel.verses[index]
        }
        
        guard !selectedVerses.isEmpty else { return }
        
        // Build copy text
        let versesText = selectedVerses.map { $0.text(for: viewModel.uiLanguage) }.joined(separator: " ")
        let bookName = viewModel.currentBook.name(for: viewModel.uiLanguage)
        let verseNumbers = sortedIndices.map { $0 + 1 }
        let reference: String
        
        if viewModel.uiLanguage == .kr {
            if verseNumbers.count == 1 {
                reference = "\(bookName) \(viewModel.currentChapter)장 \(verseNumbers[0])절"
            } else if let first = verseNumbers.first, let last = verseNumbers.last, verseNumbers == Array(first...last) {
                // Continuous range
                reference = "\(bookName) \(viewModel.currentChapter)장 \(first)-\(last)절"
            } else {
                // Non-continuous
                reference = "\(bookName) \(viewModel.currentChapter)장 \(verseNumbers.map { String($0) }.joined(separator: ", "))절"
            }
        } else {
            if verseNumbers.count == 1 {
                reference = "\(bookName) \(viewModel.currentChapter):\(verseNumbers[0])"
            } else if let first = verseNumbers.first, let last = verseNumbers.last, verseNumbers == Array(first...last) {
                reference = "\(bookName) \(viewModel.currentChapter):\(first)-\(last)"
            } else {
                reference = "\(bookName) \(viewModel.currentChapter):\(verseNumbers.map { String($0) }.joined(separator: ", "))"
            }
        }
        
        UIPasteboard.general.string = "\(versesText)\n— \(reference)"
        HapticManager.shared.success()
        FeedbackManager.shared.showSuccess(viewModel.uiLanguage == .kr ? "클립보드에 복사했어요" : "Copied")
    }
    
    private func handleMultiSelectAsk() {
        guard !selectedVerseIndices.isEmpty else { return }
        
        // Sort indices and get verses
        let sortedIndices = selectedVerseIndices.sorted()
        let selectedVerses = sortedIndices.compactMap { index -> BibleVerse? in
            guard index < viewModel.verses.count else { return nil }
            return viewModel.verses[index]
        }
        
        guard !selectedVerses.isEmpty else { return }
        
        // Get verse numbers and texts
        let verseNumbers = selectedVerses.map { $0.verseNumber }
        let texts = selectedVerses.map { $0.text(for: viewModel.uiLanguage) }
        
        // Create attached passage
        let passage = AttachedPassage(
            book: viewModel.currentBook,
            chapter: viewModel.currentChapter,
            verseNumbers: verseNumbers,
            texts: texts
        )
        
        // Open chat with passage
        gamalielViewModel.openWithPassage(passage, languageMode: viewModel.uiLanguage, readingContext: currentReadingContext)
        
        // Exit multi-select mode
        exitMultiSelectMode()
        HapticManager.shared.selection()
    }
    
    // MARK: - Listening Mode
    
    private func enterListeningMode(fromVerseIndex: Int = 0) {
        // Dismiss any open panels
        if viewModel.showBookshelf {
            dismissBookshelf()
        }
        
        // Start listening mode with current chapter's verses
        if fromVerseIndex > 0 {
            listeningViewModel.startFrom(verses: viewModel.verses, language: viewModel.languageMode, verseIndex: fromVerseIndex)
        } else {
            listeningViewModel.start(verses: viewModel.verses, language: viewModel.languageMode)
        }
        HapticManager.shared.selection()
    }
    
    private func exitListeningMode() {
        listeningViewModel.exit()
        HapticManager.shared.selection()
    }
    
    // MARK: - Left Action Buttons
    
    @ViewBuilder
    private var leftActionButtons: some View {
        // Hide completely when settings FAB is expanded to give menu more space
        if !isSettingsFABExpanded {
            HStack(spacing: 8) {
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
                
                // AI chatbot button - opens Gamaliel
                aiChatButton
            }
            .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .bottomLeading)))
        }
    }
    
    // MARK: - Top Left Back Button (for chapter grid and favorites)
    
    private var topLeftBackButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                if showFavoritesInBookshelf {
                    if favoritesOpenedFromReading {
                        // Came directly from reading view - go back to reading
                        dismissBookshelf()
                        favoritesOpenedFromReading = false
                    } else {
                        // Came from bookshelf - go back to bookshelf
                        showFavoritesInBookshelf = false
                    }
                } else {
                    fullscreenSelectedBook = nil
                }
            }
            HapticManager.shared.selection()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.glassCircle)
    }
    
    private var searchButton: some View {
        Button {
            viewModel.openBookshelf(withSearch: true)
        } label: {
            ZStack {
                searchButtonBackground
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(BookshelfButtonStyle())
    }
    
    private var aiChatButton: some View {
        Button {
            gamalielViewModel.open(with: viewModel.uiLanguage, readingContext: currentReadingContext)
        } label: {
            ZStack {
                searchButtonBackground  // Same style as search button
                
                Image(systemName: "sparkle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)
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
    
    // MARK: - Book Navigation Buttons (for chapter grid)
    
    private var previousBookForNavigation: BibleBook? {
        guard let book = fullscreenSelectedBook else { return nil }
        return BibleData.previousBook(before: book)
    }
    
    private var nextBookForNavigation: BibleBook? {
        guard let book = fullscreenSelectedBook else { return nil }
        return BibleData.nextBook(after: book)
    }
    
    @ViewBuilder
    private var bookNavigationButtons: some View {
        HStack(spacing: 12) {
            // Previous book button - only show if previous book exists
            if let prevBook = previousBookForNavigation {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        fullscreenSelectedBook = prevBook
                    }
                    HapticManager.shared.selection()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text(prevBook.name(for: viewModel.uiLanguage))
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
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
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                }
                .buttonStyle(BookNavigationButtonStyle())
            }
            
            // Next book button - only show if next book exists
            if let nextBook = nextBookForNavigation {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        fullscreenSelectedBook = nextBook
                    }
                    HapticManager.shared.selection()
                } label: {
                    HStack(spacing: 4) {
                        Text(nextBook.name(for: viewModel.uiLanguage))
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 48)
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
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                }
                .buttonStyle(BookNavigationButtonStyle())
            }
        }
    }
}

// MARK: - Book Navigation Button Style
private struct BookNavigationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}

import SwiftUI

struct ContentView: View {
    @State private var viewModel = BibleViewModel()
    @State private var searchText: String = ""
    @State private var voiceSearchViewModel = VoiceSearchViewModel()
    @State private var fullscreenSelectedBook: BibleBook? = nil  // Book selected within fullscreen bookshelf
    @State private var showSettings = false
    @State private var showChapterToast = false
    @State private var currentChapterSummary: ChapterSummary? = nil
    
    private var theme: BookTheme {
        viewModel.currentTheme
    }
    
    // Fullscreen bookshelf panel (books or chapters)
    private var isShowingFullscreenBookshelf: Bool {
        viewModel.showBookshelf && viewModel.selectedBookForChapter == nil
    }
    
    // Top panel chapter grid (from header tap)
    private var isShowingTopPanelChapters: Bool {
        viewModel.showBookshelf && viewModel.selectedBookForChapter != nil
    }
    
    var body: some View {
        GeometryReader { geometry in
            let maxPanelHeight = geometry.size.height * 0.8
            
            ZStack {
                // Main slot machine view
                SlotMachineView(viewModel: viewModel) {
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
                
                // Chapter toast (below header, above content)
                if !viewModel.showBookshelf && !voiceSearchViewModel.showOverlay {
                    VStack {
                        ChapterToastContainer(
                            isVisible: $showChapterToast,
                            chapterSummary: currentChapterSummary,
                            languageMode: viewModel.languageMode,
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
                
                // Fullscreen bookshelf panel (books grid OR chapters grid)
                if isShowingFullscreenBookshelf {
                    // Solid background to prevent reading view visibility during transitions
                    let panelTheme = fullscreenSelectedBook != nil 
                        ? BookThemes.theme(for: fullscreenSelectedBook!.id)
                        : theme
                    panelTheme.background
                        .ignoresSafeArea()
                    
                    ZStack {
                        // Books grid
                        if fullscreenSelectedBook == nil {
                            BookGridView(
                                viewModel: viewModel,
                                searchText: $searchText,
                                safeAreaBottom: geometry.safeAreaInsets.bottom,
                                topPadding: geometry.safeAreaInsets.top,
                                isFullscreen: true,
                                onClose: { dismissBookshelf() },
                                onBookSelect: { book in
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        fullscreenSelectedBook = book
                                    }
                                }
                            )
                            .transition(.opacity)
                        }
                        
                        // Chapters grid (same fullscreen panel)
                        if fullscreenSelectedBook != nil {
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
                
                // Floating controls at bottom (hidden when in books grid)
                if !(isShowingFullscreenBookshelf && fullscreenSelectedBook == nil) {
                    VStack {
                        Spacer()
                        
                        // Bottom: Action buttons (left) + Expandable menu (right)
                        HStack(alignment: .bottom) {
                            leftActionButtons
                            Spacer()
                            ExpandableFAB(
                                languageMode: $viewModel.languageMode,
                                theme: theme,
                                onLanguageToggle: {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        viewModel.toggleLanguage()
                                    }
                                },
                                onSettings: {
                                    showSettings = true
                                }
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, geometry.safeAreaInsets.bottom - 4)
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
                            languageMode: viewModel.languageMode
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
                    onDismiss: { showSettings = false }
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
        viewModel.dismissBookshelf()
        HapticManager.shared.selection()
    }
    
    // MARK: - Left Action Buttons
    
    @ViewBuilder
    private var leftActionButtons: some View {
        if isShowingFullscreenBookshelf && fullscreenSelectedBook != nil {
            // In fullscreen chapters - show back button
            actionButton(icon: "chevron.left") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    fullscreenSelectedBook = nil
                }
                HapticManager.shared.selection()
            }
        } else {
            HStack(spacing: 12) {
                // Bookshelf button - opens to books grid view
                actionButton(icon: "books.vertical") {
                    if viewModel.showBookshelf {
                        dismissBookshelf()
                    } else {
                        viewModel.openBookshelf()
                    }
                    HapticManager.shared.selection()
                }
                
                // Mic button
                actionButton(icon: "mic.fill") {
                    withAnimation {
                        voiceSearchViewModel.openAndStartListening(with: viewModel.languageMode)
                    }
                    HapticManager.shared.selection()
                }
            }
        }
    }
    
    private func actionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.glassCircleClear)
    }
}

#Preview {
    ContentView()
}

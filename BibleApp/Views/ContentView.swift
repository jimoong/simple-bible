import SwiftUI

struct ContentView: View {
    @State private var viewModel = BibleViewModel()
    @State private var searchText: String = ""
    @State private var voiceSearchViewModel = VoiceSearchViewModel()
    @State private var fullscreenSelectedBook: BibleBook? = nil  // Book selected within fullscreen bookshelf
    
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
            let maxPanelHeight = geometry.size.height * 0.6
            
            ZStack {
                // Main slot machine view
                SlotMachineView(viewModel: viewModel) {
                    // Header tap action - toggle bookshelf (shows chapters for current book)
                    if viewModel.showBookshelf {
                        dismissBookshelf()
                    } else {
                        viewModel.openBookshelf(showChapters: true)
                    }
                    HapticManager.shared.selection()
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
                                book: fullscreenSelectedBook!,
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
                
                // Chapter grid - top panel (from header tap, fits content up to 60%)
                if isShowingTopPanelChapters {
                    VStack(spacing: 0) {
                        ChapterGridView(
                            viewModel: viewModel,
                            currentBook: $viewModel.selectedBookForChapter,
                            maxHeight: maxPanelHeight,
                            safeAreaTop: geometry.safeAreaInsets.top,
                            onChapterSelect: { book, chapter in
                                dismissBookshelf()
                                Task {
                                    await viewModel.navigateTo(book: book, chapter: chapter)
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
                    .zIndex(2)
                }
                
                // Floating controls at bottom
                VStack {
                    Spacer()
                    
                    // Bottom: Action buttons (left) + Language toggle (right)
                    HStack(alignment: .bottom) {
                        leftActionButtons
                        Spacer()
                        languageToggleButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                }
                .ignoresSafeArea()
                .zIndex(3)
                
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
            }
        }
    }
    
    private func setupVoiceSearchNavigation() {
        voiceSearchViewModel.onNavigate = { book, chapter, verse in
            await viewModel.navigateTo(book: book, chapter: chapter, verse: verse)
        }
    }
    
    private func dismissBookshelf() {
        viewModel.isSearchActive = false
        searchText = ""
        fullscreenSelectedBook = nil
        viewModel.dismissBookshelf()
        HapticManager.shared.selection()
    }
    
    // MARK: - Language Toggle Button
    private var languageToggleButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                viewModel.toggleLanguage()
            }
        } label: {
            HStack(spacing: 4) {
                Text("EN")
                    .fontWeight(viewModel.languageMode == .en ? .bold : .regular)
                    .foregroundStyle(viewModel.languageMode == .en ? theme.textPrimary : theme.textSecondary.opacity(0.5))
                
                Text("/")
                    .foregroundStyle(theme.textSecondary.opacity(0.3))
                
                Text("KR")
                    .fontWeight(viewModel.languageMode == .kr ? .bold : .regular)
                    .foregroundStyle(viewModel.languageMode == .kr ? theme.textPrimary : theme.textSecondary.opacity(0.5))
            }
            .font(.system(size: 17, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.regularMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                Capsule()
                    .stroke(theme.textPrimary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.3), value: viewModel.currentBook.id)
    }
    
    // MARK: - Left Action Buttons
    @FocusState private var isSearchFieldFocused: Bool
    
    @ViewBuilder
    private var leftActionButtons: some View {
        if isShowingFullscreenBookshelf && fullscreenSelectedBook == nil {
            // In books grid - show search
            if viewModel.isSearchActive {
                searchInputBox
            } else {
                actionButton(icon: "magnifyingglass") {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.isSearchActive = true
                    }
                    HapticManager.shared.selection()
                }
            }
        } else if isShowingFullscreenBookshelf && fullscreenSelectedBook != nil {
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
                
                // Mic button (only when not in bookshelf)
                if !viewModel.showBookshelf {
                    actionButton(icon: "mic.fill") {
                        withAnimation {
                            voiceSearchViewModel.openAndStartListening(with: viewModel.languageMode)
                        }
                        HapticManager.shared.selection()
                    }
                }
            }
        }
    }
    
    // MARK: - Search Input Box (bottom left, replaces search button)
    private var searchInputBox: some View {
        HStack(spacing: 8) {
            TextField("Search", text: $searchText)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .focused($isSearchFieldFocused)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.isSearchActive = false
                    searchText = ""
                    isSearchFieldFocused = false
                }
            } label: {
                Text("Cancel")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.regularMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .frame(maxWidth: 280)
        .onAppear {
            isSearchFieldFocused = true
        }
    }
    
    private func actionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(.regularMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}

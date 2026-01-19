import SwiftUI

/// Full-screen listening mode view
/// Uses exact same scroll view as BookReadingView with player overlay
struct ListeningModeView: View {
    @Bindable var viewModel: ListeningViewModel
    @Bindable var bibleViewModel: BibleViewModel
    let theme: BookTheme
    let safeAreaTop: CGFloat
    let safeAreaBottom: CGFloat
    
    // Callbacks
    var onExit: () -> Void = {}
    var onHeaderTap: () -> Void = {}  // Opens chapter info panel
    var onBookshelf: () -> Void = {}
    var onSearch: () -> Void = {}
    var onChat: () -> Void = {}
    
    @State private var scrollProxy: ScrollViewProxy?
    @ObservedObject private var fontSizeSettings = FontSizeSettings.shared
    
    private var verseFontSize: CGFloat {
        fontSizeSettings.mode.scrollBodySize
    }
    
    private var verseLineSpacing: CGFloat {
        fontSizeSettings.mode.scrollLineSpacing
    }
    
    // Chapter title from summary data (same as BookReadingView)
    private var chapterTitle: String? {
        ChapterDataManager.shared.chapterSummary(
            bookId: bibleViewModel.currentBook.id,
            chapter: bibleViewModel.currentChapter
        )?.title(for: bibleViewModel.uiLanguage)
    }
    
    var body: some View {
        // Force SwiftUI to observe these properties at the top level
        // This ensures the view re-renders when TTS updates highlighting
        let _ = viewModel.highlightedRange
        let _ = viewModel.verseReadPositions
        let _ = viewModel.currentVerseIndex
        
        GeometryReader { geometry in
            ZStack {
                // Background - same as BookReadingView
                theme.background
                    .ignoresSafeArea()
                
                // Main content - exact copy of BookReadingView structure
                ZStack {
                    verseScrollView(geometry: geometry)
                    
                    // Header - exact copy of BookReadingView
                    VStack(spacing: 0) {
                        headerView(safeAreaTop: geometry.safeAreaInsets.top)
                        Spacer()
                    }
                    .ignoresSafeArea(edges: .top)
                }
                
                // Player overlay at bottom
                VStack {
                    Spacer()
                    
                    ListeningPlayerView(
                        viewModel: viewModel,
                        theme: theme,
                        safeAreaBottom: geometry.safeAreaInsets.bottom,
                        languageMode: bibleViewModel.uiLanguage,
                        onBookshelf: onBookshelf,
                        onSearch: onSearch,
                        onChat: onChat,
                        onExit: onExit
                    )
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .onChange(of: viewModel.currentVerseIndex) { oldValue, newValue in
            if newValue > 0 {
                scrollToVerse(newValue)
            }
        }
        .onChange(of: viewModel.showCompletionButtons) { _, showCompletion in
            if showCompletion {
                scrollToEnd()
            }
        }
        .onAppear {
            // Refresh callbacks when view appears to ensure proper observation
            viewModel.refreshCallbacks()
            // Note: markViewReady() is called from ScrollViewReader's onAppear
            // to ensure scrollProxy is set before TTS playback begins
        }
    }
    
    // MARK: - Header View (EXACT copy from BookReadingView)
    private func headerView(safeAreaTop: CGFloat) -> some View {
        HStack(spacing: 6) {
            Text(bibleViewModel.headerText)
                .font(theme.header(13))
                .foregroundStyle(theme.textPrimary.opacity(0.8))
            
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(theme.textPrimary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, safeAreaTop + 6)
        .padding(.bottom, 8)
        .background(theme.background)
        .contentShape(Rectangle())
        .onTapGesture {
            // Pause and open chapter info panel (same as normal reading mode)
            viewModel.pauseForNavigation()
            onHeaderTap()
        }
    }
    
    // MARK: - Verse Scroll View (EXACT copy from BookReadingView with TTS additions)
    private func verseScrollView(geometry: GeometryProxy) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 4) {
                    // Top padding for header + chapter title (same as BookReadingView)
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: geometry.safeAreaInsets.top + 40)
                        
                        // Chapter title (left-aligned) - same as BookReadingView
                        if let title = chapterTitle {
                            Text(title)
                                .font(theme.verseText(24, language: bibleViewModel.uiLanguage).bold())
                                .foregroundStyle(theme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 40)
                        } else {
                            Spacer()
                                .frame(height: 40)
                        }
                    }
                    
                    // All verses in a continuous flow (same structure as BookReadingView)
                    // Use sessionId to force full refresh when chapter changes
                    ForEach(Array(viewModel.verses.enumerated()), id: \.element.id) { index, verse in
                        let isCurrentVerse = index == viewModel.currentVerseIndex
                        let highlightedRange = isCurrentVerse ? viewModel.highlightedRange : nil
                        let maxReadPosition = viewModel.verseReadPositions[index] ?? 0
                        let isCompleted = index < viewModel.currentVerseIndex
                        
                        ListeningVerseRow(
                            verse: verse,
                            index: index,
                            language: bibleViewModel.languageMode,
                            theme: theme,
                            fontSize: verseFontSize,
                            lineSpacing: verseLineSpacing,
                            isCurrentVerse: isCurrentVerse,
                            highlightedRange: highlightedRange,
                            maxReadPosition: maxReadPosition,
                            isCompleted: isCompleted,
                            isFinished: viewModel.showCompletionButtons
                        )
                        // Force row update when its specific data changes
                        .id("\(viewModel.sessionId)-\(index)-\(maxReadPosition)")
                    }
                    
                    // Mark as read at the end (same as BookReadingView)
                    MarkAsReadCard(
                        bookId: bibleViewModel.currentBook.id,
                        chapter: bibleViewModel.currentChapter,
                        theme: theme,
                        languageMode: bibleViewModel.uiLanguage,
                        canGoToNextChapter: bibleViewModel.canGoToNextChapter,
                        onNextChapter: {
                            goToNextChapter()
                        }
                    )
                    .padding(.top, 40)
                    .id("markAsRead")
                }
                .padding(.horizontal, 8)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: geometry.safeAreaInsets.bottom + 280)  // Extra space for player
            }
            .scrollIndicators(.visible)
            .id(viewModel.sessionId)  // Force scroll view refresh when chapter changes
            .onAppear {
                scrollProxy = proxy
                // Initial scroll to starting verse if not from beginning
                if viewModel.currentVerseIndex > 0 {
                    // Delay to ensure view layout is complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        scrollToVerse(viewModel.currentVerseIndex)
                    }
                }
                // Mark view ready AFTER scrollProxy is set - this triggers TTS playback
                viewModel.markViewReady()
            }
        }
    }
    
    // MARK: - Scroll Helpers
    
    private func scrollToVerse(_ index: Int) {
        // Use the same ID format as the verse rows (sessionId-index)
        let verseId = "\(viewModel.sessionId)-\(index)"
        withAnimation(.easeInOut(duration: 0.4)) {
            scrollProxy?.scrollTo(verseId, anchor: .center)
        }
    }
    
    private func scrollToEnd() {
        withAnimation(.easeInOut(duration: 0.6)) {
            scrollProxy?.scrollTo("markAsRead", anchor: .center)
        }
    }
    
    // MARK: - Actions
    
    private func goToNextChapter() {
        Task {
            await bibleViewModel.goToNextChapter()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.start(verses: bibleViewModel.verses, language: bibleViewModel.languageMode)
            }
        }
    }
}

// MARK: - Listening Verse Row (same layout as BookVerseRow with TTS text opacity)

struct ListeningVerseRow: View {
    let verse: BibleVerse
    let index: Int
    let language: LanguageMode
    let theme: BookTheme
    let fontSize: CGFloat
    let lineSpacing: CGFloat
    let isCurrentVerse: Bool
    let highlightedRange: NSRange?
    let maxReadPosition: Int  // Tracked by ViewModel - never decreases
    let isCompleted: Bool
    let isFinished: Bool
    
    // Verse number opacity
    private var verseNumberOpacity: Double {
        if isFinished || isCompleted || maxReadPosition > 0 {
            return 0.6
        } else {
            return 0.25
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            // Verse text on the left - takes remaining space (same as BookVerseRow)
            Text(attributedText)
                .font(theme.verseText(fontSize, language: language))
                .lineSpacing(lineSpacing)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Verse number on the right - fixed width (same as BookVerseRow)
            Text("\(verse.verseNumber)")
                .font(theme.verseNumber(12, language: language))
                .foregroundStyle(theme.textSecondary.opacity(verseNumberOpacity))
                .frame(width: 18, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
    
    // Create attributed text with progressive opacity based on reading progress
    private var attributedText: AttributedString {
        let verseText = verse.text(for: language)
        var text = AttributedString(verseText)
        
        let dimmedColor = theme.textPrimary.opacity(0.3)
        let fullColor = theme.textPrimary
        
        if isFinished {
            // All finished - full opacity
            text.foregroundColor = fullColor
        } else if isCompleted {
            // Already read - full opacity
            text.foregroundColor = fullColor
        } else {
            // Use maxReadPosition from ViewModel (never decreases)
            // This prevents flashing when highlightedRange becomes nil during transitions
            let effectivePosition: Int
            if let range = highlightedRange {
                effectivePosition = max(maxReadPosition, range.location + range.length)
            } else {
                effectivePosition = maxReadPosition
            }
            
            if effectivePosition > 0 {
                // Start with dimmed base
                text.foregroundColor = dimmedColor
                
                // Full opacity for read portion
                let readPosition = min(effectivePosition, verseText.count)
                let startIdx = text.startIndex
                let endIdx = text.index(startIdx, offsetByCharacters: readPosition)
                text[startIdx..<endIdx].foregroundColor = fullColor
            } else {
                // Not started yet - all dimmed
                text.foregroundColor = dimmedColor
            }
        }
        
        return text
    }
}

#Preview {
    ListeningModeView(
        viewModel: ListeningViewModel(),
        bibleViewModel: BibleViewModel(),
        theme: BookThemes.genesis,
        safeAreaTop: 59,
        safeAreaBottom: 34
    )
}

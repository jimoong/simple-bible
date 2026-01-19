import SwiftUI

struct BookReadingView: View {
    @Bindable var viewModel: BibleViewModel
    var isMultiSelectMode: Bool = false
    @Binding var selectedVerseIndices: Set<Int>
    var onHeaderTap: () -> Void = {}
    var onSaveVerse: ((BibleVerse) -> Void)? = nil
    var onCopyVerse: ((BibleVerse) -> Void)? = nil
    var onAskVerse: ((BibleVerse) -> Void)? = nil
    var onListenFromVerse: ((Int) -> Void)? = nil  // Listen from verse index
    var onMultiSelectVerse: ((Int) -> Void)? = nil  // Enter multi-select with this verse index
    var onScrollStateChange: ((Bool) -> Void)? = nil  // true = scrolling, false = idle
    var externalControlsHidden: Bool = false  // External state to sync with
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var highlightedVerseNumber: Int? = nil
    @State private var controlsHidden: Bool = false  // Track if controls are hidden due to scrolling
    @ObservedObject private var fontSizeSettings = FontSizeSettings.shared
    
    private let swipeThreshold: CGFloat = 100
    
    private var verseFontSize: CGFloat {
        fontSizeSettings.mode.scrollBodySize
    }
    
    private var verseLineSpacing: CGFloat {
        fontSizeSettings.mode.scrollLineSpacing
    }
    
    private var theme: BookTheme {
        viewModel.currentTheme
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                theme.background
                    .ignoresSafeArea()
                    .animation(.easeOut(duration: 0.4), value: viewModel.currentBook.id)
                
                // Main content
                ZStack {
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else {
                        verseScrollView(geometry: geometry)
                    }
                    
                    // Header
                    VStack(spacing: 0) {
                        headerView(safeAreaTop: geometry.safeAreaInsets.top)
                        Spacer()
                    }
                    .ignoresSafeArea(edges: .top)
                }
                .offset(x: dragOffset)
                .simultaneousGesture(horizontalSwipeGesture)
            }
        }
        .task {
            await viewModel.loadCurrentChapter()
        }
    }
    
    // MARK: - Header View
    private func headerView(safeAreaTop: CGFloat) -> some View {
        Button {
            onHeaderTap()
        } label: {
            HStack(spacing: 6) {
                Text(viewModel.headerText)
                    .font(theme.header(13))
                    .foregroundStyle(theme.textPrimary.opacity(0.8))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.textPrimary.opacity(0.5))
                    .rotationEffect(.degrees(viewModel.showBookshelf ? 180 : 0))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, safeAreaTop + 6)
            .padding(.bottom, 8)
            .background(theme.background)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.3), value: viewModel.currentBook.id)
        .animation(.easeOut(duration: 0.2), value: viewModel.showBookshelf)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.textSecondary))
                .scaleEffect(1.1)
            
            Text("Loading")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(theme.textSecondary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                Task {
                    await viewModel.loadCurrentChapter()
                }
            } label: {
                Text("Try Again")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.glass)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Chapter title from summary data
    private var chapterTitle: String? {
        ChapterDataManager.shared.chapterSummary(
            bookId: viewModel.currentBook.id,
            chapter: viewModel.currentChapter
        )?.title(for: viewModel.uiLanguage)
    }
    
    // MARK: - Verse Scroll View (Book Mode)
    private func verseScrollView(geometry: GeometryProxy) -> some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 4) {
                    // Top padding for header + chapter title
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: geometry.safeAreaInsets.top + 40)
                        
                        // Chapter title (left-aligned)
                        if let title = chapterTitle {
                            Text(title)
                                .font(theme.verseText(24, language: viewModel.uiLanguage).bold())
                                .foregroundStyle(theme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.bottom, 40)
                        } else {
                            Spacer()
                                .frame(height: 40)
                        }
                    }
                    
                    // All verses in a continuous flow
                    ForEach(Array(viewModel.verses.enumerated()), id: \.element.id) { index, verse in
                        BookVerseRow(
                            verse: verse,
                            language: viewModel.languageMode,
                            theme: theme,
                            fontSize: verseFontSize,
                            lineSpacing: verseLineSpacing,
                            isHighlighted: highlightedVerseNumber == verse.verseNumber,
                            isMultiSelectMode: isMultiSelectMode,
                            isSelected: selectedVerseIndices.contains(index),
                            onSave: {
                                onSaveVerse?(verse)
                            },
                            onCopy: {
                                onCopyVerse?(verse)
                            },
                            onAsk: {
                                onAskVerse?(verse)
                            },
                            onListen: {
                                onListenFromVerse?(index)
                            },
                            onSelect: {
                                toggleVerseSelection(index)
                            },
                            onMultiSelect: {
                                onMultiSelectVerse?(index)
                            }
                        )
                        .id(verse.verseNumber)
                    }
                    
                    // Mark as read at the end
                    MarkAsReadCard(
                        bookId: viewModel.currentBook.id,
                        chapter: viewModel.currentChapter,
                        theme: theme,
                        languageMode: viewModel.uiLanguage,
                        canGoToNextChapter: viewModel.canGoToNextChapter,
                        onNextChapter: {
                            Task {
                                await viewModel.goToNextChapter()
                            }
                        }
                    )
                    .padding(.top, 40)
                }
                .padding(.horizontal, 12)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: geometry.safeAreaInsets.bottom + 100)
            }
            .scrollIndicators(.visible)
            .scrollDisabled(isDragging)  // Lock vertical scroll during horizontal swipe
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { _ in
                        // User started scrolling - hide controls
                        if !controlsHidden && !isDragging {
                            controlsHidden = true
                            onScrollStateChange?(true)
                        }
                    }
            )
            .onChange(of: viewModel.targetVerseNumber) { _, newValue in
                if let targetVerse = newValue {
                    // Use animation when navigating while already in view
                    scrollToVerse(targetVerse, proxy: scrollProxy, animated: true)
                }
            }
            .onAppear {
                // Handle initial target verse when view appears
                if let targetVerse = viewModel.targetVerseNumber {
                    // Delay to ensure ScrollView layout is complete (longer on cold start)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        scrollToVerse(targetVerse, proxy: scrollProxy, animated: false)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap to show controls if hidden
            if controlsHidden {
                controlsHidden = false
                onScrollStateChange?(false)
            }
        }
        .onChange(of: externalControlsHidden) { _, newValue in
            // Sync internal state when external state changes (e.g., returning from favorites)
            if !newValue && controlsHidden {
                controlsHidden = false
            }
        }
    }
    
    // MARK: - Multi-Select Helper
    private func toggleVerseSelection(_ index: Int) {
        if selectedVerseIndices.contains(index) {
            selectedVerseIndices.remove(index)
        } else {
            selectedVerseIndices.insert(index)
        }
        HapticManager.shared.selection()
    }
    
    // MARK: - Scroll to Verse Helper
    private func scrollToVerse(_ verseNumber: Int, proxy: ScrollViewProxy, animated: Bool) {
        // Scroll to the verse, centered on screen
        if animated {
            withAnimation(.easeOut(duration: 0.4)) {
                proxy.scrollTo(verseNumber, anchor: .center)
            }
        } else {
            // No animation - instant scroll for initial landing
            proxy.scrollTo(verseNumber, anchor: .center)
        }
        
        // Show highlight effect (always animated for visibility)
        withAnimation(.easeIn(duration: 0.3)) {
            highlightedVerseNumber = verseNumber
        }
        
        // Clear target verse from view model
        viewModel.clearTargetVerse()
        
        // Remove highlight after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                highlightedVerseNumber = nil
            }
        }
    }
    
    // MARK: - Horizontal Swipe Gesture
    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                // Only recognize as horizontal swipe if width is significantly greater than height
                let horizontalAmount = abs(value.translation.width)
                let verticalAmount = abs(value.translation.height)
                
                // Must be predominantly horizontal (at least 2:1 ratio) to start dragging
                if horizontalAmount > verticalAmount * 2 && horizontalAmount > 30 {
                    isDragging = true
                    dragOffset = value.translation.width
                } else if isDragging {
                    // Already dragging, continue to track
                    dragOffset = value.translation.width
                }
            }
            .onEnded { value in
                guard isDragging else { return }
                isDragging = false
                
                let horizontalAmount = value.translation.width
                let velocity = value.predictedEndTranslation.width - value.translation.width
                
                let shouldGoBack = (horizontalAmount > swipeThreshold || velocity > 200) && viewModel.canGoToPreviousChapter
                let shouldGoForward = (horizontalAmount < -swipeThreshold || velocity < -200) && viewModel.canGoToNextChapter
                
                if shouldGoBack {
                    withAnimation(.easeOut(duration: 0.2)) {
                        dragOffset = UIScreen.main.bounds.width
                    }
                    Task {
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        await viewModel.goToPreviousChapter()
                        dragOffset = -UIScreen.main.bounds.width
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = 0
                        }
                    }
                } else if shouldGoForward {
                    withAnimation(.easeOut(duration: 0.2)) {
                        dragOffset = -UIScreen.main.bounds.width
                    }
                    Task {
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        await viewModel.goToNextChapter()
                        dragOffset = UIScreen.main.bounds.width
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = 0
                        }
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.25)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

// MARK: - Book Verse Row (verse number on left, text on right)
struct BookVerseRow: View {
    let verse: BibleVerse
    let language: LanguageMode
    let theme: BookTheme
    let fontSize: CGFloat
    let lineSpacing: CGFloat
    var isHighlighted: Bool = false
    var isMultiSelectMode: Bool = false
    var isSelected: Bool = false
    var onSave: (() -> Void)? = nil
    var onCopy: (() -> Void)? = nil
    var onAsk: (() -> Void)? = nil
    var onListen: (() -> Void)? = nil
    var onSelect: (() -> Void)? = nil  // Tap handler for multi-select mode
    var onMultiSelect: (() -> Void)? = nil  // Enter multi-select mode with this verse selected
    
    @State private var isFavorite: Bool = false
    @State private var highlightedCharCount: Int = 0
    @State private var highlightTimer: Timer?
    
    // Highlighted text for saved verses - progressively highlights characters
    private var highlightedText: AttributedString {
        let verseString = verse.text(for: language)
        var text = AttributedString(verseString)
        
        if isFavorite && highlightedCharCount > 0 {
            let endIndex = min(highlightedCharCount, verseString.count)
            if endIndex > 0 {
                let startIdx = text.startIndex
                let endIdx = text.index(startIdx, offsetByCharacters: endIndex)
                text[startIdx..<endIdx].backgroundColor = Color(theme.highlightAccent.opacity(0.25))
            }
        }
        return text
    }
    
    // Check favorite status
    private func checkFavoriteStatus() {
        let wasFavorite = FavoriteService.shared.isFavorite(
            bookName: verse.bookName,
            chapter: verse.chapter,
            verseNumber: verse.verseNumber
        )
        if wasFavorite != isFavorite {
            isFavorite = wasFavorite
            if wasFavorite {
                highlightedCharCount = verse.text(for: language).count
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            // Verse text on the left - takes remaining space
            Text(highlightedText)
                .font(theme.verseText(fontSize, language: language))
                .foregroundStyle(theme.textPrimary)
                .lineSpacing(lineSpacing)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Verse number on the right - fixed width
            Text("\(verse.verseNumber)")
                .font(theme.verseNumber(12, language: language))
                .foregroundStyle(theme.textSecondary.opacity(0.6))
                .frame(width: 18, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Group {
                if isMultiSelectMode {
                    if isSelected {
                        // Selected: filled background, no border
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(theme.textPrimary.opacity(0.08))
                    } else {
                        // Unselected: border only
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(theme.textSecondary.opacity(0.2), lineWidth: 1)
                    }
                } else {
                    // Normal mode: highlight on navigation
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(theme.textPrimary.opacity(isHighlighted ? 0.08 : 0))
                }
            }
        )
        .animation(.easeOut(duration: 0.3), value: isHighlighted)
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .contentShape(Rectangle())
        .overlay {
            // Tap overlay only active in multi-select mode
            if isMultiSelectMode {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect?()
                    }
            }
        }
        .onAppear {
            checkFavoriteStatus()
        }
        .onChange(of: verse.id) { _, _ in
            // When verse changes (scroll reuse), re-check favorite status
            checkFavoriteStatus()
        }
        .onChange(of: FavoriteService.shared.favorites.count) { _, _ in
            // When favorites list changes, re-check status
            checkFavoriteStatus()
        }
        .onChange(of: isFavorite) { oldValue, newValue in
            if !newValue && oldValue {
                // Removed from favorites
                highlightTimer?.invalidate()
                highlightedCharCount = 0
            }
        }
        .onDisappear {
            highlightTimer?.invalidate()
        }
        .onReceive(NotificationCenter.default.publisher(for: .verseFavoriteSaved)) { notification in
            // Check if this notification is for this verse
            guard let userInfo = notification.userInfo,
                  let bookName = userInfo["bookName"] as? String,
                  let chapter = userInfo["chapter"] as? Int,
                  let verseNumber = userInfo["verseNumber"] as? Int,
                  bookName == verse.bookName,
                  chapter == verse.chapter,
                  verseNumber == verse.verseNumber else { return }
            
            // Update favorite state and animate after delay
            isFavorite = true
            animateHighlight()
        }
        .onReceive(NotificationCenter.default.publisher(for: .verseFavoriteRemoved)) { notification in
            // Check if this notification is for this verse
            guard let userInfo = notification.userInfo,
                  let bookNameEn = userInfo["bookNameEn"] as? String,
                  let chapter = userInfo["chapter"] as? Int,
                  let verseNumber = userInfo["verseNumber"] as? Int,
                  bookNameEn == verse.bookName,
                  chapter == verse.chapter,
                  verseNumber == verse.verseNumber else { return }
            
            // Immediately remove highlight
            highlightTimer?.invalidate()
            highlightedCharCount = 0
            isFavorite = false
        }
        .contextMenu(isMultiSelectMode ? nil : ContextMenu {
            Button {
                onSave?()
                // State change handled by notification after actual save
            } label: {
                Label(
                    isFavorite 
                        ? (language == .kr ? "저장됨" : "Saved")
                        : (language == .kr ? "저장" : "Save"),
                    systemImage: isFavorite ? "heart.fill" : "heart"
                )
            }
            
            Button {
                onCopy?()
            } label: {
                Label(
                    language == .kr ? "복사" : "Copy",
                    systemImage: "doc.on.doc"
                )
            }
            
            Button {
                onMultiSelect?()
            } label: {
                Label(
                    language == .kr ? "선택하기" : "Select",
                    systemImage: "checkmark.circle"
                )
            }
            
            Button {
                onListen?()
            } label: {
                Label(
                    language == .kr ? "여기서부터 듣기" : "Listen from here",
                    systemImage: "play.fill"
                )
            }
            
            Button {
                onAsk?()
            } label: {
                Label(
                    language == .kr ? "물어보기" : "Ask",
                    systemImage: "sparkle"
                )
            }
        })
    }
    
    // Animate highlight like drawing with a highlighter pen
    private func animateHighlight() {
        let totalChars = verse.text(for: language).count
        highlightedCharCount = 0
        
        // Wait for context menu to close, then animate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let duration: Double = 0.6  // Slower animation for visibility
            let charsPerTick = max(1, totalChars / 20)  // More ticks for smoother animation
            let interval = duration / Double(max(1, totalChars / charsPerTick))
            
            highlightTimer?.invalidate()
            highlightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
                if highlightedCharCount < totalChars {
                    highlightedCharCount = min(highlightedCharCount + charsPerTick, totalChars)
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedIndices: Set<Int> = []
        
        var body: some View {
            BookReadingView(
                viewModel: BibleViewModel(),
                selectedVerseIndices: $selectedIndices
            )
        }
    }
    return PreviewWrapper()
}

import SwiftUI

struct SlotMachineView: View {
    @Bindable var viewModel: BibleViewModel
    var onHeaderTap: () -> Void = {}
    var onSaveVerse: ((BibleVerse) -> Void)? = nil
    var onCopyVerse: ((BibleVerse) -> Void)? = nil
    @State private var scrollPosition: Int?
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var isScrubbing: Bool = false
    
    private let swipeThreshold: CGFloat = 100
    
    private var theme: BookTheme {
        viewModel.currentTheme
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Vibrant book-specific background (stays fixed)
                theme.background
                    .ignoresSafeArea()
                    .animation(.easeOut(duration: 0.4), value: viewModel.currentBook.id)
                
                // Full-screen card content (moves with drag)
                ZStack {
                    // Verse scroller
                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else {
                        HStack(spacing: 0) {
                            verseScrollView(geometry: geometry)
                                .contentShape(Rectangle())
                                .onTapGesture { location in
                                    // Top 30% = previous verse, bottom 70% = next verse
                                    let tapY = location.y
                                    let threshold = geometry.size.height * 0.3
                                    // Total items includes verses + mark as read card
                                    let maxIndex = viewModel.verses.count // Last index is the mark as read card
                                    
                                    if tapY < threshold {
                                        // Top 30% - go to previous verse
                                        let prevIndex = max((scrollPosition ?? viewModel.currentVerseIndex) - 1, 0)
                                        guard prevIndex != scrollPosition else { return }
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            scrollPosition = prevIndex
                                        }
                                    } else {
                                        // Bottom 70% - go to next item (verse or mark as read card)
                                        let currentPos = scrollPosition ?? viewModel.currentVerseIndex
                                        let nextIndex = min(currentPos + 1, maxIndex)
                                        guard nextIndex != scrollPosition else { return }
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            scrollPosition = nextIndex
                                        }
                                    }
                                }
                            
                            // Verse index scrubber on right edge
                            verseIndexScrubber(geometry: geometry)
                        }
                    }
                    
                    // Minimal top header - flush to top
                    VStack(spacing: 0) {
                        headerView(safeAreaTop: geometry.safeAreaInsets.top)
                        Spacer()
                    }
                    .ignoresSafeArea(edges: .top)
                }
                .offset(x: dragOffset)  // Entire card moves together
                .gesture(horizontalSwipeGesture)
            }
        }
        .onChange(of: scrollPosition) { oldValue, newValue in
            // Only sync to viewModel if not scrubbing and not navigating (scrubber updates both directly)
            // isNavigating prevents race conditions when navigateTo is setting the verse index
            if !isScrubbing, !viewModel.isNavigating, let newValue, newValue != viewModel.currentVerseIndex {
                viewModel.onVerseSnap(to: newValue)
            }
        }
        .onChange(of: viewModel.currentVerseIndex) { oldValue, newValue in
            // Debug logging for Numbers navigation issue
            #if DEBUG
            if viewModel.currentBook.id == "numbers" && viewModel.currentChapter == 1 {
                if newValue < viewModel.verses.count {
                    let verse = viewModel.verses[newValue]
                    print("📺 DISPLAY: index=\(newValue), verseNumber=\(verse.verseNumber)")
                }
            }
            #endif
            
            if scrollPosition != newValue {
                // Skip animation during scrubbing for immediate response
                if isScrubbing {
                    scrollPosition = newValue
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        scrollPosition = newValue
                    }
                }
            }
        }
        .task {
            await viewModel.loadCurrentChapter()
        }
    }
    
    // MARK: - Minimal Header - flush to top, tappable
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
            .background(
                theme.background.opacity(0.85)
            )
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
            .buttonStyle(.glassClear)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Verse Scroll View
    private func verseScrollView(geometry: GeometryProxy) -> some View {
        let verseHeight = geometry.size.height * 0.38
        let verticalPadding = geometry.size.height * 0.31
        // Total items: verses + 1 for the "Mark as read" card
        let totalItems = viewModel.verses.count + 1
        let markAsReadIndex = viewModel.verses.count
        
        return ScrollView(.vertical) {
            LazyVStack(spacing: 16) {
                ForEach(0..<totalItems, id: \.self) { index in
                    if index < viewModel.verses.count {
                        // Regular verse card
                        VerseCardView(
                            verse: viewModel.verses[index],
                            language: viewModel.languageMode,
                            theme: theme,
                            isCentered: index == viewModel.currentVerseIndex,
                            onSave: {
                                onSaveVerse?(viewModel.verses[index])
                            },
                            onCopy: {
                                onCopyVerse?(viewModel.verses[index])
                            }
                        )
                        .slotMachineEffect(isScrubbing: isScrubbing)
                        .id(index)
                        .frame(maxWidth: .infinity)
                        .frame(height: verseHeight, alignment: .center)
                    } else {
                        // Mark as read card at the end
                        MarkAsReadCard(
                            bookId: viewModel.currentBook.id,
                            chapter: viewModel.currentChapter,
                            theme: theme,
                            languageMode: viewModel.uiLanguage
                        )
                        .slotMachineEffect(isScrubbing: isScrubbing)
                        .id(markAsReadIndex)
                        .frame(maxWidth: .infinity)
                        .frame(height: verseHeight, alignment: .center)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .contentMargins(.vertical, verticalPadding, for: .scrollContent)
    }
    
    // MARK: - Verse Index Scrubber (iOS Contacts style)
    private func verseIndexScrubber(geometry: GeometryProxy) -> some View {
        let totalVerses = viewModel.verses.count
        let displayItems: [ScrubberDisplayItem] = buildDisplayItems(totalVerses: totalVerses)
        let numberHeight: CGFloat = 14
        let dotHeight: CGFloat = 10
        let itemSpacing: CGFloat = 8
        let contentHeight = displayItems.reduce(0) { sum, item in
            sum + (item.isDot ? dotHeight : numberHeight)
        } + CGFloat(max(0, displayItems.count - 1)) * itemSpacing
        
        return VStack(spacing: itemSpacing) {
            ForEach(Array(displayItems.enumerated()), id: \.offset) { _, item in
                scrubberItemView(item: item, currentIndex: viewModel.currentVerseIndex, totalVerses: totalVerses)
            }
        }
        .frame(width: 28, height: contentHeight)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    guard contentHeight > 0, totalVerses > 0 else { return }
                    
                    // Map Y position (0 to contentHeight) to verse index (0 to totalVerses-1)
                    let clampedY = max(0, min(contentHeight, value.location.y))
                    let fraction = clampedY / contentHeight
                    let targetIndex = Int(round(fraction * CGFloat(totalVerses - 1)))
                    let finalIndex = max(0, min(totalVerses - 1, targetIndex))
                    
                    if finalIndex != scrollPosition {
                        // Disable all animations during scrubbing
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            scrollPosition = finalIndex
                            viewModel.currentVerseIndex = finalIndex
                        }
                        
                        if !isScrubbing {
                            isScrubbing = true
                            HapticManager.shared.lightClick()
                        } else {
                            HapticManager.shared.selection()
                        }
                    }
                }
                .onEnded { _ in
                    isScrubbing = false
                }
        )
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(.trailing, 4)
        .animation(.none, value: scrollPosition)
    }
    
    private struct ScrubberDisplayItem {
        let label: String      // "1", "10", "·", etc.
        let verseNumber: Int   // 1-indexed verse number this represents
        let isDot: Bool
    }
    
    private func buildDisplayItems(totalVerses: Int) -> [ScrubberDisplayItem] {
        var items: [ScrubberDisplayItem] = []
        
        guard totalVerses > 0 else { return items }
        
        if totalVerses <= 20 {
            // 1-20: Show all numbers
            for v in 1...totalVerses {
                items.append(ScrubberDisplayItem(label: "\(v)", verseNumber: v, isDot: false))
            }
        } else if totalVerses <= 50 {
            // 21-50: Show every 5 with vertical dots
            var v = 1
            while v <= totalVerses {
                items.append(ScrubberDisplayItem(label: "\(v)", verseNumber: v, isDot: false))
                // Add vertical dots between numbers if there's a next number
                if v + 5 <= totalVerses {
                    items.append(ScrubberDisplayItem(label: "⋮", verseNumber: v + 2, isDot: true))
                }
                v += 5
            }
        } else {
            // 51+: Show every 10 with vertical dots
            var v = 1
            while v <= totalVerses {
                items.append(ScrubberDisplayItem(label: "\(v)", verseNumber: v, isDot: false))
                // Add vertical dots between numbers if there's a next number
                if v + 10 <= totalVerses {
                    items.append(ScrubberDisplayItem(label: "⋮", verseNumber: v + 5, isDot: true))
                }
                v += 10
            }
        }
        
        return items
    }
    
    private func scrubberItemView(item: ScrubberDisplayItem, currentIndex: Int, totalVerses: Int) -> some View {
        // currentIndex is 0-based, item.verseNumber is 1-based
        let currentVerseNumber = currentIndex + 1
        
        // Determine highlight range based on interval
        let highlightRange: Int
        if totalVerses <= 20 {
            highlightRange = 0  // Exact match only
        } else if totalVerses <= 50 {
            highlightRange = 2  // Within 2 of the displayed number (for 5-step intervals)
        } else {
            highlightRange = 5  // Within 5 of the displayed number (for 10-step intervals)
        }
        
        let isNearCurrent = abs(item.verseNumber - currentVerseNumber) <= highlightRange
        let isExactMatch = !item.isDot && item.verseNumber == currentVerseNumber
        
        return Text(item.label)
            .font(.system(size: item.isDot ? 9 : 11, weight: isExactMatch ? .bold : .regular, design: .default))
            .foregroundStyle(
                isExactMatch ? theme.accent :
                isNearCurrent ? theme.textSecondary.opacity(0.6) :
                theme.textSecondary.opacity(0.35)
            )
            .frame(width: 28, height: item.isDot ? 10 : 14)  // Smaller height for dots
    }
    
    // MARK: - Horizontal Swipe Gesture
    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                // Only track horizontal drags
                if abs(value.translation.width) > abs(value.translation.height) {
                    isDragging = true
                    // Direct follow - view moves with finger
                    dragOffset = value.translation.width
                }
            }
            .onEnded { value in
                guard isDragging else { return }
                isDragging = false
                
                let horizontalAmount = value.translation.width
                let velocity = value.predictedEndTranslation.width - value.translation.width
                
                // Consider both distance and velocity for triggering navigation
                let shouldGoBack = (horizontalAmount > swipeThreshold || velocity > 200) && viewModel.canGoToPreviousChapter
                let shouldGoForward = (horizontalAmount < -swipeThreshold || velocity < -200) && viewModel.canGoToNextChapter
                
                if shouldGoBack {
                    // Animate off screen to the right, then load previous
                    withAnimation(.easeOut(duration: 0.2)) {
                        dragOffset = UIScreen.main.bounds.width
                    }
                    Task {
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        await viewModel.goToPreviousChapter()
                        dragOffset = -UIScreen.main.bounds.width
                        scrollPosition = 0
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = 0
                        }
                    }
                } else if shouldGoForward {
                    // Animate off screen to the left, then load next
                    withAnimation(.easeOut(duration: 0.2)) {
                        dragOffset = -UIScreen.main.bounds.width
                    }
                    Task {
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        await viewModel.goToNextChapter()
                        dragOffset = UIScreen.main.bounds.width
                        scrollPosition = 0
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = 0
                        }
                    }
                } else {
                    // Snap back
                    withAnimation(.easeOut(duration: 0.25)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

// MARK: - Mark As Read Card
struct MarkAsReadCard: View {
    let bookId: String
    let chapter: Int
    let theme: BookTheme
    let languageMode: LanguageMode
    
    @State private var isRead: Bool = false
    
    var body: some View {
        VStack {
            // Mark as read toggle button
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    isRead.toggle()
                }
                ReadingProgressTracker.shared.toggleReadState(bookId: bookId, chapter: chapter)
                HapticManager.shared.selection()
            } label: {
                HStack(spacing: 8) {
                    if isRead {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                    }
                    
                    Text(isRead 
                         ? (languageMode == .kr ? "읽음으로 표시됨" : "Marked as Read")
                         : (languageMode == .kr ? "읽음으로 표시" : "Mark as Read"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(isRead ? theme.background : theme.textPrimary)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(isRead ? theme.accent : theme.surface)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 28)
        .onAppear {
            isRead = ReadingProgressTracker.shared.isChapterRead(bookId: bookId, chapter: chapter)
        }
        .onChange(of: bookId) { _, _ in
            isRead = ReadingProgressTracker.shared.isChapterRead(bookId: bookId, chapter: chapter)
        }
        .onChange(of: chapter) { _, _ in
            isRead = ReadingProgressTracker.shared.isChapterRead(bookId: bookId, chapter: chapter)
        }
    }
}

#Preview {
    SlotMachineView(viewModel: BibleViewModel())
}

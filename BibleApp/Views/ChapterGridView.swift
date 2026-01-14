import SwiftUI

struct ChapterGridView: View {
    @Bindable var viewModel: BibleViewModel
    @Binding var currentBook: BibleBook?
    var maxHeight: CGFloat = .infinity
    var safeAreaTop: CGFloat = 0
    var onChapterSelect: ((BibleBook, Int) -> Void)? = nil
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
    private let swipeThreshold: CGFloat = 100
    
    // Cell dimensions
    private let cellHeight: CGFloat = 56
    private let cellSpacing: CGFloat = 10
    private let headerHeight: CGFloat = 120  // Title + subtitle + padding (with doubled bottom)
    private let summaryHeight: CGFloat = 250  // Summary + message section (17pt font with increased line height)
    
    private var book: BibleBook {
        currentBook ?? viewModel.currentBook
    }
    
    private var theme: BookTheme {
        BookThemes.theme(for: book.id)
    }
    
    private var bookSummary: BibleBookSummary? {
        BibleBookSummaries.summary(for: book.id)
    }
    
    private var previousBook: BibleBook? {
        BibleData.previousBook(before: book)
    }
    
    private var nextBook: BibleBook? {
        BibleData.nextBook(after: book)
    }
    
    // Calculate content height based on number of chapter rows (including safe area)
    private var contentHeight: CGFloat {
        let rowCount = ceil(Double(book.chapterCount) / 5.0)
        let gridHeight = CGFloat(rowCount) * cellHeight + CGFloat(max(0, rowCount - 1)) * cellSpacing
        let summaryAddition: CGFloat = bookSummary != nil ? summaryHeight : 0
        let totalHeight = safeAreaTop + headerHeight + summaryAddition + gridHeight + 20  // 20 for bottom padding
        return min(totalHeight, maxHeight)
    }
    
    var body: some View {
        ZStack {
            // Background - extends to top
            theme.background
            
            // Content with safe area padding
            swipeableContent
                .padding(.top, safeAreaTop)
                .offset(x: dragOffset)
                .gesture(horizontalSwipeGesture)
        }
        .frame(height: contentHeight)
    }
    
    // MARK: - Swipeable Content
    private var swipeableContent: some View {
        VStack(spacing: 0) {
            // Book title (fixed header)
            VStack(spacing: 8) {
                Text(book.name(for: viewModel.uiLanguage))
                    .font(theme.display(28, language: viewModel.uiLanguage))
                    .foregroundStyle(theme.textPrimary)
                
                Text("\(book.chapterCount) \(book.chapterCount == 1 ? "chapter" : "chapters")")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.top, 20)
            .padding(.bottom, 24)
            
            // Scrollable content (summary + chapters)
            chapterGrid
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Book Summary Section
    private func bookSummarySection(_ summary: BibleBookSummary) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            // Summary
            Text(viewModel.uiLanguage == .kr ? summary.summaryKo : summary.summaryEn)
                .font(theme.verseText(17, language: viewModel.uiLanguage))
                .foregroundStyle(theme.textSecondary)
                .lineSpacing(7)
            
            // Key message
            Text(viewModel.uiLanguage == .kr ? summary.messageKo : summary.messageEn)
                .font(theme.verseText(17, language: viewModel.uiLanguage))
                .foregroundStyle(theme.textSecondary)
                .lineSpacing(7)
        }
        .multilineTextAlignment(.leading)
    }
    
    // MARK: - Chapter Grid (includes summary/message)
    private var chapterGrid: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // Book summary and message (scrollable)
                    if let summary = bookSummary {
                        bookSummarySection(summary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                    }
                    
                    // Chapter grid
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(1...book.chapterCount, id: \.self) { chapter in
                            ChapterCell(
                                chapter: chapter,
                                theme: theme,
                                isCurrentChapter: book == viewModel.currentBook && chapter == viewModel.currentChapter,
                                isRead: ReadingProgressTracker.shared.isChapterRead(bookId: book.id, chapter: chapter)
                            )
                            .id(chapter)
                            .onTapGesture {
                                if let onChapterSelect {
                                    onChapterSelect(book, chapter)
                                } else {
                                    Task {
                                        await viewModel.navigateTo(book: book, chapter: chapter)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: 350)
                    .frame(maxWidth: .infinity)
                }
                .padding(.bottom, 40)
            }
            .onAppear {
                if book == viewModel.currentBook {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(viewModel.currentChapter, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Horizontal Swipe Gesture
    private let animationDuration: Double = 0.2
    
    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                if abs(value.translation.width) > abs(value.translation.height) {
                    isDragging = true
                    dragOffset = value.translation.width
                }
            }
            .onEnded { value in
                guard isDragging else { return }
                isDragging = false
                
                let horizontalAmount = value.translation.width
                let velocity = value.predictedEndTranslation.width - value.translation.width
                
                let shouldGoBack = (horizontalAmount > swipeThreshold || velocity > 200) && previousBook != nil
                let shouldGoForward = (horizontalAmount < -swipeThreshold || velocity < -200) && nextBook != nil
                
                if shouldGoBack, let prev = previousBook {
                    // Slide current content off-screen to the right
                    withAnimation(.easeOut(duration: animationDuration)) {
                        dragOffset = UIScreen.main.bounds.width
                    }
                    // After exit, swap book and slide new content in from left
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        // Disable animation for instant reposition
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            currentBook = prev
                            dragOffset = -UIScreen.main.bounds.width
                        }
                        // Then animate slide in
                        withAnimation(.easeOut(duration: animationDuration)) {
                            dragOffset = 0
                        }
                    }
                    HapticManager.shared.selection()
                } else if shouldGoForward, let next = nextBook {
                    // Slide current content off-screen to the left
                    withAnimation(.easeOut(duration: animationDuration)) {
                        dragOffset = -UIScreen.main.bounds.width
                    }
                    // After exit, swap book and slide new content in from right
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        // Disable animation for instant reposition
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            currentBook = next
                            dragOffset = UIScreen.main.bounds.width
                        }
                        // Then animate slide in
                        withAnimation(.easeOut(duration: animationDuration)) {
                            dragOffset = 0
                        }
                    }
                    HapticManager.shared.selection()
                } else {
                    // Snap back to center
                    withAnimation(.easeOut(duration: 0.25)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

struct ChapterCell: View {
    let chapter: Int
    let theme: BookTheme
    let isCurrentChapter: Bool
    let isRead: Bool
    
    // Darker shade for read chapters - darker than parent background
    private var cellBackground: Color {
        if isCurrentChapter {
            return theme.accent
        } else if isRead {
            // Darker than the parent background
            return Color.black.opacity(0.3)
        } else {
            return theme.surface
        }
    }
    
    var body: some View {
        Text("\(chapter)")
            .font(.system(size: 18, weight: isCurrentChapter ? .bold : .medium))
            .foregroundStyle(isCurrentChapter ? theme.background : (isRead ? theme.textPrimary.opacity(0.6) : theme.textPrimary))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cellBackground)
            )
            .contentShape(Rectangle())
    }
}

// MARK: - Fullscreen Chapter Grid View (for bookshelf panel)
struct FullscreenChapterGridView: View {
    @Bindable var viewModel: BibleViewModel
    @Binding var book: BibleBook?
    var topPadding: CGFloat = 0
    var onClose: (() -> Void)? = nil
    var onChapterSelect: ((BibleBook, Int) -> Void)? = nil
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
    private let swipeThreshold: CGFloat = 100
    private let animationDuration: Double = 0.2
    
    private var currentBook: BibleBook {
        book ?? viewModel.currentBook
    }
    
    private var theme: BookTheme {
        BookThemes.theme(for: currentBook.id)
    }
    
    private var bookSummary: BibleBookSummary? {
        BibleBookSummaries.summary(for: currentBook.id)
    }
    
    private var previousBook: BibleBook? {
        BibleData.previousBook(before: currentBook)
    }
    
    private var nextBook: BibleBook? {
        BibleData.nextBook(after: currentBook)
    }
    
    var body: some View {
        ZStack {
            // Swipeable content
            swipeableContent
                .offset(x: dragOffset)
                .gesture(horizontalSwipeGesture)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
    
    // MARK: - Swipeable Content
    private var swipeableContent: some View {
        VStack(spacing: 0) {
            // Book title and chapter count (fixed header)
            VStack(spacing: 8) {
                Text(currentBook.name(for: viewModel.uiLanguage))
                    .font(theme.display(28, language: viewModel.uiLanguage))
                    .foregroundStyle(theme.textPrimary)
                
                Text("\(currentBook.chapterCount) \(currentBook.chapterCount == 1 ? "chapter" : "chapters")")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.top, topPadding + 20)
            .padding(.bottom, 24)
            
            // Scrollable content (summary + chapters)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Book summary and message (scrollable)
                        if let summary = bookSummary {
                            bookSummarySection(summary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 32)
                        }
                        
                        // Chapter grid
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(1...currentBook.chapterCount, id: \.self) { chapter in
                                ChapterCell(
                                    chapter: chapter,
                                    theme: theme,
                                    isCurrentChapter: currentBook == viewModel.currentBook && chapter == viewModel.currentChapter,
                                    isRead: ReadingProgressTracker.shared.isChapterRead(bookId: currentBook.id, chapter: chapter)
                                )
                                .id(chapter)
                                .onTapGesture {
                                    onChapterSelect?(currentBook, chapter)
                                    HapticManager.shared.selection()
                                }
                            }
                        }
                        .frame(maxWidth: 350)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 100)
                }
                .onAppear {
                    if currentBook == viewModel.currentBook {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(viewModel.currentChapter, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Book Summary Section
    private func bookSummarySection(_ summary: BibleBookSummary) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            // Summary
            Text(viewModel.uiLanguage == .kr ? summary.summaryKo : summary.summaryEn)
                .font(theme.verseText(17, language: viewModel.uiLanguage))
                .foregroundStyle(theme.textSecondary)
                .lineSpacing(7)
            
            // Key message
            Text(viewModel.uiLanguage == .kr ? summary.messageKo : summary.messageEn)
                .font(theme.verseText(17, language: viewModel.uiLanguage))
                .foregroundStyle(theme.textSecondary)
                .lineSpacing(7)
        }
        .multilineTextAlignment(.leading)
    }
    
    // MARK: - Horizontal Swipe Gesture
    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                if abs(value.translation.width) > abs(value.translation.height) {
                    isDragging = true
                    dragOffset = value.translation.width
                }
            }
            .onEnded { value in
                guard isDragging else { return }
                isDragging = false
                
                let horizontalAmount = value.translation.width
                let velocity = value.predictedEndTranslation.width - value.translation.width
                
                let shouldGoBack = (horizontalAmount > swipeThreshold || velocity > 200) && previousBook != nil
                let shouldGoForward = (horizontalAmount < -swipeThreshold || velocity < -200) && nextBook != nil
                
                if shouldGoBack, let prev = previousBook {
                    // Slide current content off-screen to the right
                    withAnimation(.easeOut(duration: animationDuration)) {
                        dragOffset = UIScreen.main.bounds.width
                    }
                    // After exit, swap book and slide new content in from left
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            book = prev
                            dragOffset = -UIScreen.main.bounds.width
                        }
                        withAnimation(.easeOut(duration: animationDuration)) {
                            dragOffset = 0
                        }
                    }
                    HapticManager.shared.selection()
                } else if shouldGoForward, let next = nextBook {
                    // Slide current content off-screen to the left
                    withAnimation(.easeOut(duration: animationDuration)) {
                        dragOffset = -UIScreen.main.bounds.width
                    }
                    // After exit, swap book and slide new content in from right
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            book = next
                            dragOffset = UIScreen.main.bounds.width
                        }
                        withAnimation(.easeOut(duration: animationDuration)) {
                            dragOffset = 0
                        }
                    }
                    HapticManager.shared.selection()
                } else {
                    // Snap back to center
                    withAnimation(.easeOut(duration: 0.25)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var book: BibleBook? = BibleData.books[42] // John
        var body: some View {
            VStack {
                ChapterGridView(
                    viewModel: BibleViewModel(),
                    currentBook: $book,
                    maxHeight: 400,
                    safeAreaTop: 59
                )
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
        }
    }
    return PreviewWrapper()
}

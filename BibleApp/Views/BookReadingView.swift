import SwiftUI

struct BookReadingView: View {
    @Bindable var viewModel: BibleViewModel
    var onHeaderTap: () -> Void = {}
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    private let swipeThreshold: CGFloat = 100
    private let verseFontSize: CGFloat = 17
    private let verseLineSpacing: CGFloat = 6
    
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
                .gesture(horizontalSwipeGesture)
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
        )?.title(for: viewModel.languageMode)
    }
    
    // MARK: - Verse Scroll View (Book Mode)
    private func verseScrollView(geometry: GeometryProxy) -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 28) {
                // Top padding for header + chapter title
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geometry.safeAreaInsets.top + 40)
                    
                    // Chapter title (left-aligned)
                    if let title = chapterTitle {
                        Text(title)
                            .font(theme.verseText(24, language: viewModel.languageMode).bold())
                            .foregroundStyle(theme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                        lineSpacing: verseLineSpacing
                    )
                }
                
                // Mark as read at the end
                MarkAsReadCard(
                    bookId: viewModel.currentBook.id,
                    chapter: viewModel.currentChapter,
                    theme: theme,
                    languageMode: viewModel.languageMode
                )
                .padding(.top, 40)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 100)
            }
            .padding(.horizontal, 24)
        }
        .scrollIndicators(.visible)
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
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            // Verse text on the left - takes remaining space
            Text(verse.text(for: language))
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
    }
}

#Preview {
    BookReadingView(viewModel: BibleViewModel())
}

import SwiftUI

struct ChapterGridView: View {
    @Bindable var viewModel: BibleViewModel
    @Binding var currentBook: BibleBook?
    let onDismiss: () -> Void
    let onClose: () -> Void
    var onChapterSelect: ((BibleBook, Int) -> Void)? = nil
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
    private let swipeThreshold: CGFloat = 100
    
    private var book: BibleBook {
        currentBook ?? viewModel.currentBook
    }
    
    private var theme: BookTheme {
        BookThemes.theme(for: book.id)
    }
    
    private var previousBook: BibleBook? {
        BibleData.previousBook(before: book)
    }
    
    private var nextBook: BibleBook? {
        BibleData.nextBook(after: book)
    }
    
    var body: some View {
        ZStack {
            // Background
            theme.background
            
            VStack(spacing: 0) {
                // Fixed header with close button
                HStack {
                    Spacer()
                    
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(theme.textPrimary.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(theme.textPrimary.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                
                // Swipeable content
                swipeableContent
                    .offset(x: dragOffset)
                    .gesture(horizontalSwipeGesture)
            }
        }
    }
    
    // MARK: - Swipeable Content
    private var swipeableContent: some View {
        VStack(spacing: 0) {
            // Book title
            VStack(spacing: 8) {
                Text(book.name(for: viewModel.languageMode))
                    .font(theme.display(32))
                    .foregroundStyle(theme.textPrimary)
                
                Text("\(book.chapterCount) \(book.chapterCount == 1 ? "chapter" : "chapters")")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
            
            // Chapter grid
            chapterGrid
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Chapter Grid
    private var chapterGrid: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(1...book.chapterCount, id: \.self) { chapter in
                        ChapterCell(
                            chapter: chapter,
                            theme: theme,
                            isCurrentChapter: book == viewModel.currentBook && chapter == viewModel.currentChapter
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
                .padding(.horizontal, 20)
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
    
    var body: some View {
        Text("\(chapter)")
            .font(.system(size: 18, weight: isCurrentChapter ? .bold : .medium))
            .foregroundStyle(isCurrentChapter ? theme.background : theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCurrentChapter ? theme.accent : theme.surface)
            )
            .contentShape(Rectangle())
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var book: BibleBook? = BibleData.books[42] // John
        var body: some View {
            ChapterGridView(
                viewModel: BibleViewModel(),
                currentBook: $book,
                onDismiss: {},
                onClose: {}
            )
        }
    }
    return PreviewWrapper()
}

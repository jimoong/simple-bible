//
//  ChapterInfoPanel.swift
//  BibleApp
//
//  Top overlay panel showing chapter-specific information in reading mode
//

import SwiftUI

struct ChapterInfoPanel: View {
    var viewModel: BibleViewModel
    var maxHeight: CGFloat = .infinity
    var safeAreaTop: CGFloat = 0
    
    @State private var measuredHeight: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    private let swipeThreshold: CGFloat = 100
    private let animationDuration: Double = 0.2
    
    private var book: BibleBook {
        viewModel.currentBook
    }
    
    private var chapter: Int {
        viewModel.currentChapter
    }
    
    private var theme: BookTheme {
        BookThemes.theme(for: book.id)
    }
    
    private var chapterSummary: ChapterSummary? {
        ChapterDataManager.shared.chapterSummary(bookId: book.id, chapter: chapter)
    }
    
    private var verseCount: Int {
        viewModel.verses.count
    }
    
    var body: some View {
        ZStack {
            // Background
            theme.background
            
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // Title: Book + Chapter
                    Text(chapterTitle)
                        .font(theme.display(28, language: viewModel.uiLanguage))
                        .foregroundStyle(theme.textPrimary)
                        .padding(.top, safeAreaTop + 20)
                    
                    // Subtitle: Chapter title + verse count
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(theme.textSecondary)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    
                    // Chapter summary and message (if available)
                    if let summary = chapterSummary {
                        chapterContentSection(summary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                    } else {
                        // Empty state
                        emptyStateView
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            measuredHeight = geo.size.height
                        }
                        .onChange(of: geo.size.height) { _, newValue in
                            measuredHeight = newValue
                        }
                    }
                )
            }
            .offset(x: dragOffset)
            .gesture(horizontalSwipeGesture)
        }
        .frame(height: min(measuredHeight, maxHeight))
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
                    // Slide current content off-screen to the right
                    withAnimation(.easeOut(duration: animationDuration)) {
                        dragOffset = UIScreen.main.bounds.width
                    }
                    // After exit, swap chapter and slide new content in from left
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        Task {
                            await viewModel.goToPreviousChapter()
                            
                            // Reset offset to the left of screen
                            var transaction = Transaction()
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                dragOffset = -UIScreen.main.bounds.width
                            }
                            // Then animate slide in
                            withAnimation(.easeOut(duration: animationDuration)) {
                                dragOffset = 0
                            }
                        }
                    }
                    HapticManager.shared.selection()
                } else if shouldGoForward {
                    // Slide current content off-screen to the left
                    withAnimation(.easeOut(duration: animationDuration)) {
                        dragOffset = -UIScreen.main.bounds.width
                    }
                    // After exit, swap chapter and slide new content in from right
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        Task {
                            await viewModel.goToNextChapter()
                            
                            // Reset offset to the right of screen
                            var transaction = Transaction()
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                dragOffset = UIScreen.main.bounds.width
                            }
                            // Then animate slide in
                            withAnimation(.easeOut(duration: animationDuration)) {
                                dragOffset = 0
                            }
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
    
    // MARK: - Title
    private var chapterTitle: String {
        let bookName = book.name(for: viewModel.uiLanguage)
        if viewModel.uiLanguage == .kr {
            return "\(bookName) \(chapter)장"
        } else {
            return "\(bookName) \(chapter)"
        }
    }
    
    // MARK: - Subtitle
    private var subtitle: String {
        let versesText = viewModel.uiLanguage == .kr 
            ? "\(verseCount)절" 
            : "\(verseCount) verses"
        
        if let summary = chapterSummary {
            let title = viewModel.uiLanguage == .kr ? summary.titleKo : summary.titleEn
            return "\(title) · \(versesText)"
        } else {
            return versesText
        }
    }
    
    // MARK: - Chapter Content Section
    private func chapterContentSection(_ summary: ChapterSummary) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 18) {
                // Summary
                Text(summary.summary(for: viewModel.uiLanguage))
                    .font(theme.verseText(17, language: viewModel.uiLanguage))
                    .foregroundStyle(theme.textSecondary)
                    .lineSpacing(7)
                
                // Key message
                Text(summary.message(for: viewModel.uiLanguage))
                    .font(theme.verseText(17, language: viewModel.uiLanguage))
                    .foregroundStyle(theme.textSecondary)
                    .lineSpacing(7)
            }
            
            // Key Events
            if !summary.keyEvents.isEmpty {
                keyEventsSection(summary.keyEvents)
            }
        }
        .multilineTextAlignment(.leading)
    }
    
    // MARK: - Key Events Section
    private func keyEventsSection(_ events: [ChapterKeyEvent]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(events) { event in
                    Button {
                        Task {
                            // Map verse number to index (typically verse - 1)
                            let verseIndex = max(0, event.verse - 1)
                            await viewModel.navigateTo(
                                book: book, 
                                chapter: chapter, 
                                verse: verseIndex
                            )
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 16) {
                            Text("\(event.verse)")
                                .font(theme.verseNumber(14, language: viewModel.uiLanguage))
                                .foregroundStyle(theme.textSecondary.opacity(0.5))
                                .frame(width: 28, alignment: .leading)
                                .padding(.top, 2)
                            
                            Text(event.event(for: viewModel.uiLanguage))
                                .font(theme.verseText(17, language: viewModel.uiLanguage))
                                .foregroundStyle(theme.textPrimary)
                                .lineSpacing(4)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text(viewModel.uiLanguage == .kr ? "준비 중입니다" : "Coming soon")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(theme.textSecondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview {
    VStack {
        ChapterInfoPanel(
            viewModel: BibleViewModel(),
            maxHeight: 400,
            safeAreaTop: 59
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
        Spacer()
    }
    .ignoresSafeArea(edges: .top)
}

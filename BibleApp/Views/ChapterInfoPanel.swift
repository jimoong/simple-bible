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
                        .font(theme.display(28, language: viewModel.languageMode))
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
        }
        .frame(height: min(measuredHeight, maxHeight))
    }
    
    // MARK: - Title
    private var chapterTitle: String {
        let bookName = book.name(for: viewModel.languageMode)
        if viewModel.languageMode == .kr {
            return "\(bookName) \(chapter)장"
        } else {
            return "\(bookName) \(chapter)"
        }
    }
    
    // MARK: - Subtitle
    private var subtitle: String {
        let versesText = viewModel.languageMode == .kr 
            ? "\(verseCount)절" 
            : "\(verseCount) verses"
        
        if let summary = chapterSummary {
            let title = viewModel.languageMode == .kr ? summary.titleKo : summary.titleEn
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
                Text(summary.summary(for: viewModel.languageMode))
                    .font(theme.verseText(17, language: viewModel.languageMode))
                    .foregroundStyle(theme.textSecondary)
                    .lineSpacing(7)
                
                // Key message
                Text(summary.message(for: viewModel.languageMode))
                    .font(theme.verseText(17, language: viewModel.languageMode))
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
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.languageMode == .kr ? "주요 사건" : "Key events")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(theme.accent)
            
            VStack(alignment: .leading, spacing: 1) {
                ForEach(Array(events.enumerated()), id: \.offset) { index, event in
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
                                .font(theme.verseNumber(14, language: viewModel.languageMode))
                                .foregroundStyle(theme.accent)
                                .frame(width: 28, alignment: .leading)
                                .padding(.top, 2)
                            
                            Text(event.event(for: viewModel.languageMode))
                                .font(theme.verseText(17, language: viewModel.languageMode))
                                .foregroundStyle(theme.textPrimary)
                                .lineSpacing(4)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            UnevenRoundedRectangle(
                                topLeadingRadius: index == 0 ? 16 : 0,
                                bottomLeadingRadius: index == events.count - 1 ? 16 : 0,
                                bottomTrailingRadius: index == events.count - 1 ? 16 : 0,
                                topTrailingRadius: index == 0 ? 16 : 0,
                                style: .continuous
                            )
                            .fill(Color.black.opacity(0.2))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text(viewModel.languageMode == .kr ? "준비 중입니다" : "Coming soon")
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

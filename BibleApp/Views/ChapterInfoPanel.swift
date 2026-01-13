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
    
    // Calculate content height based on whether we have chapter data
    private var contentHeight: CGFloat {
        let headerHeight: CGFloat = 100  // Title + subtitle
        let contentPadding: CGFloat = 60  // Top and bottom padding
        
        if chapterSummary != nil {
            // With summary: estimate based on content
            let summaryHeight: CGFloat = 280  // Summary + message with padding
            let totalHeight = safeAreaTop + headerHeight + summaryHeight + contentPadding
            return min(totalHeight, maxHeight)
        } else {
            // Empty state
            let emptyHeight: CGFloat = 100
            let totalHeight = safeAreaTop + headerHeight + emptyHeight + contentPadding
            return min(totalHeight, maxHeight)
        }
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
            }
        }
        .frame(height: contentHeight)
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
        .multilineTextAlignment(.leading)
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

//
//  MultiSelectSaveOverlay.swift
//  BibleApp
//
//  Full-screen overlay for saving multiple selected verses
//

import SwiftUI

struct MultiSelectSaveOverlay: View {
    let verses: [BibleVerse]
    let book: BibleBook
    let chapter: Int
    let language: LanguageMode
    let onSave: (String?) -> Void
    let onCancel: () -> Void
    
    @State private var noteText: String = ""
    @FocusState private var isTextEditorFocused: Bool
    
    @ObservedObject private var fontSizeSettings = FontSizeSettings.shared
    
    private var theme: BookTheme {
        BookThemes.theme(for: book.id)
    }
    
    // Font size for verse content (matching scroll mode)
    private var verseFontSize: CGFloat {
        fontSizeSettings.mode.scrollBodySize
    }
    
    private var verseLineSpacing: CGFloat {
        fontSizeSettings.mode.scrollLineSpacing
    }
    
    // Format verse range for display
    private var verseRangeText: String {
        guard !verses.isEmpty else { return "" }
        
        let verseNumbers = verses.map { $0.verseNumber }.sorted()
        let bookName = book.name(for: language)
        
        if language == .kr {
            if verseNumbers.count == 1 {
                return "\(bookName) \(chapter)장 \(verseNumbers[0])절"
            } else if let first = verseNumbers.first, let last = verseNumbers.last,
                      verseNumbers == Array(first...last) {
                // Continuous range
                return "\(bookName) \(chapter)장 \(first)-\(last)절"
            } else {
                // Non-continuous
                return "\(bookName) \(chapter)장 \(verseNumbers.map { String($0) }.joined(separator: ", "))절"
            }
        } else {
            if verseNumbers.count == 1 {
                return "\(bookName) \(chapter):\(verseNumbers[0])"
            } else if let first = verseNumbers.first, let last = verseNumbers.last,
                      verseNumbers == Array(first...last) {
                return "\(bookName) \(chapter):\(first)-\(last)"
            } else {
                return "\(bookName) \(chapter):\(verseNumbers.map { String($0) }.joined(separator: ", "))"
            }
        }
    }
    
    // Check if selected verses are continuous
    private var isContinuous: Bool {
        let numbers = verses.map { $0.verseNumber }.sorted()
        guard let first = numbers.first, let last = numbers.last else { return true }
        return numbers == Array(first...last)
    }
    
    // Combined verse text (no verse numbers, continuous flow)
    private var combinedVerseText: String {
        verses
            .sorted { $0.verseNumber < $1.verseNumber }
            .map { $0.text(for: language) }
            .joined(separator: " ")
    }
    
    // Sorted verses for non-continuous display
    private var sortedVerses: [BibleVerse] {
        verses.sorted { $0.verseNumber < $1.verseNumber }
    }
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with close and save buttons
                topBar
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Verse display
                        verseCard
                        
                        // Note input section
                        noteSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            // Close button
            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.glassCircle)
            
            Spacer()
            
            // Save button
            Button {
                let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                onSave(trimmedNote.isEmpty ? nil : trimmedNote)
            } label: {
                Text(language == .kr ? "저장" : "Save")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.glass)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Verse Card
    private var verseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Reference (range format)
            Text(verseRangeText)
                .font(theme.verseNumber(12, language: language))
                .foregroundStyle(theme.textSecondary.opacity(0.6))
            
            // Verse content - continuous vs non-continuous display
            if isContinuous {
                // Combined verse text - scroll mode style without verse numbers
                Text(combinedVerseText)
                    .font(theme.verseText(verseFontSize, language: language))
                    .foregroundStyle(theme.textPrimary)
                    .lineSpacing(verseLineSpacing)
            } else {
                // Non-continuous: show each verse with number on right (scroll mode layout)
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(sortedVerses, id: \.verseNumber) { verse in
                        HStack(alignment: .top, spacing: 4) {
                            Text(verse.text(for: language))
                                .font(theme.verseText(verseFontSize, language: language))
                                .foregroundStyle(theme.textPrimary)
                                .lineSpacing(verseLineSpacing)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("\(verse.verseNumber)")
                                .font(theme.verseNumber(12, language: language))
                                .foregroundStyle(theme.textSecondary.opacity(0.6))
                                .frame(width: 18, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.background)
        )
    }
    
    // MARK: - Note Section
    private var noteSection: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $noteText)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.9))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 150)
                .focused($isTextEditorFocused)
            
            // Placeholder text when empty
            if noteText.isEmpty && !isTextEditorFocused {
                Text(language == .kr 
                     ? "이 구절에 대한 생각이나 묵상을 기록하세요..."
                     : "Write your thoughts or reflections on this verse...")
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Preview

#Preview("Single Verse") {
    MultiSelectSaveOverlay(
        verses: [
            BibleVerse(
                bookName: "Genesis",
                chapter: 1,
                verseNumber: 1,
                textEn: "In the beginning God created the heaven and the earth.",
                textKr: "태초에 하나님이 천지를 창조하시니라"
            )
        ],
        book: BibleData.books[0],
        chapter: 1,
        language: .kr,
        onSave: { _ in },
        onCancel: {}
    )
}

#Preview("Multiple Verses") {
    MultiSelectSaveOverlay(
        verses: [
            BibleVerse(
                bookName: "Genesis",
                chapter: 1,
                verseNumber: 1,
                textEn: "In the beginning God created the heaven and the earth.",
                textKr: "태초에 하나님이 천지를 창조하시니라"
            ),
            BibleVerse(
                bookName: "Genesis",
                chapter: 1,
                verseNumber: 2,
                textEn: "And the earth was without form, and void; and darkness was upon the face of the deep.",
                textKr: "땅이 혼돈하고 공허하며 흑암이 깊음 위에 있고 하나님의 영은 수면 위에 운행하시니라"
            ),
            BibleVerse(
                bookName: "Genesis",
                chapter: 1,
                verseNumber: 3,
                textEn: "And God said, Let there be light: and there was light.",
                textKr: "하나님이 이르시되 빛이 있으라 하시니 빛이 있었고"
            )
        ],
        book: BibleData.books[0],
        chapter: 1,
        language: .kr,
        onSave: { _ in },
        onCancel: {}
    )
}

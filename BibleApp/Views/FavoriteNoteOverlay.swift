//
//  FavoriteNoteOverlay.swift
//  BibleApp
//
//  Full-screen overlay for adding/editing notes on favorite verses
//

import SwiftUI

struct FavoriteNoteOverlay: View {
    let verse: BibleVerse
    let book: BibleBook
    let language: LanguageMode
    let existingFavorite: FavoriteVerse?
    let onSave: (String?) -> Void
    let onCancel: () -> Void
    
    @State private var noteText: String = ""
    @FocusState private var isTextEditorFocused: Bool
    
    private var theme: BookTheme {
        BookThemes.theme(for: book.id)
    }
    
    // Dynamic font sizing based on character count (same as tap mode)
    private var fontSize: CGFloat {
        let text = verse.text(for: language)
        let count = text.count
        
        if language == .kr {
            if count > 300 { return 17 }
            if count > 225 { return 18 }
            if count > 160 { return 20 }
            if count > 35  { return 24 }
            return 30
        } else {
            if count > 600 { return 17 }
            if count > 450 { return 18 }
            if count > 320 { return 20 }
            if count > 200 { return 24 }
            if count > 70  { return 28 }
            return 32
        }
    }
    
    private var lineSpacing: CGFloat {
        let text = verse.text(for: language)
        let count = text.count
        
        if language == .kr {
            if count > 225 { return 6 }
            if count > 160 { return 8 }
            if count > 35  { return 12 }
            return 14
        } else {
            if count > 450 { return 5 }
            if count > 320 { return 6 }
            if count > 200 { return 7 }
            if count > 70  { return 9 }
            return 11
        }
    }
    
    var body: some View {
        ZStack {
            // Black background for system view
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
        .onAppear {
            noteText = existingFavorite?.note ?? ""
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
            // Reference
            Text(referenceText)
                .font(theme.verseNumber(12, language: language))
                .foregroundStyle(theme.textSecondary.opacity(0.6))
            
            // Verse text - dynamic font size based on length
            Text(verse.text(for: language))
                .font(theme.verseText(fontSize, language: language))
                .foregroundStyle(theme.textPrimary)
                .lineSpacing(lineSpacing)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.background)
        )
    }
    
    private var referenceText: String {
        let bookName = book.name(for: language)
        switch language {
        case .kr:
            return "\(bookName) \(verse.chapter)장 \(verse.verseNumber)절"
        case .en:
            return "\(bookName) \(verse.chapter):\(verse.verseNumber)"
        }
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
#Preview("New Favorite") {
    FavoriteNoteOverlay(
        verse: BibleVerse(
            bookName: "John",
            chapter: 3,
            verseNumber: 16,
            textEn: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
            textKr: "하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니 이는 그를 믿는 자마다 멸망하지 않고 영생을 얻게 하려 하심이라"
        ),
        book: BibleData.books[42],
        language: .kr,
        existingFavorite: nil,
        onSave: { _ in },
        onCancel: {}
    )
}

#Preview("Edit Mode") {
    let book = BibleData.books[42]
    let verse = BibleVerse(
        bookName: "John",
        chapter: 3,
        verseNumber: 16,
        textEn: "For God so loved the world...",
        textKr: "하나님이 세상을 이처럼 사랑하사..."
    )
    let favorite = FavoriteVerse(from: verse, book: book, note: "This is my favorite verse!")
    
    FavoriteNoteOverlay(
        verse: verse,
        book: book,
        language: .en,
        existingFavorite: favorite,
        onSave: { _ in },
        onCancel: {}
    )
}

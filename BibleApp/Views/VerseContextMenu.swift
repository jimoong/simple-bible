//
//  VerseContextMenu.swift
//  BibleApp
//
//  Contextual action menu that appears on long press of a verse
//

import SwiftUI

// MARK: - Verse Selection Overlay
/// Full-screen overlay that handles verse selection and context menu display
struct VerseSelectionOverlay: View {
    let verse: BibleVerse
    let book: BibleBook
    let theme: BookTheme
    let language: LanguageMode
    let anchorPosition: CGPoint
    let onSave: () -> Void
    let onNavigateToSaved: () -> Void  // Navigate to favorites list when already saved
    let onCopy: () -> Void
    let onAsk: () -> Void
    let onDismiss: () -> Void
    
    @State private var isAppearing = false
    @State private var isFavorite: Bool = false
    
    // Dynamic font sizing - same as VerseCardView (tap mode)
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
        GeometryReader { geometry in
            let cardHeight = geometry.size.height * 0.5
            
            ZStack {
                // Semi-transparent background - tap to dismiss
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissWithAnimation()
                    }
                
                // iOS native context menu style layout - centered
                VStack(spacing: 8) {
                    // Verse preview card - fixed 50% height
                    verseCard(height: cardHeight)
                    
                    // Native iOS context menu action group
                    actionMenuGroup
                }
                .padding(.horizontal, 16)
                .scaleEffect(isAppearing ? 1 : 0.95)
                .opacity(isAppearing ? 1 : 0)
            }
        }
        .onAppear {
            isFavorite = FavoriteService.shared.isFavorite(verse: verse, book: book)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isAppearing = true
            }
        }
    }
    
    // MARK: - Verse Card  
    private func verseCard(height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Reference - same style as verse number in tap mode (13pt)
            Text(referenceText)
                .font(theme.verseNumber(13, language: language))
                .foregroundStyle(theme.textSecondary.opacity(0.5))
            
            // Verse text - dynamic font size same as tap mode
            Text(verse.text(for: language))
                .font(theme.verseText(fontSize, language: language))
                .foregroundStyle(theme.textPrimary)
                .lineSpacing(lineSpacing)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.background)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .frame(height: height)
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
    
    // MARK: - Native iOS Context Menu Action Group
    private var actionMenuGroup: some View {
        VStack(spacing: 0) {
            // Save/Like action - different behavior based on saved state
            Button {
                if isFavorite {
                    onNavigateToSaved()  // Navigate to favorites list
                } else {
                    onSave()  // Open note overlay to save
                }
            } label: {
                HStack {
                    Text(isFavorite 
                         ? (language == .kr ? "저장됨" : "Saved")
                         : (language == .kr ? "저장" : "Save"))
                    Spacer()
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                }
                .font(.system(size: 17))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Divider()
            
            // Copy action
            Button {
                onCopy()
            } label: {
                HStack {
                    Text(language == .kr ? "복사" : "Copy")
                    Spacer()
                    Image(systemName: "doc.on.doc")
                }
                .font(.system(size: 17))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            Divider()
            
            // Ask action
            Button {
                onAsk()
            } label: {
                HStack {
                    Text(language == .kr ? "물어보기" : "Ask")
                    Spacer()
                    Image(systemName: "sparkle")
                }
                .font(.system(size: 17))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(width: 200)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.2)) {
            isAppearing = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    VerseSelectionOverlay(
        verse: BibleVerse(
            bookName: "John",
            chapter: 3,
            verseNumber: 16,
            textEn: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
            textKr: "하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니 이는 그를 믿는 자마다 멸망하지 않고 영생을 얻게 하려 하심이라"
        ),
        book: BibleData.books[42],
        theme: BookThemes.john,
        language: .kr,
        anchorPosition: CGPoint(x: 200, y: 400),
        onSave: {},
        onNavigateToSaved: {},
        onCopy: {},
        onAsk: {},
        onDismiss: {}
    )
}

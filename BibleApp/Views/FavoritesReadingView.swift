//
//  FavoritesReadingView.swift
//  BibleApp
//
//  Reading view for favorite (liked) verses collection
//

import SwiftUI

struct FavoritesReadingView: View {
    let language: LanguageMode
    var safeAreaTop: CGFloat = 0
    var safeAreaBottom: CGFloat = 0
    let onClose: () -> Void
    var onBack: (() -> Void)? = nil
    let onNavigateToVerse: (FavoriteVerse) -> Void
    let onEditFavorite: (FavoriteVerse) -> Void
    
    @State private var favorites: [FavoriteVerse] = []
    @State private var glowAnimating = false
    
    var body: some View {
        ZStack {
            // Black background (app system view)
            Color.black
            
            if favorites.isEmpty {
                emptyView
            } else {
                // Main content - favorites scroll view
                favoritesScrollView
            }
        }
        .onAppear {
            loadFavorites()
        }
    }
    
    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white.opacity(0.3))
            
            Text(language == .kr 
                 ? "아직 좋아요한 구절이 없습니다"
                 : "No favorite verses yet")
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Text(language == .kr
                 ? "구절을 길게 눌러 좋아요를 추가하세요"
                 : "Long press on a verse to add it to favorites")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Title Section (like bookshelf/timeline)
    private var titleSection: some View {
        ZStack {
            // Heart icon with glow
            Image(systemName: "heart.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 48, height: 48)
        .background(
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(glowAnimating ? 0.25 : 0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 30
                    )
                )
                .blur(radius: 8)
                .scaleEffect(glowAnimating ? 1.15 : 1.0)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowAnimating = true
            }
        }
    }
    
    // MARK: - Favorites Scroll View
    private var favoritesScrollView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 24) {
                // Title (same position as bookshelf)
                titleSection
                    .padding(.top, safeAreaTop + 16)
                
                // Favorites list
                LazyVStack(spacing: 10) {
                    ForEach(favorites) { favorite in
                        FavoriteVerseRow(
                            favorite: favorite,
                            language: language,
                            onTap: {
                                onNavigateToVerse(favorite)
                            },
                            onCopy: {
                                copyVerse(favorite)
                            },
                            onEdit: {
                                onEditFavorite(favorite)
                            },
                            onDelete: {
                                deleteFavorite(favorite)
                            }
                        )
                    }
                }
            }
            .padding(.bottom, safeAreaBottom + 100)
        }
        .scrollIndicators(.visible)
    }
    
    // MARK: - Helper Methods
    private func loadFavorites() {
        favorites = FavoriteService.shared.getAllFavorites()
    }
    
    private func deleteFavorite(_ favorite: FavoriteVerse) {
        withAnimation(.easeOut(duration: 0.25)) {
            FavoriteService.shared.removeFavorite(id: favorite.id)
            favorites = FavoriteService.shared.getAllFavorites()
        }
    }
    
    private func copyVerse(_ favorite: FavoriteVerse) {
        let text = favorite.text(for: language)
        let reference = favorite.referenceText(for: language)
        UIPasteboard.general.string = "\(text)\n— \(reference)"
        HapticManager.shared.success()
    }
}

// MARK: - Favorite Verse Row
struct FavoriteVerseRow: View {
    let favorite: FavoriteVerse
    let language: LanguageMode
    let onTap: () -> Void
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    // Get the specific book's theme - used for card styling (matches FavoriteNoteOverlay)
    private var bookTheme: BookTheme {
        BookThemes.theme(for: favorite.bookId)
    }
    
    // Dynamic font sizing based on character count (same as tap mode)
    private var fontSize: CGFloat {
        let text = favorite.text(for: language)
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
    
    private var verseLineSpacing: CGFloat {
        let text = favorite.text(for: language)
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
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Reference
                Text(favorite.referenceText(for: language))
                    .font(bookTheme.verseNumber(12, language: language))
                    .foregroundStyle(bookTheme.textSecondary.opacity(0.6))
                
                // Verse text - dynamic font size based on length
                Text(favorite.text(for: language))
                    .font(bookTheme.verseText(fontSize, language: language))
                    .foregroundStyle(bookTheme.textPrimary)
                    .lineSpacing(verseLineSpacing)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Note (if exists) - no icon, just text
                if let note = favorite.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 14))
                        .foregroundStyle(bookTheme.textSecondary.opacity(0.8))
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 16)
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 60)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(bookTheme.background)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onCopy()
            } label: {
                Label(
                    language == .kr ? "복사" : "Copy",
                    systemImage: "doc.on.doc"
                )
            }
            
            Button {
                onEdit()
            } label: {
                Label(
                    language == .kr ? "수정" : "Edit",
                    systemImage: "pencil"
                )
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(
                    language == .kr ? "삭제" : "Delete",
                    systemImage: "trash"
                )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    FavoritesReadingView(
        language: .kr,
        onClose: {},
        onNavigateToVerse: { _ in },
        onEditFavorite: { _ in }
    )
}

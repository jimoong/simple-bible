//
//  ChapterToast.swift
//  BibleApp
//
//  Toast component showing chapter message/summary when opening a chapter
//

import SwiftUI

struct ChapterToast: View {
    let chapterSummary: ChapterSummary
    let languageMode: LanguageMode
    let theme: BookTheme
    var onDismiss: () -> Void
    var onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Chapter title
                Text(chapterSummary.title(for: languageMode))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                
                // Summary (instead of message)
                Text(chapterSummary.summary(for: languageMode))
                    .font(theme.verseText(14, language: languageMode))
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(2)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.surface)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Toast Container with Animation
struct ChapterToastContainer: View {
    @Binding var isVisible: Bool
    let chapterSummary: ChapterSummary?
    let languageMode: LanguageMode
    let theme: BookTheme
    var onTap: () -> Void
    var onDismiss: () -> Void = {}
    
    @State private var opacity: Double = 0
    @State private var offsetY: CGFloat = -20
    @State private var dragOffset: CGFloat = 0
    @State private var dismissTask: Task<Void, Never>?
    
    private let displayDuration: Double = 5.0 // seconds before auto-dismiss
    private let animationDuration: Double = 0.35
    private let swipeThreshold: CGFloat = -30 // swipe up threshold
    
    var body: some View {
        Group {
            if let summary = chapterSummary, isVisible {
                ChapterToast(
                    chapterSummary: summary,
                    languageMode: languageMode,
                    theme: theme,
                    onDismiss: {
                        dismissToast()
                    },
                    onTap: {
                        dismissToast()
                        onTap()
                    }
                )
                .opacity(opacity)
                .offset(y: offsetY + dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow upward drag
                            if value.translation.height < 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height < swipeThreshold {
                                // Swipe up detected - dismiss
                                dismissToast()
                            } else {
                                // Snap back
                                withAnimation(.easeOut(duration: 0.2)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                .onAppear {
                    startDisplayTimer()
                }
                .onDisappear {
                    dismissTask?.cancel()
                }
            }
        }
    }
    
    private func startDisplayTimer() {
        // Cancel any existing timer
        dismissTask?.cancel()
        
        // Reset to initial state
        opacity = 0
        offsetY = -20
        dragOffset = 0
        
        // Slide down + fade in
        withAnimation(.easeOut(duration: animationDuration)) {
            opacity = 1
            offsetY = 0
        }
        
        // Schedule auto-dismiss
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(displayDuration * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                dismissToast()
            }
        }
    }
    
    private func dismissToast() {
        dismissTask?.cancel()
        
        // Slide up + fade out
        withAnimation(.easeOut(duration: animationDuration)) {
            opacity = 0
            offsetY = -20
            dragOffset = 0
        }
        
        // Actually hide after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            isVisible = false
            onDismiss()
        }
    }
}

#Preview {
    let theme = BookThemes.genesis
    let summary = ChapterSummary(
        chapter: 1,
        titleKo: "천지창조",
        titleEn: "The Creation",
        summaryKo: "하나님께서 6일 동안 말씀으로 온 우주 만물과 인간을 창조하신 이야기입니다.",
        summaryEn: "God creates the universe and all living things by His word over six days.",
        messageKo: "하나님은 모든 것의 창조주이시며, 그분의 말씀에는 생명을 창조하는 권능이 있습니다.",
        messageEn: "God is the Creator of all things, and His word has the power to bring life into existence.",
        keyEvents: [],
        timelineYear: nil
    )
    
    ZStack {
        theme.background.ignoresSafeArea()
        
        VStack {
            ChapterToast(
                chapterSummary: summary,
                languageMode: .en,
                theme: theme,
                onDismiss: {},
                onTap: {}
            )
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .padding(.top, 100)
    }
}

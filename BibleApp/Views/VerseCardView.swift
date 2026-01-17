import SwiftUI

struct VerseCardView: View {
    let verse: BibleVerse
    let language: LanguageMode
    let theme: BookTheme
    let isCentered: Bool
    var isMultiSelectMode: Bool = false
    var isSelected: Bool = false
    var onSave: (() -> Void)? = nil
    var onCopy: (() -> Void)? = nil
    var onAsk: (() -> Void)? = nil
    var onListen: (() -> Void)? = nil
    
    // Dynamic font sizing based on character count
    // Progressively smaller fonts for longer verses
    // Korean uses half the character breakpoints of English
    private var fontSize: CGFloat {
        let text = verse.text(for: language)
        let count = text.count
        
        if language == .kr {
            if count > 300 { return 17 }      // Very long (EN: 600)
            if count > 225 { return 18 }      // Long (EN: 450)
            if count > 160 { return 20 }      // Medium-long (EN: 320)
            if count > 35  { return 24 }      // Normal (EN: 70)
            return 30                          // Short
        } else {
            if count > 600 { return 17 }      // Very long
            if count > 450 { return 18 }      // Long
            if count > 320 { return 20 }      // Medium-long
            if count > 200 { return 24 }      // Medium
            if count > 70  { return 28 }      // Normal
            return 32                          // Short
        }
    }
    
    private var lineSpacing: CGFloat {
        let text = verse.text(for: language)
        let count = text.count
        
        if language == .kr {
            if count > 225 { return 6 }       // (EN: 450)
            if count > 160 { return 8 }       // (EN: 320)
            if count > 35  { return 12 }      // (EN: 70)
            return 14                          // Short verses get more breathing room
        } else {
            if count > 450 { return 5 }
            if count > 320 { return 6 }
            if count > 200 { return 7 }       // Medium
            if count > 70  { return 9 }       // Normal
            return 11                          // Short verses get more breathing room
        }
    }
    
    // Height of verse number + spacing (used for optical centering)
    private let verseNumberHeight: CGFloat = 13 + 10  // font size + spacing
    
    @State private var isFavorite: Bool = false
    @State private var highlightedCharCount: Int = 0
    @State private var highlightTimer: Timer?
    
    // Highlighted text for saved verses - progressively highlights characters
    private var highlightedText: AttributedString {
        let verseString = verse.text(for: language)
        var text = AttributedString(verseString)
        
        if isFavorite && highlightedCharCount > 0 {
            let endIndex = min(highlightedCharCount, verseString.count)
            if endIndex > 0 {
                let startIdx = text.startIndex
                let endIdx = text.index(startIdx, offsetByCharacters: endIndex)
                text[startIdx..<endIdx].backgroundColor = Color(theme.highlightAccent.opacity(0.25))
            }
        }
        return text
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Verse number
            Text("\(verse.verseNumber)")
                .font(theme.verseNumber(13, language: language))
                .foregroundStyle(theme.textSecondary.opacity(0.5))
            
            // Verse text - dynamic font size, no clipping
            Text(highlightedText)
                .font(theme.verseText(fontSize, language: language))
                .foregroundStyle(theme.textPrimary)
                .lineSpacing(lineSpacing)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear {
            let wasFavorite = FavoriteService.shared.isFavorite(
                bookName: verse.bookName,
                chapter: verse.chapter,
                verseNumber: verse.verseNumber
            )
            isFavorite = wasFavorite
            if wasFavorite {
                highlightedCharCount = verse.text(for: language).count
            }
        }
        .onChange(of: isFavorite) { oldValue, newValue in
            if !newValue && oldValue {
                // Removed from favorites
                highlightTimer?.invalidate()
                highlightedCharCount = 0
            }
        }
        .onDisappear {
            highlightTimer?.invalidate()
        }
        .onReceive(NotificationCenter.default.publisher(for: .verseFavoriteSaved)) { notification in
            // Check if this notification is for this verse
            guard let userInfo = notification.userInfo,
                  let bookName = userInfo["bookName"] as? String,
                  let chapter = userInfo["chapter"] as? Int,
                  let verseNumber = userInfo["verseNumber"] as? Int,
                  bookName == verse.bookName,
                  chapter == verse.chapter,
                  verseNumber == verse.verseNumber else { return }
            
            // Update favorite state and animate after delay
            isFavorite = true
            animateHighlight()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.bottom, verseNumberHeight)  // Compensate for verse number to optically center text
        .padding(.vertical, isMultiSelectMode ? 16 : 0)
        .padding(.horizontal, isMultiSelectMode ? -12 : 0)  // Expand for border/fill
        .background(
            Group {
                if isMultiSelectMode {
                    if isSelected {
                        // Selected: filled background, no border
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.textPrimary.opacity(0.08))
                    } else {
                        // Unselected: border only
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(theme.textSecondary.opacity(0.2), lineWidth: 1)
                    }
                }
            }
        )
        .padding(.horizontal, isMultiSelectMode ? 12 : 0)  // Restore padding after background
        .animation(.easeOut(duration: 0.15), value: isSelected)
        .contentShape(Rectangle())
        .contextMenu(isCentered && !isMultiSelectMode ? ContextMenu {
            Button {
                onSave?()
                // State change handled by notification after actual save
            } label: {
                Label(
                    isFavorite 
                        ? (language == .kr ? "저장됨" : "Saved")
                        : (language == .kr ? "저장" : "Save"),
                    systemImage: isFavorite ? "heart.fill" : "heart"
                )
            }
            
            Button {
                onCopy?()
            } label: {
                Label(
                    language == .kr ? "복사" : "Copy",
                    systemImage: "doc.on.doc"
                )
            }
            
            Button {
                onListen?()
            } label: {
                Label(
                    language == .kr ? "여기서부터 듣기" : "Listen from here",
                    systemImage: "play.fill"
                )
            }
            
            Button {
                onAsk?()
            } label: {
                Label(
                    language == .kr ? "물어보기" : "Ask",
                    systemImage: "sparkle"
                )
            }
        } : nil)
    }
    
    // Animate highlight like drawing with a highlighter pen
    private func animateHighlight() {
        let totalChars = verse.text(for: language).count
        highlightedCharCount = 0
        
        // Wait for overlay to close, then animate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let duration: Double = 0.6  // Slower animation for visibility
            let charsPerTick = max(1, totalChars / 20)
            let interval = duration / Double(max(1, totalChars / charsPerTick))
            
            highlightTimer?.invalidate()
            highlightTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
                if highlightedCharCount < totalChars {
                    highlightedCharCount = min(highlightedCharCount + charsPerTick, totalChars)
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}

// MARK: - Slot Machine Effect Modifier
struct SlotMachineEffect: ViewModifier {
    var isScrubbing: Bool = false
    
    func body(content: Content) -> some View {
        content
            .scrollTransition(isScrubbing ? .interactive : .animated(.easeOut(duration: 0.2))) { content, phase in
                content
                    .opacity(phase.isIdentity ? 1.0 : 0.2)
                    .scaleEffect(phase.isIdentity ? 1.0 : 0.88)
                    .blur(radius: phase.isIdentity ? 0 : 3)
            }
    }
}

extension View {
    func slotMachineEffect(isScrubbing: Bool = false) -> some View {
        modifier(SlotMachineEffect(isScrubbing: isScrubbing))
    }
}

#Preview("English - Serif") {
    let theme = BookThemes.john // Serif theme
    
    ZStack {
        theme.background.ignoresSafeArea()
        
        VerseCardView(
            verse: BibleVerse(
                bookName: "John",
                chapter: 3,
                verseNumber: 16,
                textEn: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
                textKr: "하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니 이는 그를 믿는 자마다 멸망하지 않고 영생을 얻게 하려 하심이라"
            ),
            language: .en,
            theme: theme,
            isCentered: true
        )
    }
}

#Preview("Korean - Serif") {
    let theme = BookThemes.john // Serif theme
    
    ZStack {
        theme.background.ignoresSafeArea()
        
        VerseCardView(
            verse: BibleVerse(
                bookName: "John",
                chapter: 3,
                verseNumber: 16,
                textEn: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.",
                textKr: "하나님이 세상을 이처럼 사랑하사 독생자를 주셨으니 이는 그를 믿는 자마다 멸망하지 않고 영생을 얻게 하려 하심이라"
            ),
            language: .kr,
            theme: theme,
            isCentered: true
        )
    }
}

#Preview("Korean - Sans") {
    let theme = BookThemes.mark // Sans-serif theme
    
    ZStack {
        theme.background.ignoresSafeArea()
        
        VerseCardView(
            verse: BibleVerse(
                bookName: "Mark",
                chapter: 1,
                verseNumber: 1,
                textEn: "The beginning of the gospel of Jesus Christ, the Son of God.",
                textKr: "하나님의 아들 예수 그리스도의 복음의 시작이라"
            ),
            language: .kr,
            theme: theme,
            isCentered: true
        )
    }
}

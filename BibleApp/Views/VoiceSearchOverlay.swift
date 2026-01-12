import SwiftUI

struct VoiceSearchOverlay: View {
    @Bindable var viewModel: VoiceSearchViewModel
    let theme: BookTheme
    let languageMode: LanguageMode
    
    // MARK: - Sans-Serif Font Helper
    
    private func sansFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if languageMode == .kr {
            return FontManager.korean(size: size, weight: weight, design: .default)
        } else {
            return .system(size: size, weight: weight, design: .default)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            header
            
            // Main content
            mainContent
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .background(Color.black)
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Spacer()
            
            // Close button
            Button {
                viewModel.close()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black)
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 24) {
            switch viewModel.state {
            case .idle:
                idleContent
                
            case .listening:
                listeningContent
                
            case .navigating:
                navigatingContent
                
            case .error(let message):
                errorContent(message)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeOut(duration: 0.2), value: viewModel.state)
    }
    
    // MARK: - Idle Content
    
    private var idleContent: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Button {
                viewModel.startListening()
            } label: {
                VStack(spacing: 16) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Text(languageMode == .kr ? "탭하여 시작" : "Tap to start")
                        .font(sansFont(14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(width: 120, height: 120)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
    
    // MARK: - Listening Content
    
    private var listeningContent: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Circular audio visualizer
            audioVisualizer
            
            // Live transcript - replaced with validated text when available
            Text(displayText)
                .font(sansFont(32))
                .foregroundStyle(viewModel.transcript.isEmpty ? .clear : .white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal)
                .frame(minHeight: 120)
                .animation(.easeOut(duration: 0.15), value: displayText)
            
            Spacer()
            
            // Open button
            Button {
                viewModel.tryNavigate()
            } label: {
                Text(languageMode == .kr ? "열기" : "Open")
                    .font(sansFont(16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(.regularMaterial)
                            .environment(\.colorScheme, .dark)
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Display Text (validated or raw)
    
    private var displayText: String {
        guard !viewModel.transcript.isEmpty else { return " " }
        
        // If we have a valid parsed result, show the validated version
        if let parsed = viewModel.liveParseResult, let book = parsed.book {
            return formatParsedReference(book: book, chapter: parsed.chapter, verse: parsed.verse)
        }
        
        // Otherwise show raw transcript
        return viewModel.transcript
    }
    
    private func formatParsedReference(book: BibleBook, chapter: Int?, verse: Int?) -> String {
        let bookName = book.name(for: languageMode)
        
        // Only show what was actually spoken
        if let chapter = chapter {
            if let verse = verse {
                // Book + Chapter + Verse
                if languageMode == .kr {
                    return "\(bookName) \(chapter)장 \(verse)절"
                } else {
                    return "\(bookName) \(chapter):\(verse)"
                }
            } else {
                // Book + Chapter only
                if languageMode == .kr {
                    return "\(bookName) \(chapter)장"
                } else {
                    return "\(bookName) \(chapter)"
                }
            }
        } else {
            // Book only
            return bookName
        }
    }
    
    // MARK: - Audio Visualizer (Circular)
    
    private var audioVisualizer: some View {
        let level = CGFloat(viewModel.audioLevel)
        let hasText = !viewModel.transcript.isEmpty
        let baseSize: CGFloat = hasText ? 16 : 60  // 20% when text detected
        let maxExpansion: CGFloat = hasText ? 16 : 80  // x2 exaggerated motion
        let size = baseSize + level * maxExpansion
        
        return Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .frame(width: 100, height: 100)  // Fixed boundary
            .animation(.easeOut(duration: 0.1), value: level)
            .animation(.easeOut(duration: 0.3), value: hasText)
    }
    
    // MARK: - Navigating Content
    
    private var navigatingContent: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text(languageMode == .kr ? "이동 중..." : "Navigating...")
                .font(sansFont(14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            
            Spacer()
        }
    }
    
    // MARK: - Error Content
    
    private func errorContent(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text(message)
                .font(sansFont(14))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Button {
                viewModel.retryListening()
            } label: {
                Text(languageMode == .kr ? "다시 시도" : "Try Again")
                    .font(sansFont(16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            VoiceSearchOverlay(
                viewModel: VoiceSearchViewModel(),
                theme: BookThemes.john,
                languageMode: .kr
            )
            .frame(height: 400)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

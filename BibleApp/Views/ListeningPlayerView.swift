import SwiftUI
import AVFoundation

/// Bottom player panel for listening mode
struct ListeningPlayerView: View {
    @Bindable var viewModel: ListeningViewModel
    let theme: BookTheme
    let safeAreaBottom: CGFloat
    let languageMode: LanguageMode
    
    // Action callbacks
    var onBookshelf: () -> Void = {}
    var onSearch: () -> Void = {}
    var onChat: () -> Void = {}
    var onExit: () -> Void = {}
    
    // Volume control
    @State private var volume: Float = TTSService.shared.volume
    
    private let buttonSize: CGFloat = 48
    
    var body: some View {
        VStack(spacing: 30) {
            // Segmented progress bar
            segmentedProgressBar
                .padding(.top, 30)
                .padding(.horizontal, 10)  // Additional 10 (total 30 with parent's 20)
            
            // Playback controls - simple SF Symbols
            playbackControls
            
            // Volume control
            volumeControl
                .padding(.horizontal, 10)  // Match progress bar horizontal padding
            
            // Bottom: Action buttons (left) + Close button (right)
            bottomActionButtons
        }
        .padding(.horizontal, 28)
        .padding(.bottom, safeAreaBottom - 4)
        .background(playerBackground)
    }
    
    // MARK: - Player Background
    
    private var playerBackground: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 24,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: 24,
            style: .continuous
        )
        .fill(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 24,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
        )
    }
    
    // MARK: - Segmented Progress Bar
    
    private var segmentedProgressBar: some View {
        let segments = viewModel.verseProgressSegments
        let totalSegments = segments.count
        // Remove spacing if there are many verses to prevent overflow
        let segmentSpacing: CGFloat = totalSegments > 30 ? 0 : 2
        
        return GeometryReader { geometry in
            let totalWidth = geometry.size.width
            
            HStack(spacing: segmentSpacing) {
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    let isFirst = index == 0
                    let isLast = index == totalSegments - 1
                    segmentView(
                        segment: segment,
                        totalWidth: totalWidth,
                        totalSegments: totalSegments,
                        segmentSpacing: segmentSpacing,
                        isFirst: isFirst,
                        isLast: isLast
                    )
                }
            }
        }
        .frame(height: 6)  // 1.5x thicker (was 4)
    }
    
    private func segmentView(segment: VerseProgressSegment, totalWidth: CGFloat, totalSegments: Int, segmentSpacing: CGFloat, isFirst: Bool, isLast: Bool) -> some View {
        // Calculate available width after accounting for all spacing
        let totalSpacing = segmentSpacing * CGFloat(totalSegments - 1)
        let availableWidth = totalWidth - totalSpacing
        let segmentWidth = segment.width * availableWidth
        let cornerRadius: CGFloat = segmentSpacing > 0 ? 3 : 0
        
        // Only round corners on outer edges (and only if spacing exists)
        let corners: UIRectCorner = {
            if segmentSpacing == 0 {
                if isFirst && isLast {
                    return .allCorners
                } else if isFirst {
                    return [.topLeft, .bottomLeft]
                } else if isLast {
                    return [.topRight, .bottomRight]
                } else {
                    return []
                }
            }
            if isFirst && isLast {
                return .allCorners
            } else if isFirst {
                return [.topLeft, .bottomLeft]
            } else if isLast {
                return [.topRight, .bottomRight]
            } else {
                return []
            }
        }()
        
        return ZStack(alignment: .leading) {
            // Background
            RoundedCornersShape(corners: corners, radius: cornerRadius)
                .fill(Color.white.opacity(0.15))
            
            // Fill based on state
            if segment.state == .completed {
                RoundedCornersShape(corners: corners, radius: cornerRadius)
                    .fill(Color.white.opacity(0.8))
            } else if segment.state == .playing {
                GeometryReader { geo in
                    let fillProgress = calculateSegmentFill(segment: segment)
                    // For playing segment, only round left corners if first
                    let fillCorners: UIRectCorner = isFirst ? [.topLeft, .bottomLeft] : []
                    RoundedCornersShape(corners: fillCorners, radius: cornerRadius)
                        .fill(Color.white.opacity(0.8))
                        .frame(width: geo.size.width * fillProgress)
                }
            }
        }
        .frame(width: max(2, segmentWidth))
    }
    
    private func calculateSegmentFill(segment: VerseProgressSegment) -> Double {
        let progress = viewModel.playbackProgress
        guard segment.state == .playing else { return 0 }
        
        let segmentProgress = (progress - segment.startProgress) / segment.width
        return min(1, max(0, segmentProgress))
    }
    
    // MARK: - Playback Controls (Simple SF Symbols)
    
    private var playbackControls: some View {
        HStack(spacing: 32) {
            // Previous verse
            Button {
                viewModel.previousVerse()
                HapticManager.shared.selection()
            } label: {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(viewModel.currentVerseIndex > 0 && !viewModel.isLoading ? 0.9 : 0.3))
            }
            .disabled(viewModel.currentVerseIndex == 0 || viewModel.isLoading)
            
            // Play/Pause/Loading
            Button {
                viewModel.togglePlayPause()
                HapticManager.shared.selection()
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .disabled(viewModel.isLoading)
            
            // Next verse
            Button {
                viewModel.nextVerse()
                HapticManager.shared.selection()
            } label: {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(viewModel.currentVerseIndex < viewModel.totalVerses - 1 && !viewModel.isLoading ? 0.9 : 0.3))
            }
            .disabled(viewModel.currentVerseIndex >= viewModel.totalVerses - 1 || viewModel.isLoading)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Volume Control
    
    private var volumeControl: some View {
        HStack(spacing: 8) {
            // Low volume icon
            Image(systemName: "speaker.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            
            // Volume slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                    
                    // Fill track
                    Capsule()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: geometry.size.width * CGFloat(volume))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newVolume = Float(value.location.x / geometry.size.width)
                            volume = min(1, max(0, newVolume))
                            TTSService.shared.volume = volume
                        }
                )
            }
            .frame(height: 6)  // Same height as progress bar
            
            // High volume icon
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
    
    // MARK: - Bottom Action Buttons (Same as Reading Mode)
    
    private var bottomActionButtons: some View {
        HStack(alignment: .bottom) {
            // Left buttons - same as reading mode
            HStack(spacing: 10) {
                // Bookshelf button
                fabButton(icon: "book.closed") {
                    viewModel.pauseForNavigation()
                    onBookshelf()
                }
                
                // Search button
                fabButton(icon: "magnifyingglass") {
                    viewModel.pauseForNavigation()
                    onSearch()
                }
                
                // Chat button
                fabButton(icon: "sparkle") {
                    viewModel.pauseForNavigation()
                    onChat()
                }
            }
            
            Spacer()
            
            // Close button - same position and style as ExpandableFAB
            fabButton(icon: "xmark") {
                onExit()
            }
        }
    }
    
    // FAB button - integrated into panel (no shadow, no border, ultrathin only)
    private func fabButton(icon: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            HapticManager.shared.selection()
        } label: {
            ZStack {
                // Ultrathin material only - part of the panel
                Circle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: buttonSize, height: buttonSize)
        }
        .buttonStyle(BookshelfButtonStyle())
    }
    
}

// MARK: - Rounded Corners Shape (selective corners)

struct RoundedCornersShape: Shape {
    let corners: UIRectCorner
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            ListeningPlayerView(
                viewModel: ListeningViewModel(),
                theme: BookThemes.genesis,
                safeAreaBottom: 34,
                languageMode: .kr
            )
        }
    }
}

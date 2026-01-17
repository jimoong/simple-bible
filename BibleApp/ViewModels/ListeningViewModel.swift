import SwiftUI
import Combine

/// ViewModel for managing listening mode state
@Observable
class ListeningViewModel {
    // MARK: - State
    var isActive: Bool = false
    var currentVerseIndex: Int = 0
    var highlightedRange: NSRange?
    var showCompletionButtons: Bool = false
    var shouldAutoScroll: Bool = false
    
    // Track read progress per verse to prevent flashing
    var verseReadPositions: [Int: Int] = [:]  // verseIndex -> maxReadPosition
    
    // Unique ID that changes when chapter changes - forces view refresh
    var sessionId: UUID = UUID()
    
    // Playback start coordination (wait for view to appear)
    private var isViewReady: Bool = false
    private var pendingStartIndex: Int?
    
    // References to content
    var verses: [BibleVerse] = []
    var languageMode: LanguageMode = .kr
    
    // Service reference
    private let ttsService = TTSService.shared
    
    
    // MARK: - Computed Properties
    
    var isPlaying: Bool {
        ttsService.isPlaying
    }
    
    var isPaused: Bool {
        ttsService.isPaused
    }
    
    var isLoading: Bool {
        ttsService.isLoading
    }
    
    var playbackProgress: Double {
        ttsService.playbackProgress
    }
    
    var totalVerses: Int {
        verses.count
    }
    
    var currentVerseNumber: Int {
        guard currentVerseIndex < verses.count else { return 1 }
        return verses[currentVerseIndex].verseNumber
    }
    
    var verseTexts: [String] {
        verses.map { $0.text(for: languageMode) }
    }
    
    // Progress segments for segmented progress bar
    var verseProgressSegments: [VerseProgressSegment] {
        guard !verses.isEmpty else { return [] }
        
        let totalChars = verseTexts.reduce(0) { $0 + $1.count }
        guard totalChars > 0 else { return [] }
        
        var segments: [VerseProgressSegment] = []
        var accumulatedChars = 0
        
        for (index, text) in verseTexts.enumerated() {
            let start = Double(accumulatedChars) / Double(totalChars)
            accumulatedChars += text.count
            let end = Double(accumulatedChars) / Double(totalChars)
            
            let state: VerseProgressState
            // Check if verse is fully read according to verseReadPositions
            let verseLength = text.count
            let readPosition = verseReadPositions[index] ?? 0
            let isFullyRead = readPosition >= verseLength
            
            // If playback finished, all verses are completed
            if showCompletionButtons {
                state = .completed
            } else if isFullyRead {
                // Verse is marked as fully read (e.g., skipped via forward button)
                state = .completed
            } else if index < currentVerseIndex {
                state = .completed
            } else if index == currentVerseIndex {
                state = isPlaying || isPaused ? .playing : .pending
            } else {
                state = .pending
            }
            
            segments.append(VerseProgressSegment(
                verseIndex: index,
                startProgress: start,
                endProgress: end,
                state: state
            ))
        }
        
        return segments
    }
    
    // MARK: - Initialization
    
    init() {
        setupCallbacks()
    }
    
    private func setupCallbacks() {
        // Capture self strongly to avoid weak reference issues during callbacks
        let viewModel = self
        ttsService.onUtteranceStart = { index in
            Task { @MainActor in
                viewModel.currentVerseIndex = index
                viewModel.showCompletionButtons = false
                viewModel.highlightedRange = nil
                // Start auto-scroll after first verse starts
                if index > 0 {
                    viewModel.shouldAutoScroll = true
                }
            }
        }
        
        ttsService.onWordSpoken = { index, range in
            Task { @MainActor in
                viewModel.highlightedRange = range
                
                // Track max read position for this verse
                // Create new dictionary to ensure @Observable triggers update
                let newPosition = range.location + range.length
                let currentMax = viewModel.verseReadPositions[index] ?? 0
                if newPosition > currentMax {
                    var updatedPositions = viewModel.verseReadPositions
                    updatedPositions[index] = newPosition
                    viewModel.verseReadPositions = updatedPositions
                }
            }
        }
        
        ttsService.onUtteranceFinish = { index in
            Task { @MainActor in
                // Mark verse as fully read
                if index < viewModel.verses.count {
                    let verseLength = viewModel.verses[index].text(for: viewModel.languageMode).count
                    var updatedPositions = viewModel.verseReadPositions
                    updatedPositions[index] = verseLength
                    viewModel.verseReadPositions = updatedPositions
                }
            }
        }
        
        ttsService.onAllFinished = {
            Task { @MainActor in
                viewModel.showCompletionButtons = true
                viewModel.highlightedRange = nil
            }
        }
    }
    
    // MARK: - Actions
    
    /// Enter listening mode with verses
    func start(verses: [BibleVerse], language: LanguageMode) {
        startFrom(verses: verses, language: language, verseIndex: 0)
    }
    
    /// Enter listening mode starting from a specific verse
    func startFrom(verses: [BibleVerse], language: LanguageMode, verseIndex: Int) {
        // Stop any existing playback first
        ttsService.stop()
        
        // Generate new session ID to force view refresh
        self.sessionId = UUID()
        
        // Reset all state
        self.currentVerseIndex = verseIndex
        self.showCompletionButtons = false
        self.shouldAutoScroll = verseIndex > 0  // Auto-scroll if not starting from beginning
        self.highlightedRange = nil
        self.verseReadPositions = [:]  // Reset tracking
        
        // Set new verses
        self.verses = verses
        self.languageMode = language
        self.isActive = true
        self.pendingStartIndex = verseIndex
        
        // Mark all previous verses as fully read
        if verseIndex > 0 {
            var positions: [Int: Int] = [:]
            for i in 0..<verseIndex {
                let verseLength = verses[i].text(for: language).count
                positions[i] = verseLength
            }
            self.verseReadPositions = positions
        }
        
        // Re-setup callbacks to ensure they're connected to this instance
        setupCallbacks()
        
        // Start playback once the listening view is ready
        beginPlaybackIfNeeded()
    }
    
    /// Exit listening mode
    func exit() {
        ttsService.stop()
        isActive = false
        isViewReady = false
        pendingStartIndex = nil
        verses = []
        currentVerseIndex = 0
        highlightedRange = nil
        showCompletionButtons = false
        shouldAutoScroll = false
        verseReadPositions = [:]  // Reset tracking
    }
    
    /// Toggle play/pause
    func togglePlayPause() {
        if isPlaying {
            ttsService.pause()
        } else if isPaused {
            ttsService.resume()
        } else if !verses.isEmpty {
            // Restart from beginning
            ttsService.speakVerses(verseTexts, language: languageMode)
        }
    }
    
    /// Go to previous verse
    func previousVerse() {
        ttsService.previousVerse(texts: verseTexts, language: languageMode)
    }
    
    /// Go to next verse
    func nextVerse() {
        // Mark current verse as fully read before skipping
        if currentVerseIndex < verses.count {
            let verseLength = verses[currentVerseIndex].text(for: languageMode).count
            var updatedPositions = verseReadPositions
            updatedPositions[currentVerseIndex] = verseLength
            verseReadPositions = updatedPositions
        }
        
        ttsService.nextVerse(texts: verseTexts, language: languageMode)
    }
    
    /// Jump to specific verse
    func jumpToVerse(_ index: Int) {
        guard index >= 0 && index < verses.count else { return }
        ttsService.jumpToVerse(index: index, texts: verseTexts, language: languageMode)
    }
    
    /// Pause playback (called when navigating away)
    func pauseForNavigation() {
        if isPlaying {
            ttsService.pause()
        } else if ttsService.isLoading {
            // Cancel loading request - audio would start playing after navigation otherwise
            ttsService.stop()
        }
    }
    
    /// Get the read position for a specific verse
    func readPosition(for verseIndex: Int) -> Int {
        return verseReadPositions[verseIndex] ?? 0
    }
    
    /// Check if a verse has started playing
    func hasStartedPlaying(verseIndex: Int) -> Bool {
        return verseReadPositions[verseIndex] != nil
    }
    
    /// Refresh callbacks - called when view appears to ensure proper observation
    func refreshCallbacks() {
        setupCallbacks()
    }
    
    /// Mark listening view ready and start pending playback if needed
    func markViewReady() {
        isViewReady = true
        beginPlaybackIfNeeded()
    }
    
    private func beginPlaybackIfNeeded() {
        guard isActive, isViewReady, let startIndex = pendingStartIndex else { return }
        pendingStartIndex = nil
        ttsService.speakFrom(index: startIndex, texts: verseTexts, language: languageMode)
    }
}

// MARK: - Supporting Types

struct VerseProgressSegment: Identifiable {
    let id = UUID()
    let verseIndex: Int
    let startProgress: Double
    let endProgress: Double
    let state: VerseProgressState
    
    var width: Double {
        endProgress - startProgress
    }
}

enum VerseProgressState {
    case pending
    case playing
    case completed
}

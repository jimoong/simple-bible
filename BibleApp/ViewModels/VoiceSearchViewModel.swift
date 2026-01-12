import SwiftUI
import Combine

/// State machine for voice search flow
enum VoiceSearchState: Equatable {
    case idle
    case listening
    case choosingOption  // Multiple matches - user needs to pick one
    case navigating
    case error(String)
}

@MainActor
@Observable
final class VoiceSearchViewModel {
    
    // MARK: - State
    var state: VoiceSearchState = .idle
    var showOverlay = false
    var currentAudioLevel: Float = 0.0
    var parsedOptions: ParsedBibleReference? = nil  // Stored when multiple options need to be shown
    
    // MARK: - Services
    private let voiceService = VoiceSearchService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Callbacks
    var onNavigate: ((BibleBook, Int, Int) async -> Void)?
    
    // MARK: - Computed Properties
    
    var isListening: Bool {
        if case .listening = state { return true }
        return false
    }
    
    var transcript: String {
        voiceService.transcript
    }
    
    var audioLevel: Float {
        currentAudioLevel
    }
    
    /// Real-time parsed result for live validation display
    var liveParseResult: ParsedBibleReference? {
        guard !transcript.isEmpty else { return nil }
        let result = BibleReferenceParser.shared.parse(transcript)
        return result.book != nil ? result : nil
    }
    
    /// Display text - shows validated reference (book + chapter + verse) if found, otherwise raw transcript
    var displayText: String {
        if let parsed = liveParseResult, let book = parsed.book {
            return formatReference(book: book, chapter: parsed.chapter, verse: parsed.verse)
        }
        return transcript
    }
    
    /// Format the parsed reference for display
    private func formatReference(book: BibleBook, chapter: Int?, verse: Int?) -> String {
        let bookName = book.name(for: languageMode)
        
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
    
    var errorMessage: String? {
        if case .error(let message) = state {
            return message
        }
        return voiceService.errorMessage
    }
    
    var isAuthorized: Bool {
        voiceService.isAuthorized
    }
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Observe transcript changes
        voiceService.$transcript
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Transcript updated - UI will refresh
            }
            .store(in: &cancellables)
        
        voiceService.$errorMessage
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                guard let self = self else { return }
                // Only transition to error state if we're currently listening
                // This prevents stale errors from affecting retry flow
                if case .listening = self.state {
                    self.state = .error(error)
                }
            }
            .store(in: &cancellables)
        
        // Observe audio level changes
        voiceService.$audioLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.currentAudioLevel = level
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func open(with languageMode: LanguageMode) {
        voiceService.setPreferredLanguage(languageMode)
        showOverlay = true
        state = .idle
    }
    
    /// Opens the overlay and immediately starts listening
    func openAndStartListening(with language: LanguageMode) {
        setLanguage(language)
        voiceService.clearTranscript()  // Start with clean state
        state = .listening  // Set state immediately to avoid idle flash
        showOverlay = true
        startListening()
    }
    
    func close() {
        voiceService.reset()  // Clear transcript and stop listening
        parsedOptions = nil
        showOverlay = false
        state = .idle
    }
    
    func startListening() {
        Task {
            do {
                state = .listening
                try await voiceService.startListening()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
    
    /// Stop listening and try to navigate with the current transcript
    func tryNavigate() {
        voiceService.stopListening()
        
        let result = voiceService.parseTranscript()
        
        if let book = result.book {
            // Check if there are multiple options
            if result.isAmbiguous {
                // Store the parsed result and show options
                parsedOptions = result
                state = .choosingOption
                HapticManager.shared.lightClick()
            } else {
                // Single match - navigate directly
                let chapter = result.chapter ?? 1
                let verse = result.verse ?? 1
                state = .navigating
                
                Task {
                    await onNavigate?(book, chapter, verse)
                    HapticManager.shared.success()
                    close()
                }
            }
        } else {
            let errorMsg = languageMode == .kr 
                ? "구절을 찾을 수 없습니다. 다시 시도해 주세요."
                : "Could not find the verse. Please try again."
            state = .error(errorMsg)
            HapticManager.shared.error()
        }
    }
    
    // Store language for error messages
    private var languageMode: LanguageMode = .kr
    
    func setLanguage(_ mode: LanguageMode) {
        languageMode = mode
        voiceService.setPreferredLanguage(mode)
    }
    
    func retryListening() {
        // Reset everything cleanly
        voiceService.reset()
        state = .listening  // Set to listening immediately to avoid idle flash
        
        // Small delay to let audio session properly reset
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            startListening()
        }
    }
    
    /// Navigate directly to a specific book (used when multiple options are shown)
    /// Always navigates to chapter 1, verse 1 to avoid hallucinated chapter numbers
    func navigateToBook(_ book: BibleBook) {
        voiceService.stopListening()
        state = .navigating
        
        Task {
            await onNavigate?(book, 1, 1)
            HapticManager.shared.success()
            close()
        }
    }
    
    // MARK: - Permission
    
    func requestPermission() {
        voiceService.checkAuthorization()
    }
}

import SwiftUI
import Combine

/// State machine for voice search flow
enum VoiceSearchState: Equatable {
    case idle
    case listening
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
    
    /// Real-time parsed result for validation preview
    var liveParseResult: ParsedBibleReference? {
        guard !transcript.isEmpty else { return nil }
        let result = BibleReferenceParser.shared.parse(transcript)
        return result.book != nil ? result : nil
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
                self?.state = .error(error)
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
        showOverlay = true
        startListening()
    }
    
    func close() {
        voiceService.stopListening()
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
        
        // Only require book to be found; default chapter and verse to 1 if not specified
        if let book = result.book {
            let chapter = result.chapter ?? 1
            let verse = result.verse ?? 1
            state = .navigating
            
            Task {
                await onNavigate?(book, chapter, verse)
                HapticManager.shared.success()
                close()
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
        state = .idle
        voiceService.clearTranscript()
        startListening()
    }
    
    // MARK: - Permission
    
    func requestPermission() {
        voiceService.checkAuthorization()
    }
}

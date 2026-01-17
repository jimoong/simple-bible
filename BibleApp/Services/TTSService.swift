import AVFoundation
import Combine

/// Text-to-Speech service for Bible verse reading using OpenAI TTS
@Observable
class TTSService: NSObject {
    static let shared = TTSService()
    
    // MARK: - Published State
    var isPlaying: Bool = false
    var isPaused: Bool = false
    var currentUtteranceIndex: Int = 0
    var currentCharacterRange: NSRange?
    var playbackProgress: Double = 0 // 0.0 to 1.0
    var isLoading: Bool = false
    var errorMessage: String?
    
    // MARK: - Private
    private var audioPlayer: AVAudioPlayer?
    private var verseTexts: [String] = []
    private var audioDataCache: [Int: Data] = [:]  // Cache audio for each verse
    private var totalVerses: Int = 0
    private var currentLanguage: LanguageMode = .kr
    
    // Session tracking to ignore stale async responses
    private var playbackSessionId: UUID = UUID()
    private var loadTask: Task<Void, Never>?
    private var prefetchTask: Task<Void, Never>?
    
    // Timer for simulating word progress (OpenAI TTS doesn't provide word-level callbacks)
    private var progressTask: Task<Void, Never>?
    private var currentVerseStartTime: Date?
    private var estimatedVerseDuration: TimeInterval = 0
    
    // Delegate callbacks
    var onUtteranceStart: ((Int) -> Void)?
    var onWordSpoken: ((Int, NSRange) -> Void)?  // (utteranceIndex, characterRange)
    var onUtteranceFinish: ((Int) -> Void)?
    var onAllFinished: (() -> Void)?
    var onError: ((String) -> Void)?
    
    // MARK: - Voice Settings
    var selectedVoice: String {
        didSet {
            UserDefaults.standard.set(selectedVoice, forKey: "tts_openai_voice")
        }
    }
    
    var speechRate: Float = 1.0 {  // 0.25 to 4.0
        didSet {
            UserDefaults.standard.set(speechRate, forKey: "tts_speech_rate")
        }
    }
    
    var volume: Float = 1.0 {  // 0.0 to 1.0
        didSet {
            audioPlayer?.volume = volume
            UserDefaults.standard.set(volume, forKey: "tts_volume")
        }
    }
    
    // Available OpenAI voices
    static let availableVoices = ["alloy", "echo", "fable", "onyx", "nova", "shimmer"]
    
    private override init() {
        self.selectedVoice = UserDefaults.standard.string(forKey: "tts_openai_voice") ?? Constants.OpenAI.ttsVoice
        super.init()
        loadSettings()
        setupAudioSession()
    }
    
    private func loadSettings() {
        if UserDefaults.standard.object(forKey: "tts_speech_rate") != nil {
            speechRate = UserDefaults.standard.float(forKey: "tts_speech_rate")
        }
        if UserDefaults.standard.object(forKey: "tts_volume") != nil {
            volume = UserDefaults.standard.float(forKey: "tts_volume")
        }
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    /// Ensure audio session is ready before playback
    private func ensureAudioSessionReady() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Re-activate session if needed (fixes cold start issue)
            if !session.isOtherAudioPlaying {
                try session.setActive(true)
            }
        } catch {
            print("Failed to ensure audio session: \(error)")
        }
    }
    
    // MARK: - OpenAI TTS API
    
    /// Generate speech audio from text using OpenAI TTS
    private func generateSpeech(text: String) async throws -> Data {
        let apiKey = Constants.OpenAI.apiKey
        
        guard !apiKey.isEmpty && !apiKey.contains("YOUR") else {
            throw TTSError.noAPIKey
        }
        
        guard let url = URL(string: Constants.OpenAI.ttsURL) else {
            throw TTSError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": Constants.OpenAI.ttsModel,
            "voice": selectedVoice,
            "input": text,
            "speed": speechRate,
            "response_format": "mp3"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TTSError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            // Try to parse error message
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw TTSError.apiError(message)
            }
            throw TTSError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        return data
    }
    
    // MARK: - Playback Control
    
    /// Speak multiple verses sequentially
    func speakVerses(_ texts: [String], language: LanguageMode) {
        stop()
        startNewSession()
        
        verseTexts = texts
        totalVerses = texts.count
        currentLanguage = language
        currentUtteranceIndex = 0
        audioDataCache.removeAll()
        isLoading = true
        errorMessage = nil
        
        // Start loading and playing
        loadTask = Task { [weak self] in
            guard let self else { return }
            await self.loadAndPlayVerse(index: 0, sessionId: self.playbackSessionId)
        }
    }
    
    /// Load audio for a verse and play it
    private func loadAndPlayVerse(index: Int, sessionId: UUID) async {
        guard sessionId == playbackSessionId else { return }
        guard index < verseTexts.count else {
            await MainActor.run {
                guard sessionId == playbackSessionId else { return }
                isLoading = false
                isPlaying = false
                onAllFinished?()
            }
            return
        }
        
        let text = verseTexts[index]
        
        do {
            // Check cache first
            let audioData: Data
            if let cached = audioDataCache[index] {
                audioData = cached
            } else {
                // Generate audio
                await MainActor.run {
                    guard sessionId == playbackSessionId else { return }
                    if index == 0 {
                        isLoading = true
                    }
                }
                
                audioData = try await generateSpeech(text: text)
                guard sessionId == playbackSessionId else { return }
                audioDataCache[index] = audioData
                
                // Pre-fetch next verse in background
                if index + 1 < verseTexts.count {
                    prefetchTask?.cancel()
                    prefetchTask = Task { [weak self] in
                        guard let self else { return }
                        guard sessionId == self.playbackSessionId else { return }
                        if let nextData = try? await self.generateSpeech(text: self.verseTexts[index + 1]) {
                            guard sessionId == self.playbackSessionId else { return }
                            self.audioDataCache[index + 1] = nextData
                        }
                    }
                }
            }
            
            // Play audio
            await MainActor.run {
                guard sessionId == playbackSessionId else { return }
                isLoading = false
                // Don't play if user paused during loading
                guard !isPaused else { return }
                playAudio(data: audioData, verseIndex: index)
            }
            
        } catch {
            await MainActor.run {
                guard sessionId == playbackSessionId else { return }
                isLoading = false
                isPlaying = false
                errorMessage = error.localizedDescription
                onError?(error.localizedDescription)
                
                // Report error via FeedbackManager
                FeedbackManager.shared.reportError(
                    error,
                    context: ErrorContext(
                        service: "TTSService",
                        action: "generateSpeech",
                        additionalInfo: ["verseIndex": "\(index)"]
                    ),
                    userMessage: "음성 변환에 문제가 있습니다"
                )
            }
        }
    }
    
    /// Play audio data
    private func playAudio(data: Data, verseIndex: Int) {
        // Ensure audio session is ready (fixes cold start issue)
        ensureAudioSessionReady()
        
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
            currentUtteranceIndex = verseIndex
            isPlaying = true
            isPaused = false
            
            // Start progress simulation
            startProgressSimulation(for: verseIndex)
            onUtteranceStart?(verseIndex)
            
        } catch {
            errorMessage = "오디오 재생 실패: \(error.localizedDescription)"
            onError?(errorMessage!)
            
            // Report error via FeedbackManager
            FeedbackManager.shared.reportError(
                error,
                context: ErrorContext(
                    service: "TTSService",
                    action: "playAudio",
                    additionalInfo: ["verseIndex": "\(verseIndex)"]
                ),
                userMessage: "오디오 재생에 문제가 있습니다"
            )
        }
    }
    
    /// Simulate word-by-word progress (OpenAI doesn't provide word callbacks)
    private func startProgressSimulation(for verseIndex: Int) {
        progressTask?.cancel()
        progressTask = nil
        
        guard verseIndex < verseTexts.count else { return }
        
        let text = verseTexts[verseIndex]
        let textLength = text.count
        let duration = audioPlayer?.duration ?? Double(textLength) * 0.05
        
        currentVerseStartTime = Date()
        estimatedVerseDuration = max(0.1, duration)
        
        // Capture values for closure
        let capturedVerseIndex = verseIndex
        let capturedTextLength = textLength
        let capturedDuration = estimatedVerseDuration
        let startTime = currentVerseStartTime!
        let sessionId = playbackSessionId
        
        // Update progress every 100ms
        progressTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            while !Task.isCancelled {
                guard sessionId == self.playbackSessionId else { break }
                
                if self.isPaused {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    continue
                }
                
                let elapsed = Date().timeIntervalSince(startTime)
                let currentTime = self.audioPlayer?.currentTime ?? 0
                let effectiveDuration = max(0.1, self.audioPlayer?.duration ?? capturedDuration)
                let baseTime = max(currentTime, elapsed)
                let progress = min(1.0, baseTime / effectiveDuration)
                
                // Estimate current character position
                let charPosition = Int(Double(capturedTextLength) * progress)
                let range = NSRange(location: 0, length: min(charPosition, capturedTextLength))
                
                self.onWordSpoken?(capturedVerseIndex, range)
                
                // Update overall progress
                let verseProgress = Double(capturedVerseIndex) / Double(max(1, self.totalVerses))
                let withinVerseProgress = progress / Double(max(1, self.totalVerses))
                self.playbackProgress = verseProgress + withinVerseProgress
                
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }
    
    /// Start playing from a specific verse index
    func speakFrom(index: Int, texts: [String], language: LanguageMode) {
        guard index < texts.count else { return }
        stop()
        startNewSession()
        verseTexts = texts
        totalVerses = texts.count
        currentLanguage = language
        currentUtteranceIndex = index
        
        loadTask = Task { [weak self] in
            guard let self else { return }
            await self.loadAndPlayVerse(index: index, sessionId: self.playbackSessionId)
        }
    }
    
    /// Pause playback
    func pause() {
        audioPlayer?.pause()
        progressTask?.cancel()
        progressTask = nil
        isPaused = true
        isPlaying = false
    }
    
    /// Resume playback
    func resume() {
        audioPlayer?.play()
        
        // Resume progress timer
        if let startTime = currentVerseStartTime {
            let elapsed = audioPlayer?.currentTime ?? 0
            currentVerseStartTime = Date().addingTimeInterval(-elapsed)
            startProgressSimulation(for: currentUtteranceIndex)
        }
        
        isPaused = false
        isPlaying = true
    }
    
    /// Stop playback completely
    func stop() {
        progressTask?.cancel()
        progressTask = nil
        loadTask?.cancel()
        loadTask = nil
        prefetchTask?.cancel()
        prefetchTask = nil
        startNewSession()
        audioPlayer?.stop()
        audioPlayer = nil
        
        verseTexts.removeAll()
        audioDataCache.removeAll()
        isPlaying = false
        isPaused = false
        isLoading = false
        currentUtteranceIndex = 0
        currentCharacterRange = nil
        playbackProgress = 0
        totalVerses = 0
    }

    private func startNewSession() {
        playbackSessionId = UUID()
    }
    
    /// Toggle play/pause
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else if isPaused {
            resume()
        }
    }
    
    /// Skip to previous verse
    func previousVerse(texts: [String], language: LanguageMode) {
        let newIndex = max(0, currentUtteranceIndex - 1)
        speakFrom(index: newIndex, texts: texts, language: language)
    }
    
    /// Skip to next verse
    func nextVerse(texts: [String], language: LanguageMode) {
        let newIndex = min(texts.count - 1, currentUtteranceIndex + 1)
        speakFrom(index: newIndex, texts: texts, language: language)
    }
    
    /// Jump to specific verse
    func jumpToVerse(index: Int, texts: [String], language: LanguageMode) {
        speakFrom(index: index, texts: texts, language: language)
    }
}

// MARK: - AVAudioPlayerDelegate
extension TTSService: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard totalVerses > 0 else { return }
        progressTask?.cancel()
        progressTask = nil
        
        let finishedIndex = currentUtteranceIndex
        onUtteranceFinish?(finishedIndex)
        
        // Play next verse
        let nextIndex = finishedIndex + 1
        if nextIndex < totalVerses {
            loadTask?.cancel()
            loadTask = Task { [weak self] in
                guard let self else { return }
                await self.loadAndPlayVerse(index: nextIndex, sessionId: self.playbackSessionId)
            }
        } else {
            // All finished
            isPlaying = false
            isPaused = false
            playbackProgress = 1.0
            onAllFinished?()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        errorMessage = "오디오 디코딩 오류: \(error?.localizedDescription ?? "Unknown")"
        onError?(errorMessage!)
        
        // Report error via FeedbackManager
        if let error = error {
            FeedbackManager.shared.reportError(
                error,
                context: ErrorContext(
                    service: "TTSService",
                    action: "audioPlayerDecode"
                ),
                userMessage: "오디오 디코딩에 문제가 있습니다"
            )
        } else {
            FeedbackManager.shared.reportError(
                message: "Unknown audio decode error",
                context: ErrorContext(
                    service: "TTSService",
                    action: "audioPlayerDecode"
                ),
                userMessage: "오디오 디코딩에 문제가 있습니다"
            )
        }
    }
}

// MARK: - Errors
enum TTSError: Error, LocalizedError {
    case noAPIKey
    case invalidURL
    case invalidResponse
    case apiError(String)
    case audioPlaybackError(String)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API 키가 설정되지 않았습니다."
        case .invalidURL:
            return "잘못된 URL입니다."
        case .invalidResponse:
            return "서버 응답을 처리할 수 없습니다."
        case .apiError(let message):
            return "API 오류: \(message)"
        case .audioPlaybackError(let message):
            return "오디오 재생 오류: \(message)"
        }
    }
}

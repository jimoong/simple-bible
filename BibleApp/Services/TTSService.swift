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
    
    // Timer for simulating word progress (OpenAI TTS doesn't provide word-level callbacks)
    private var progressTimer: Timer?
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
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
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
        
        verseTexts = texts
        totalVerses = texts.count
        currentLanguage = language
        currentUtteranceIndex = 0
        audioDataCache.removeAll()
        isLoading = true
        errorMessage = nil
        
        // Start loading and playing
        Task {
            await loadAndPlayVerse(index: 0)
        }
    }
    
    /// Load audio for a verse and play it
    private func loadAndPlayVerse(index: Int) async {
        guard index < verseTexts.count else {
            await MainActor.run {
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
                    if index == 0 {
                        isLoading = true
                    }
                }
                
                audioData = try await generateSpeech(text: text)
                audioDataCache[index] = audioData
                
                // Pre-fetch next verse in background
                if index + 1 < verseTexts.count {
                    Task {
                        if let nextData = try? await generateSpeech(text: verseTexts[index + 1]) {
                            audioDataCache[index + 1] = nextData
                        }
                    }
                }
            }
            
            // Play audio
            await MainActor.run {
                isLoading = false
                playAudio(data: audioData, verseIndex: index)
            }
            
        } catch {
            await MainActor.run {
                isLoading = false
                isPlaying = false
                errorMessage = error.localizedDescription
                onError?(error.localizedDescription)
            }
        }
    }
    
    /// Play audio data
    private func playAudio(data: Data, verseIndex: Int) {
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
        }
    }
    
    /// Simulate word-by-word progress (OpenAI doesn't provide word callbacks)
    private func startProgressSimulation(for verseIndex: Int) {
        progressTimer?.invalidate()
        progressTimer = nil
        
        guard verseIndex < verseTexts.count else { return }
        
        let text = verseTexts[verseIndex]
        let textLength = text.count
        let duration = audioPlayer?.duration ?? Double(textLength) * 0.05
        
        currentVerseStartTime = Date()
        estimatedVerseDuration = max(0.1, duration)  // Ensure non-zero duration
        
        // Capture values for closure
        let capturedVerseIndex = verseIndex
        let capturedTextLength = textLength
        let capturedDuration = estimatedVerseDuration
        let startTime = currentVerseStartTime!
        
        // Update progress every 100ms - explicitly on main run loop
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard self.isPlaying else { return }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(1.0, elapsed / capturedDuration)
            
            // Estimate current character position (how much we've read)
            let charPosition = Int(Double(capturedTextLength) * progress)
            // Range represents: location=0, length=charPosition (total read so far)
            let range = NSRange(location: 0, length: min(charPosition, capturedTextLength))
            
            self.onWordSpoken?(capturedVerseIndex, range)
            
            // Update overall progress
            let verseProgress = Double(capturedVerseIndex) / Double(max(1, self.totalVerses))
            let withinVerseProgress = progress / Double(max(1, self.totalVerses))
            self.playbackProgress = verseProgress + withinVerseProgress
        }
        
        // Add to main run loop explicitly
        RunLoop.main.add(timer, forMode: .common)
        progressTimer = timer
    }
    
    /// Start playing from a specific verse index
    func speakFrom(index: Int, texts: [String], language: LanguageMode) {
        guard index < texts.count else { return }
        stop()
        verseTexts = texts
        totalVerses = texts.count
        currentLanguage = language
        currentUtteranceIndex = index
        
        Task {
            await loadAndPlayVerse(index: index)
        }
    }
    
    /// Pause playback
    func pause() {
        audioPlayer?.pause()
        progressTimer?.invalidate()
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
        audioPlayer?.stop()
        audioPlayer = nil
        progressTimer?.invalidate()
        progressTimer = nil
        
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
        progressTimer?.invalidate()
        
        let finishedIndex = currentUtteranceIndex
        onUtteranceFinish?(finishedIndex)
        
        // Play next verse
        let nextIndex = finishedIndex + 1
        if nextIndex < totalVerses {
            Task {
                await loadAndPlayVerse(index: nextIndex)
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

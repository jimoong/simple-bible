import Foundation
import Speech
import AVFoundation

/// Handles speech recognition for Bible verse search
@MainActor
final class VoiceSearchService: ObservableObject {
    
    // MARK: - Published State
    @Published var isListening = false
    @Published var isAuthorized = false
    @Published var transcript = ""
    @Published var errorMessage: String?
    @Published var audioLevel: Float = 0.0  // 0.0 to 1.0 normalized audio intensity
    
    // MARK: - Private Properties
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isIntentionallyStopping = false  // Flag to ignore errors during intentional stops
    
    // Detect language based on user's current setting, but allow auto-detection
    private var preferredLocale: Locale = Locale(identifier: "ko-KR")
    
    // MARK: - Initialization
    init() {
        setupSpeechRecognizer()
    }
    
    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: preferredLocale)
        checkAuthorization()
    }
    
    // MARK: - Authorization
    
    func checkAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                switch status {
                case .authorized:
                    self?.isAuthorized = true
                case .denied:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition permission denied"
                case .restricted:
                    self?.isAuthorized = false
                    self?.errorMessage = "Speech recognition is restricted on this device"
                case .notDetermined:
                    self?.isAuthorized = false
                @unknown default:
                    self?.isAuthorized = false
                }
            }
        }
    }
    
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    // MARK: - Set Language Preference
    
    func setPreferredLanguage(_ language: LanguageMode) {
        let localeId = language == .kr ? "ko-KR" : "en-US"
        preferredLocale = Locale(identifier: localeId)
        speechRecognizer = SFSpeechRecognizer(locale: preferredLocale)
    }
    
    // MARK: - Start/Stop Listening
    
    func startListening() async throws {
        // Stop any existing task first
        stopListening()
        
        // Reset state after stopping
        transcript = ""
        errorMessage = nil
        isIntentionallyStopping = false  // Clear the flag when starting fresh
        
        // Check authorization
        guard isAuthorized else {
            throw VoiceSearchError.notAuthorized
        }
        
        // Request microphone permission
        let micGranted = await requestMicrophonePermission()
        guard micGranted else {
            throw VoiceSearchError.microphoneNotAuthorized
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceSearchError.requestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.taskHint = .dictation
        
        // Try on-device first for potentially better accuracy with short phrases
        // Falls back to server if on-device isn't available
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        
        // Get input node
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on input
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            // Calculate audio level from buffer
            self?.processAudioLevel(buffer: buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        isListening = true
        
        // Start recognition task
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw VoiceSearchError.recognizerNotAvailable
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                // Ignore all callbacks if we're intentionally stopping
                if self.isIntentionallyStopping {
                    return
                }
                
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString
                }
                
                if let error = error {
                    // Ignore cancellation errors and common non-critical errors
                    let nsError = error as NSError
                    let isCancellation = nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216
                    let isNoSpeech = nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110
                    
                    if !isCancellation && !isNoSpeech {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func stopListening() {
        // Mark as intentionally stopping to ignore cancellation errors
        isIntentionallyStopping = true
        
        // Cancel recognition task first (before ending audio)
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // End recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // Stop audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        isListening = false
        audioLevel = 0.0
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    /// Reset state for retry - clears errors and transcript
    func reset() {
        stopListening()
        transcript = ""
        errorMessage = nil
        audioLevel = 0.0
    }
    
    // MARK: - Audio Level Processing
    
    private func processAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        // Calculate RMS (Root Mean Square) for audio level
        var sum: Float = 0
        for i in 0..<frameLength {
            let sample = channelData[i]
            sum += sample * sample
        }
        
        let rms = sqrt(sum / Float(frameLength))
        
        // Convert to decibels and normalize to 0-1 range
        // Typical speech is around -20 to -10 dB
        let minDb: Float = -50
        let maxDb: Float = -10
        
        let db = 20 * log10(max(rms, 0.0001))
        let normalizedLevel = (db - minDb) / (maxDb - minDb)
        let clampedLevel = max(0, min(1, normalizedLevel))
        
        // Update on main thread with smoothing
        Task { @MainActor in
            // Smooth the transition
            self.audioLevel = self.audioLevel * 0.3 + clampedLevel * 0.7
        }
    }
    
    // MARK: - Parse Current Transcript
    
    func parseTranscript() -> ParsedBibleReference {
        return BibleReferenceParser.shared.parse(transcript)
    }
    
    func clearTranscript() {
        transcript = ""
        audioLevel = 0.0
    }
}

// MARK: - Errors

enum VoiceSearchError: LocalizedError {
    case notAuthorized
    case microphoneNotAuthorized
    case requestCreationFailed
    case recognizerNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition is not authorized"
        case .microphoneNotAuthorized:
            return "Microphone access is not authorized"
        case .requestCreationFailed:
            return "Could not create speech recognition request"
        case .recognizerNotAvailable:
            return "Speech recognizer is not available"
        }
    }
}

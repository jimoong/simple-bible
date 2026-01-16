import SwiftUI
import MessageUI
import AVFoundation

struct SettingsView: View {
    @Binding var languageMode: LanguageMode
    @Binding var readingMode: ReadingMode
    var viewModel: BibleViewModel  // Direct reference to update language codes
    var onDismiss: () -> Void
    
    // MARK: - State
    @State private var primaryTranslation: BibleTranslation = .krv
    @State private var secondaryTranslation: BibleTranslation = .kjv
    @State private var showPrimaryPicker: Bool = false
    @State private var showSecondaryPicker: Bool = false
    @State private var showOfflineDownloads: Bool = false
    @State private var showVoicePicker: Bool = false
    @State private var selectedVoice: String = TTSService.shared.selectedVoice
    @State private var mailError: String?
    @State private var showClearDataConfirmation = false
    @State private var downloadedCount: Int = 0
    @State private var isPlayingVoiceDemo: Bool = false
    
    // Legal document sheets
    @State private var showPrivacyPolicy: Bool = false
    @State private var showTermsOfService: Bool = false
    @State private var showAIDisclosure: Bool = false
    
    
    private let appVersion = "1.0.0"
    private let contactEmail = "jiwoong.net@gmail.com"
    
    /// UI language based on currently active display mode (follows toggle)
    private var isKoreanUI: Bool {
        viewModel.uiLanguage == .kr
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0a0a0a")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Languages Section
                        languagesSection
                        
                        // Reading Section
                        readingSection
                        
                        // Listening Section
                        listeningSection
                        
                        // About Section
                        aboutSection
                        
                        // Offline Downloads Section
                        offlineSection
                        
                        // Developer Section
                        developerSection
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle(isKoreanUI ? "설정" : "Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.shared.selection()
                        onDismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.08))
                                .frame(width: 30, height: 30)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbarBackground(Color(hex: "0a0a0a"), for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadSavedTranslations()
        }
        .sheet(isPresented: $showPrimaryPicker) {
            TranslationPickerSheet(
                title: isKoreanUI ? "주 언어" : "Primary Language",
                cancelLabel: isKoreanUI ? "취소" : "Cancel",
                saveLabel: isKoreanUI ? "저장" : "Save",
                searchPlaceholder: isKoreanUI ? "번역 검색" : "Search translations",
                selectedTranslation: $primaryTranslation,
                onSelect: { savePrimaryTranslation() }
            )
        }
        .sheet(isPresented: $showSecondaryPicker) {
            TranslationPickerSheet(
                title: isKoreanUI ? "보조 언어" : "Secondary Language",
                cancelLabel: isKoreanUI ? "취소" : "Cancel",
                saveLabel: isKoreanUI ? "저장" : "Save",
                searchPlaceholder: isKoreanUI ? "번역 검색" : "Search translations",
                selectedTranslation: $secondaryTranslation,
                onSelect: { saveSecondaryTranslation() }
            )
        }
        .sheet(isPresented: $showOfflineDownloads) {
            OfflineDownloadView(isKoreanUI: isKoreanUI)
        }
        .sheet(isPresented: $showVoicePicker) {
            VoicePickerSheet(
                isKoreanUI: isKoreanUI,
                selectedVoice: $selectedVoice,
                onSelect: { voice in
                    TTSService.shared.selectedVoice = voice
                    selectedVoice = voice
                },
                onPlayDemo: { voice in
                    playVoiceDemo(voice: voice)
                }
            )
        }
        .alert(isKoreanUI ? "메일 오류" : "Mail Error", isPresented: .constant(mailError != nil)) {
            Button(isKoreanUI ? "확인" : "OK") { mailError = nil }
        } message: {
            Text(mailError ?? "")
        }
    }
    
    // MARK: - Languages Section
    private var languagesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: isKoreanUI ? "언어" : "Languages")
            
            VStack(spacing: 0) {
                // Primary Language
                Button {
                    HapticManager.shared.selection()
                    showPrimaryPicker = true
                } label: {
                    HStack {
                        Text(isKoreanUI ? "\(primaryTranslation.language) (주 언어)" : "\(primaryTranslation.language) (Primary)")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Text(primaryTranslation.id)
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                    .background(.white.opacity(0.06))
                    .padding(.leading, 16)
                
                // Secondary Language
                Button {
                    HapticManager.shared.selection()
                    showSecondaryPicker = true
                } label: {
                    HStack {
                        Text(secondaryTranslation.language)
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Text(secondaryTranslation.id)
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.04))
            )
        }
    }
    
    // MARK: - Offline Downloads Section
    private var offlineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: isKoreanUI ? "오프라인" : "Offline")
            
            VStack(spacing: 0) {
                Button {
                    HapticManager.shared.selection()
                    showOfflineDownloads = true
                } label: {
                    HStack {
                        Text(isKoreanUI ? "다운로드 관리" : "Manage Downloads")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            if downloadedCount > 0 {
                                Text("\(downloadedCount)")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.04))
            )
        }
        .task {
            await refreshDownloadCount()
        }
    }
    
    private func refreshDownloadCount() async {
        await DownloadManager.shared.refreshDownloadedTranslations()
        // Only count completed downloads (not auto-cached chapters)
        downloadedCount = DownloadManager.shared.downloadStates.values.filter { state in
            if case .completed = state { return true }
            return false
        }.count
    }
    
    // MARK: - Reading Section
    @ObservedObject private var fontSizeSettings = FontSizeSettings.shared
    
    private var readingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: isKoreanUI ? "읽기" : "Reading")
            
            VStack(spacing: 0) {
                // Reading Mode Toggle
                HStack {
                    Text(isKoreanUI ? "읽기 모드" : "Reading Mode")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Segmented Picker
                    HStack(spacing: 0) {
                        ForEach(ReadingMode.allCases, id: \.self) { mode in
                            Button {
                                HapticManager.shared.selection()
                                withAnimation(.easeOut(duration: 0.15)) {
                                    readingMode = mode
                                }
                            } label: {
                                Text(mode.displayName(for: isKoreanUI ? .kr : .en))
                                    .font(.system(size: 14, weight: readingMode == mode ? .semibold : .regular))
                                    .foregroundStyle(readingMode == mode ? .white : .white.opacity(0.5))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(readingMode == mode ? .white.opacity(0.15) : .clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.white.opacity(0.06))
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
                Divider()
                    .background(.white.opacity(0.06))
                    .padding(.leading, 16)
                
                // Font Size Toggle
                HStack {
                    Text(isKoreanUI ? "글자 크기" : "Font Size")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Segmented Picker
                    HStack(spacing: 0) {
                        ForEach(FontSizeMode.allCases, id: \.self) { mode in
                            Button {
                                HapticManager.shared.selection()
                                withAnimation(.easeOut(duration: 0.15)) {
                                    fontSizeSettings.mode = mode
                                }
                            } label: {
                                Text(mode.displayName(for: isKoreanUI ? .kr : .en))
                                    .font(.system(size: 14, weight: fontSizeSettings.mode == mode ? .semibold : .regular))
                                    .foregroundStyle(fontSizeSettings.mode == mode ? .white : .white.opacity(0.5))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(fontSizeSettings.mode == mode ? .white.opacity(0.15) : .clear)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.white.opacity(0.06))
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.04))
            )
        }
    }
    
    // MARK: - Listening Section
    private var listeningSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: isKoreanUI ? "듣기" : "Listening")
            
            VStack(spacing: 0) {
                // Voice Selection
                Button {
                    HapticManager.shared.selection()
                    showVoicePicker = true
                } label: {
                    HStack {
                        Text(isKoreanUI ? "목소리" : "Voice")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Text(selectedVoice.capitalized)
                                .font(.system(size: 16))
                                .foregroundStyle(.white.opacity(0.4))
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.04))
            )
        }
    }
    
    private func playVoiceDemo(voice: String) {
        guard !isPlayingVoiceDemo else { return }
        isPlayingVoiceDemo = true
        
        let voiceDisplayName = voice.capitalized
        let demoText = isKoreanUI 
            ? "안녕하세요, 반갑습니다. 저는 \(voiceDisplayName)입니다."
            : "Hi, nice to meet you. I'm \(voiceDisplayName)."
        
        // Temporarily change voice to play demo
        let originalVoice = TTSService.shared.selectedVoice
        TTSService.shared.selectedVoice = voice
        
        Task {
            do {
                let audioData = try await generateDemoSpeech(text: demoText)
                await MainActor.run {
                    playDemoAudio(data: audioData)
                }
            } catch {
                print("Voice demo error: \(error)")
            }
            
            // Restore original voice after demo
            await MainActor.run {
                TTSService.shared.selectedVoice = originalVoice
                isPlayingVoiceDemo = false
            }
        }
    }
    
    private func generateDemoSpeech(text: String) async throws -> Data {
        let apiKey = Constants.OpenAI.apiKey
        guard !apiKey.isEmpty && !apiKey.contains("YOUR") else {
            throw NSError(domain: "TTS", code: -1, userInfo: [NSLocalizedDescriptionKey: "No API key"])
        }
        
        guard let url = URL(string: Constants.OpenAI.ttsURL) else {
            throw NSError(domain: "TTS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": Constants.OpenAI.ttsModel,
            "voice": TTSService.shared.selectedVoice,
            "input": text,
            "speed": 1.0,
            "response_format": "mp3"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "TTS", code: -1, userInfo: [NSLocalizedDescriptionKey: "API Error"])
        }
        
        return data
    }
    
    @State private var demoAudioPlayer: AVAudioPlayer?
    
    private func playDemoAudio(data: Data) {
        do {
            demoAudioPlayer = try AVAudioPlayer(data: data)
            demoAudioPlayer?.play()
        } catch {
            print("Audio playback error: \(error)")
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: isKoreanUI ? "정보" : "About")
            
            VStack(spacing: 0) {
                // Version
                HStack {
                    Text(isKoreanUI ? "버전" : "Version")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text(appVersion)
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
                Divider()
                    .background(.white.opacity(0.06))
                    .padding(.leading, 16)
                
                // AI Assistant Info
                Button {
                    HapticManager.shared.selection()
                    showAIDisclosure = true
                } label: {
                    HStack {
                        Text(isKoreanUI ? "AI 도우미 정보" : "AI Assistant Info")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                    .background(.white.opacity(0.06))
                    .padding(.leading, 16)
                
                // Privacy Policy
                Button {
                    HapticManager.shared.selection()
                    showPrivacyPolicy = true
                } label: {
                    HStack {
                        Text(isKoreanUI ? "개인정보 처리방침" : "Privacy Policy")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                    .background(.white.opacity(0.06))
                    .padding(.leading, 16)
                
                // Terms of Service
                Button {
                    HapticManager.shared.selection()
                    showTermsOfService = true
                } label: {
                    HStack {
                        Text(isKoreanUI ? "이용약관" : "Terms of Service")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                    .background(.white.opacity(0.06))
                    .padding(.leading, 16)
                
                // Contact
                Button {
                    HapticManager.shared.selection()
                    openMailComposer()
                } label: {
                    HStack {
                        Text(isKoreanUI ? "개발자 연락처" : "Contact")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        Text(contactEmail)
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.04))
            )
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            LegalTextSheet(
                title: isKoreanUI ? "개인정보 처리방침" : "Privacy Policy",
                content: AppLegalTexts.privacyPolicy(isKorean: isKoreanUI),
                isKoreanUI: isKoreanUI
            )
        }
        .sheet(isPresented: $showTermsOfService) {
            LegalTextSheet(
                title: isKoreanUI ? "이용약관" : "Terms of Service",
                content: AppLegalTexts.termsOfService(isKorean: isKoreanUI),
                isKoreanUI: isKoreanUI
            )
        }
        .sheet(isPresented: $showAIDisclosure) {
            LegalTextSheet(
                title: isKoreanUI ? "AI 도우미 정보" : "AI Assistant Info",
                content: AppLegalTexts.aiDisclosure(isKorean: isKoreanUI),
                isKoreanUI: isKoreanUI
            )
        }
    }
    
    // MARK: - Developer Section
    @State private var showClearCacheConfirmation = false
    
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: isKoreanUI ? "개발자" : "Developer")
            
            VStack(spacing: 0) {
                // Clear Cache (for debugging verse navigation issues)
                Button {
                    HapticManager.shared.selection()
                    showClearCacheConfirmation = true
                } label: {
                    HStack {
                        Text(isKoreanUI ? "캐시 지우기" : "Clear Cache")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.85))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
                    .background(.white.opacity(0.06))
                    .padding(.leading, 16)
                
                // Clear All Data
                Button {
                    HapticManager.shared.selection()
                    showClearDataConfirmation = true
                } label: {
                    HStack {
                        Text(isKoreanUI ? "앱 리셋" : "Reset App")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(hex: "ef4444"))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.04))
            )
        }
        .alert(isKoreanUI ? "캐시 지우기" : "Clear Cache", isPresented: $showClearCacheConfirmation) {
            Button(isKoreanUI ? "취소" : "Cancel", role: .cancel) { }
            Button(isKoreanUI ? "지우기" : "Clear", role: .destructive) {
                clearCache()
            }
        } message: {
            Text(isKoreanUI ? "다운로드한 성경 데이터 캐시를 지웁니다. 앱이 데이터를 다시 다운로드합니다." : "This will clear cached Bible data. The app will re-download data as needed.")
        }
        .alert(isKoreanUI ? "모든 정보 삭제" : "Clear All Data", isPresented: $showClearDataConfirmation) {
            Button(isKoreanUI ? "취소" : "Cancel", role: .cancel) { }
            Button(isKoreanUI ? "삭제" : "Clear", role: .destructive) {
                clearAllSavedData()
            }
        } message: {
            Text(isKoreanUI ? "모든 읽기 진행 상황, 기록, 저장된 구절이 삭제됩니다. 이 작업은 되돌릴 수 없습니다." : "This will clear all reading progress, toast history, and saved verses. This action cannot be undone.")
        }
    }
    
    private func clearCache() {
        Task {
            // Clear in-memory cache
            await BibleAPIService.shared.clearCache()
            
            // Clear current chapter cache to force reload
            await BibleAPIService.shared.clearChapterCache(
                book: viewModel.currentBook,
                chapter: viewModel.currentChapter
            )
            
            // Reload current chapter
            await viewModel.reloadCurrentChapter()
            
            HapticManager.shared.success()
        }
    }
    
    private func clearAllSavedData() {
        // Clear reading progress
        ReadingProgressTracker.shared.clearAll()
        
        // Clear chapter toast tracker
        ChapterToastTracker.shared.clearAll()
        
        // Clear all favorites
        FavoriteService.shared.clearAll()
        
        HapticManager.shared.success()
    }
    
    // MARK: - Section Header
    private func sectionHeader(title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white.opacity(0.35))
            .kerning(0.8)
            .padding(.leading, 4)
    }
    
    // MARK: - Data Persistence
    private func loadSavedTranslations() {
        let defaults = UserDefaults.standard
        
        // Load primary translation
        if let primaryId = defaults.string(forKey: "primaryTranslationId") {
            // Try to find in hardcoded list first
            if let translation = BibleTranslation.allTranslations.first(where: { $0.id == primaryId }) {
                primaryTranslation = translation
            } else {
                // Reconstruct from saved data (for API translations not in hardcoded list)
                let languageCode = defaults.string(forKey: "primaryLanguageCode") ?? "ko"
                let language = defaults.string(forKey: "primaryLanguage") ?? "Korean"
                let name = defaults.string(forKey: "primaryTranslationName") ?? primaryId
                primaryTranslation = BibleTranslation(
                    id: primaryId,
                    name: name,
                    shortName: primaryId,
                    language: language,
                    languageCode: languageCode
                )
            }
        }
        
        // Load secondary translation
        if let secondaryId = defaults.string(forKey: "secondaryTranslationId") {
            // Try to find in hardcoded list first
            if let translation = BibleTranslation.allTranslations.first(where: { $0.id == secondaryId }) {
                secondaryTranslation = translation
            } else {
                // Reconstruct from saved data
                let languageCode = defaults.string(forKey: "secondaryLanguageCode") ?? "en"
                let language = defaults.string(forKey: "secondaryLanguage") ?? "English"
                let name = defaults.string(forKey: "secondaryTranslationName") ?? secondaryId
                secondaryTranslation = BibleTranslation(
                    id: secondaryId,
                    name: name,
                    shortName: secondaryId,
                    language: language,
                    languageCode: languageCode
                )
            }
        }
    }
    
    private func savePrimaryTranslation() {
        UserDefaults.standard.set(primaryTranslation.id, forKey: "primaryTranslationId")
        UserDefaults.standard.set(primaryTranslation.languageCode, forKey: "primaryLanguageCode")
        UserDefaults.standard.set(primaryTranslation.language, forKey: "primaryLanguage")
        UserDefaults.standard.set(primaryTranslation.name, forKey: "primaryTranslationName")
        
        // Update ViewModel immediately so UI updates
        viewModel.primaryLanguageCode = primaryTranslation.languageCode
        
        // Clear API cache so new translation is fetched
        Task {
            await BibleAPIService.shared.reloadTranslations()
        }
    }
    
    private func saveSecondaryTranslation() {
        UserDefaults.standard.set(secondaryTranslation.id, forKey: "secondaryTranslationId")
        UserDefaults.standard.set(secondaryTranslation.languageCode, forKey: "secondaryLanguageCode")
        UserDefaults.standard.set(secondaryTranslation.language, forKey: "secondaryLanguage")
        UserDefaults.standard.set(secondaryTranslation.name, forKey: "secondaryTranslationName")
        
        // Update ViewModel immediately so UI updates
        viewModel.secondaryLanguageCode = secondaryTranslation.languageCode
        
        // Clear API cache so new translation is fetched
        Task {
            await BibleAPIService.shared.reloadTranslations()
        }
    }
    
    // MARK: - Mail Composer
    private func openMailComposer() {
        let subject = isKoreanUI ? "성경 앱 피드백" : "Bible App Feedback"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(contactEmail)?subject=\(encodedSubject)") {
            UIApplication.shared.open(url) { success in
                if !success {
                    mailError = isKoreanUI ? "메일 앱을 열 수 없습니다. \(contactEmail)로 이메일을 보내주세요." : "Unable to open mail app. Please email us at \(contactEmail)"
                }
            }
        }
    }
}

// MARK: - Translation Picker Sheet
struct TranslationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    var cancelLabel: String = "Cancel"
    var saveLabel: String = "Save"
    var searchPlaceholder: String = "Search translations"
    @Binding var selectedTranslation: BibleTranslation
    var onSelect: () -> Void
    
    @State private var searchText = ""
    @State private var availableTranslations: [BibleTranslation] = []
    @State private var isLoading = true
    @State private var tempSelectedTranslation: BibleTranslation? = nil
    
    private var groupedTranslations: [(String, [BibleTranslation])] {
        let filtered = availableTranslations.filter { translation in
            searchText.isEmpty ||
            translation.name.localizedCaseInsensitiveContains(searchText) ||
            translation.shortName.localizedCaseInsensitiveContains(searchText) ||
            translation.id.localizedCaseInsensitiveContains(searchText) ||
            translation.language.localizedCaseInsensitiveContains(searchText)
        }
        
        return Dictionary(grouping: filtered, by: { $0.language })
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0a0a0a")
                    .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Loading translations...")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20, pinnedViews: .sectionHeaders) {
                            ForEach(groupedTranslations, id: \.0) { language, translations in
                                Section {
                                    VStack(spacing: 0) {
                                        ForEach(translations) { translation in
                                            translationRow(translation: translation)
                                            
                                            if translation.id != translations.last?.id {
                                                Divider()
                                                    .background(.white.opacity(0.06))
                                                    .padding(.leading, 16)
                                            }
                                        }
                                    }
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(.white.opacity(0.04))
                                    )
                                    .padding(.horizontal, 20)
                                } header: {
                                    languageSectionHeader(language)
                                }
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: searchPlaceholder)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(cancelLabel) {
                        // Dismiss without saving
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(saveLabel) {
                        // Save the selection and dismiss
                        if let temp = tempSelectedTranslation {
                            selectedTranslation = temp
                            onSelect()
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(hasChanges ? Color(hex: "007AFF") : .white.opacity(0.4))
                    .disabled(!hasChanges)
                }
            }
            .toolbarBackground(Color(hex: "0a0a0a"), for: .navigationBar)
            .task {
                await loadTranslations()
            }
            .onAppear {
                tempSelectedTranslation = selectedTranslation
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var hasChanges: Bool {
        guard let temp = tempSelectedTranslation else { return false }
        return temp.id != selectedTranslation.id
    }
    
    private func loadTranslations() async {
        isLoading = true
        let bollsTranslations = await TranslationService.shared.fetchAvailableTranslations()
        availableTranslations = bollsTranslations.map { TranslationService.shared.toBibleTranslation($0) }
        isLoading = false
    }
    
    private func languageSectionHeader(_ language: String) -> some View {
        HStack {
            Text(language.uppercased())
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
                .kerning(0.8)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Color(hex: "0a0a0a"))
    }
    
    private func translationRow(translation: BibleTranslation) -> some View {
        Button {
            // Update temporary selection only
            tempSelectedTranslation = translation
            HapticManager.shared.selection()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(translation.shortName)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    
                    Text(translation.name)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }
                
                Spacer()
                
                if tempSelectedTranslation?.id == translation.id {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "007AFF"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Voice Picker Sheet
struct VoicePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let isKoreanUI: Bool
    @Binding var selectedVoice: String
    var onSelect: (String) -> Void
    var onPlayDemo: (String) -> Void
    
    // Temporary selection (only saved when "Save" is pressed)
    @State private var tempSelectedVoice: String = ""
    
    // Voice data grouped by gender
    private let femaleVoices = [
        ("nova", "Nova", "밝고 친근한"),
        ("shimmer", "Shimmer", "부드럽고 표현력 있는"),
        ("fable", "Fable", "영국식, 스토리텔링")
    ]
    
    private let maleVoices = [
        ("alloy", "Alloy", "중성적, 균형 잡힌"),
        ("echo", "Echo", "깊고 울림 있는"),
        ("onyx", "Onyx", "깊고 권위 있는")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0a0a0a")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Female voices
                        voiceGroup(
                            title: isKoreanUI ? "여성" : "Female",
                            voices: femaleVoices
                        )
                        
                        // Male voices
                        voiceGroup(
                            title: isKoreanUI ? "남성" : "Male",
                            voices: maleVoices
                        )
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle(isKoreanUI ? "목소리 선택" : "Select Voice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(isKoreanUI ? "취소" : "Cancel") {
                        // Dismiss without saving
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isKoreanUI ? "저장" : "Save") {
                        // Save the selection and dismiss
                        onSelect(tempSelectedVoice)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(tempSelectedVoice != selectedVoice ? Color(hex: "007AFF") : .white.opacity(0.4))
                    .disabled(tempSelectedVoice == selectedVoice)
                }
            }
            .toolbarBackground(Color(hex: "0a0a0a"), for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            tempSelectedVoice = selectedVoice
        }
    }
    
    private func voiceGroup(title: String, voices: [(String, String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
                .kerning(0.8)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                ForEach(Array(voices.enumerated()), id: \.1.0) { index, voice in
                    voiceRow(
                        id: voice.0,
                        name: voice.1,
                        description: voice.2,
                        isLast: index == voices.count - 1
                    )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.04))
            )
        }
    }
    
    private func voiceRow(id: String, name: String, description: String, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Checkmark area (fixed width for alignment)
                Group {
                    if tempSelectedVoice == id {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color(hex: "007AFF"))
                    } else {
                        Color.clear
                    }
                }
                .frame(width: 20)
                
                // Tappable row content (selects voice temporarily)
                Button {
                    HapticManager.shared.selection()
                    tempSelectedVoice = id
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(name)
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                            
                            Text(description)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                // Play button (plays demo only, doesn't select)
                Button {
                    HapticManager.shared.selection()
                    onPlayDemo(id)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, 6)
            
            if !isLast {
                Divider()
                    .background(.white.opacity(0.06))
                    .padding(.leading, 48)  // Align with text after checkmark
            }
        }
    }
}

// MARK: - Legal Text Sheet
struct LegalTextSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let content: String
    let isKoreanUI: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0a0a0a")
                    .ignoresSafeArea()
                
                ScrollView {
                    Text(content)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(6)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 60)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.shared.selection()
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.08))
                                .frame(width: 30, height: 30)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbarBackground(Color(hex: "0a0a0a"), for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    SettingsView(
        languageMode: .constant(.en),
        readingMode: .constant(.tap),
        viewModel: BibleViewModel(),
        onDismiss: {}
    )
}

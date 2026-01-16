import SwiftUI
import MessageUI

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
    @State private var mailError: String?
    @State private var showClearDataConfirmation = false
    @State private var downloadedCount: Int = 0
    
    
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
                        
                        // Offline Downloads Section
                        offlineSection
                        
                        // Reading Section
                        readingSection
                        
                        // About Section
                        aboutSection
                        
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
                searchPlaceholder: isKoreanUI ? "번역 검색" : "Search translations",
                selectedTranslation: $primaryTranslation,
                onSelect: { savePrimaryTranslation() }
            )
        }
        .sheet(isPresented: $showSecondaryPicker) {
            TranslationPickerSheet(
                title: isKoreanUI ? "보조 언어" : "Secondary Language",
                cancelLabel: isKoreanUI ? "취소" : "Cancel",
                searchPlaceholder: isKoreanUI ? "번역 검색" : "Search translations",
                selectedTranslation: $secondaryTranslation,
                onSelect: { saveSecondaryTranslation() }
            )
        }
        .sheet(isPresented: $showOfflineDownloads) {
            OfflineDownloadView(isKoreanUI: isKoreanUI)
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
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.04))
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
    var searchPlaceholder: String = "Search translations"
    @Binding var selectedTranslation: BibleTranslation
    var onSelect: () -> Void
    
    @State private var searchText = ""
    @State private var availableTranslations: [BibleTranslation] = []
    @State private var isLoading = true
    
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
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }
            }
            .toolbarBackground(Color(hex: "0a0a0a"), for: .navigationBar)
            .task {
                await loadTranslations()
            }
        }
        .preferredColorScheme(.dark)
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
            // Update binding first
            selectedTranslation = translation
            HapticManager.shared.selection()
            // Save and dismiss after a small delay to ensure binding is updated
            DispatchQueue.main.async {
                onSelect()
                dismiss()
            }
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
                
                if selectedTranslation.id == translation.id {
                    Text("✓")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "22c55e"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
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

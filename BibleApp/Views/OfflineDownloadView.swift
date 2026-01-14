import SwiftUI

struct OfflineDownloadView: View {
    @Environment(\.dismiss) private var dismiss
    
    var downloadManager = DownloadManager.shared
    let isKoreanUI: Bool
    
    @State private var availableTranslations: [BibleTranslation] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var totalStorageSize: Int64 = 0
    @State private var showDeleteAllConfirmation = false
    
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
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle(isKoreanUI ? "오프라인 다운로드" : "Offline Downloads")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: isKoreanUI ? "번역 검색" : "Search translations")
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
        .task {
            await loadTranslations()
            await refreshStorageInfo()
        }
        .alert(isKoreanUI ? "모든 다운로드 삭제" : "Delete All Downloads", isPresented: $showDeleteAllConfirmation) {
            Button(isKoreanUI ? "취소" : "Cancel", role: .cancel) { }
            Button(isKoreanUI ? "삭제" : "Delete", role: .destructive) {
                Task {
                    try? await OfflineStorageService.shared.deleteAllDownloads()
                    await downloadManager.refreshDownloadedTranslations()
                    await refreshStorageInfo()
                }
            }
        } message: {
            Text(isKoreanUI ? "모든 오프라인 성경 데이터가 삭제됩니다." : "All offline Bible data will be deleted.")
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Text(isKoreanUI ? "번역 목록 로딩 중..." : "Loading translations...")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 20, pinnedViews: .sectionHeaders) {
                // Storage Info Header
                storageInfoSection
                
                // Translation List
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
    
    private var storageInfoSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isKoreanUI ? "저장 공간" : "Storage Used")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text(OfflineStorageService.shared.formatSize(totalStorageSize))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                if totalStorageSize > 0 {
                    Button {
                        HapticManager.shared.selection()
                        showDeleteAllConfirmation = true
                    } label: {
                        Text(isKoreanUI ? "모두 삭제" : "Delete All")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "ef4444"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color(hex: "ef4444").opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.04))
            )
            .padding(.horizontal, 20)
            
            // Info text
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))
                
                Text(isKoreanUI ? "다운로드한 번역본은 오프라인에서도 읽을 수 있습니다." : "Downloaded translations can be read offline.")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
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
        let state = downloadManager.getState(for: translation.id)
        let size = downloadManager.translationSizes[translation.id]
        
        return HStack(spacing: 12) {
            // Translation Info
            VStack(alignment: .leading, spacing: 2) {
                Text(translation.shortName)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                
                HStack(spacing: 6) {
                    Text(translation.name)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                    
                    if let size = size, size > 0 {
                        Text("• \(OfflineStorageService.shared.formatSize(size))")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }
            
            Spacer()
            
            // Download Button / Progress
            downloadButton(for: translation, state: state)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    private func downloadButton(for translation: BibleTranslation, state: DownloadState) -> some View {
        switch state {
        case .idle:
            Button {
                HapticManager.shared.selection()
                downloadManager.startDownload(translationId: translation.id)
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(hex: "3b82f6"))
            }
            .buttonStyle(.plain)
            
        case .downloading(let progress, _, _):
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 2)
                    .frame(width: 22, height: 22)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color(hex: "3b82f6"), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 22, height: 22)
                    .rotationEffect(.degrees(-90))
                
                Button {
                    HapticManager.shared.selection()
                    downloadManager.cancelDownload(translationId: translation.id)
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(hex: "3b82f6"))
                }
                .buttonStyle(.plain)
            }
            .offset(x: -3)
            
        case .paused(let progress):
            Button {
                HapticManager.shared.selection()
                downloadManager.resumeDownload(translationId: translation.id)
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.1), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color(hex: "f59e0b"), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 22, height: 22)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(hex: "f59e0b"))
                }
            }
            .buttonStyle(.plain)
            .offset(x: -3)
            
        case .completed:
            Menu {
                Button(role: .destructive) {
                    Task {
                        await downloadManager.deleteDownload(translationId: translation.id)
                        await refreshStorageInfo()
                    }
                } label: {
                    Label(isKoreanUI ? "삭제" : "Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(hex: "22c55e"))
            }
            
        case .failed(let error):
            Button {
                HapticManager.shared.selection()
                downloadManager.startDownload(translationId: translation.id)
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(hex: "ef4444"))
                    
                    Text(isKoreanUI ? "재시도" : "Retry")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadTranslations() async {
        isLoading = true
        let bollsTranslations = await TranslationService.shared.fetchAvailableTranslations()
        availableTranslations = bollsTranslations.map { TranslationService.shared.toBibleTranslation($0) }
        isLoading = false
    }
    
    private func refreshStorageInfo() async {
        totalStorageSize = await downloadManager.getTotalStorageSize()
    }
}

#Preview {
    OfflineDownloadView(isKoreanUI: true)
}

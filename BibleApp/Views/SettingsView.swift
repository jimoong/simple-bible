import SwiftUI
import MessageUI

struct SettingsView: View {
    @Binding var languageMode: LanguageMode
    var onDismiss: () -> Void
    
    // MARK: - State
    @State private var primaryTranslation: BibleTranslation = .krv
    @State private var secondaryTranslation: BibleTranslation = .kjv
    @State private var showPrimaryPicker: Bool = false
    @State private var showSecondaryPicker: Bool = false
    @State private var mailError: String?
    
    private let appVersion = "1.0.0"
    private let contactEmail = "jiwoong.net@gmail.com"
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0a0a0a")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        // Languages Section
                        languagesSection
                        
                        // About Section
                        aboutSection
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Settings")
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
                title: "Primary Language",
                selectedTranslation: $primaryTranslation,
                onSelect: { savePrimaryTranslation() }
            )
        }
        .sheet(isPresented: $showSecondaryPicker) {
            TranslationPickerSheet(
                title: "Secondary Language",
                selectedTranslation: $secondaryTranslation,
                onSelect: { saveSecondaryTranslation() }
            )
        }
        .alert("Mail Error", isPresented: .constant(mailError != nil)) {
            Button("OK") { mailError = nil }
        } message: {
            Text(mailError ?? "")
        }
    }
    
    // MARK: - Languages Section
    private var languagesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Languages")
            
            VStack(spacing: 0) {
                // Primary Language
                Button {
                    HapticManager.shared.selection()
                    showPrimaryPicker = true
                } label: {
                    HStack {
                        Text("\(primaryTranslation.language) (Primary)")
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
                        Text("\(secondaryTranslation.language) (Secondary)")
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
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "About")
            
            VStack(spacing: 0) {
                // Version
                HStack {
                    Text("Version")
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
                        Text("Contact")
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
        if let primaryId = UserDefaults.standard.string(forKey: "primaryTranslationId"),
           let translation = BibleTranslation.allTranslations.first(where: { $0.id == primaryId }) {
            primaryTranslation = translation
        }
        
        if let secondaryId = UserDefaults.standard.string(forKey: "secondaryTranslationId"),
           let translation = BibleTranslation.allTranslations.first(where: { $0.id == secondaryId }) {
            secondaryTranslation = translation
        }
    }
    
    private func savePrimaryTranslation() {
        UserDefaults.standard.set(primaryTranslation.id, forKey: "primaryTranslationId")
    }
    
    private func saveSecondaryTranslation() {
        UserDefaults.standard.set(secondaryTranslation.id, forKey: "secondaryTranslationId")
    }
    
    // MARK: - Mail Composer
    private func openMailComposer() {
        let subject = "Bible App Feedback"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(contactEmail)?subject=\(encodedSubject)") {
            UIApplication.shared.open(url) { success in
                if !success {
                    mailError = "Unable to open mail app. Please email us at \(contactEmail)"
                }
            }
        }
    }
}

// MARK: - Translation Picker Sheet
struct TranslationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    @Binding var selectedTranslation: BibleTranslation
    var onSelect: () -> Void
    
    @State private var searchText = ""
    
    private var groupedTranslations: [(String, [BibleTranslation])] {
        let filtered = BibleTranslation.allTranslations.filter { translation in
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
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search translations")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }
            }
            .toolbarBackground(Color(hex: "0a0a0a"), for: .navigationBar)
        }
        .preferredColorScheme(.dark)
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
            selectedTranslation = translation
            onSelect()
            HapticManager.shared.selection()
            dismiss()
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
        onDismiss: {}
    )
}

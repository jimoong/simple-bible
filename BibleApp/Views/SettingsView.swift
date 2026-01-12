import SwiftUI

struct SettingsView: View {
    @Binding var languageMode: LanguageMode
    var theme: BookTheme
    var onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                theme.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Language Section
                        settingsSection(title: "Language") {
                            languageRow
                        }
                        
                        // Bible Versions Section (placeholder for future)
                        settingsSection(title: "Bible Versions") {
                            versionRow(label: "English", version: "KJV", sublabel: "King James Version")
                            versionRow(label: "Korean", version: "KRV", sublabel: "개역한글")
                        }
                        
                        // About Section
                        settingsSection(title: "About") {
                            infoRow(label: "Version", value: "1.0.0")
                        }
                        
                        Spacer(minLength: 60)
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
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }
            .toolbarBackground(theme.background, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Section Container
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.textSecondary.opacity(0.6))
            
            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.textPrimary.opacity(0.06))
            )
        }
    }
    
    // MARK: - Language Row
    private var languageRow: some View {
        HStack {
            Text("Display Language")
                .font(.system(size: 16))
                .foregroundStyle(theme.textPrimary)
            
            Spacer()
            
            // Segmented control style
            HStack(spacing: 0) {
                ForEach(LanguageMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            languageMode = mode
                        }
                        HapticManager.shared.selection()
                    } label: {
                        Text(mode.displayName)
                            .font(.system(size: 14, weight: languageMode == mode ? .semibold : .regular))
                            .foregroundStyle(languageMode == mode ? theme.background : theme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(languageMode == mode ? theme.textPrimary : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                Capsule()
                    .fill(theme.textPrimary.opacity(0.1))
            )
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - Version Row
    private func versionRow(label: String, version: String, sublabel: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 16))
                    .foregroundStyle(theme.textPrimary)
                
                Text(sublabel)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.textSecondary.opacity(0.7))
            }
            
            Spacer()
            
            Text(version)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(theme.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(theme.accent.opacity(0.15))
                )
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Info Row
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(theme.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15))
                .foregroundStyle(theme.textSecondary)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    SettingsView(
        languageMode: .constant(.en),
        theme: BookThemes.genesis,
        onDismiss: {}
    )
}

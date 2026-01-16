import SwiftUI

/// Morphing menu button - transforms from FAB into a menu panel
struct ExpandableFAB: View {
    @Binding var languageMode: LanguageMode
    @Binding var readingMode: ReadingMode
    var theme: BookTheme
    var primaryLanguageCode: String = "ko"
    var secondaryLanguageCode: String = "en"
    var uiLanguage: LanguageMode = .kr  // Current UI language based on active display
    var onLanguageToggle: () -> Void
    var onReadingModeToggle: () -> Void
    var onSettings: () -> Void
    var onListening: () -> Void = {}  // New: listening mode callback
    @Binding var isExpanded: Bool
    var isHidden: Bool = false
    var useBlurBackground: Bool = false
    
    @ObservedObject private var fontSizeSettings = FontSizeSettings.shared
    
    private var buttonFontSize: CGFloat {
        fontSizeSettings.mode.buttonLabelSize
    }
    
    // Layout
    private let collapsedSize: CGFloat = 52
    private let expandedWidth: CGFloat = 210  // Larger - left buttons hidden when expanded
    private let menuItemHeight: CGFloat = 48  // Taller items
    private let menuPadding: CGFloat = 8
    
    private var menuItemCount: Int { 4 } // Settings + Listening + Reading Mode + Language
    
    private var expandedHeight: CGFloat {
        CGFloat(menuItemCount) * menuItemHeight + menuPadding * 2
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Morphing container + content
            if !isHidden {
                morphingMenu
            }
        }
    }
    
    // MARK: - Morphing Menu
    private var morphingMenu: some View {
        ZStack(alignment: isExpanded ? .top : .center) {
            // Glass background that morphs
            glassBackground
            
            // Content
                if isExpanded {
                // Menu items
                VStack(spacing: 0) {
                    // Settings (closes menu)
                    // Use UI language based on currently active display language
                    let isKoreanUI = uiLanguage == .kr
                    menuItem(icon: "gear", label: isKoreanUI ? "설정" : "Settings") {
                        onSettings()
                        closeMenu()
                    }
                    
                    // Listening mode (closes menu and enters listening mode)
                    menuItem(icon: "play.fill", label: isKoreanUI ? "듣기" : "Listen") {
                        onListening()
                        closeMenu()
                    }
                    
                    // Reading mode toggle (doesn't close menu)
                    readingModeToggleItem
                    
                    // Language toggle (doesn't close menu)
                    languageToggleItem
                }
                .padding(.vertical, menuPadding)
                .padding(.horizontal, menuPadding) // even padding on all sides
                .transition(.opacity.animation(.easeOut(duration: 0.15).delay(0.1)))
            } else {
                // FAB icon
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .transition(.opacity.animation(.easeOut(duration: 0.1)))
            }
        }
        .frame(
            width: isExpanded ? expandedWidth : collapsedSize,
            height: isExpanded ? expandedHeight : collapsedSize
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: isExpanded ? 32 : collapsedSize / 2,
                style: .continuous
            )
        )
        .onTapGesture {
            if !isExpanded {
                openMenu()
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isExpanded)
    }
    
    // MARK: - Glass Background
    @ViewBuilder
    private var glassBackground: some View {
        if useBlurBackground {
            RoundedRectangle(
                cornerRadius: isExpanded ? 32 : collapsedSize / 2,
                style: .continuous
            )
            .fill(.regularMaterial)
            .environment(\.colorScheme, .dark)
            .overlay(
                RoundedRectangle(
                    cornerRadius: isExpanded ? 32 : collapsedSize / 2,
                    style: .continuous
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
            .shadow(
                color: .black.opacity(isExpanded ? 0.25 : 0.15),
                radius: isExpanded ? 16 : 6,
                y: isExpanded ? 6 : 3
            )
        } else {
            RoundedRectangle(
                cornerRadius: isExpanded ? 32 : collapsedSize / 2,
                style: .continuous
            )
            .fill(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(
                    cornerRadius: isExpanded ? 32 : collapsedSize / 2,
                    style: .continuous
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
            .shadow(
                color: .black.opacity(isExpanded ? 0.20 : 0.12),
                radius: isExpanded ? 12 : 4,
                y: isExpanded ? 6 : 2
            )
        }
    }
    
    // MARK: - Menu Item (standard - closes menu on tap)
    private func menuItem(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            HapticManager.shared.selection()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 24)
                
                Text(label)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.9))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: menuItemHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuItemButtonStyle())
    }
    
    // MARK: - Reading Mode Toggle Item (doesn't close menu)
    private var readingModeToggleItem: some View {
        let isKoreanUI = uiLanguage == .kr
        
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                onReadingModeToggle()
            }
            HapticManager.shared.selection()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "hand.point.up")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 24)
                
                // Toggle indicator - uses UI language
                HStack(spacing: 6) {
                    Text(isKoreanUI ? "탭" : "Tap")
                        .font(.system(size: 17, weight: readingMode == .tap ? .semibold : .regular))
                        .foregroundStyle(readingMode == .tap ? .white : .white.opacity(0.4))
                    
                    Text("/")
                        .font(.system(size: 17))
                        .foregroundStyle(.white.opacity(0.25))
                    
                    Text(isKoreanUI ? "스크롤" : "Scroll")
                        .font(.system(size: 17, weight: readingMode == .scroll ? .semibold : .regular))
                        .foregroundStyle(readingMode == .scroll ? .white : .white.opacity(0.4))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: menuItemHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuItemButtonStyle())
    }
    
    // MARK: - Language Toggle Item (doesn't close menu)
    private var languageToggleItem: some View {
        // Primary text is in textKr slot, shown when languageMode == .kr
        // Secondary text is in textEn slot, shown when languageMode == .en
        let isPrimaryActive = languageMode == .kr
        let isKoreanUI = uiLanguage == .kr  // UI Korean based on currently active language
        
        let primaryDisplay = LanguageDisplay.displayCode(for: primaryLanguageCode, inKorean: isKoreanUI)
        let secondaryDisplay = LanguageDisplay.displayCode(for: secondaryLanguageCode, inKorean: isKoreanUI)
        
        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                onLanguageToggle()
            }
            HapticManager.shared.selection()
            // Note: Does NOT close menu
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 24)
                
                // Toggle indicator
                HStack(spacing: 6) {
                    Text(primaryDisplay)
                        .font(.system(size: 17, weight: isPrimaryActive ? .semibold : .regular))
                        .foregroundStyle(isPrimaryActive ? .white : .white.opacity(0.4))
                    
                    Text("/")
                        .font(.system(size: 17))
                        .foregroundStyle(.white.opacity(0.25))
                    
                    Text(secondaryDisplay)
                        .font(.system(size: 17, weight: !isPrimaryActive ? .semibold : .regular))
                        .foregroundStyle(!isPrimaryActive ? .white : .white.opacity(0.4))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: menuItemHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuItemButtonStyle())
    }
    
    // MARK: - Helpers
    private func openMenu() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            isExpanded = true
        }
        HapticManager.shared.selection()
    }
    
    private func closeMenu() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
            isExpanded = false
        }
    }
}

// MARK: - Menu Item Button Style
private struct MenuItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Capsule()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0))
            )
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var languageMode: LanguageMode = .en
        @State private var readingMode: ReadingMode = .tap
        @State private var isExpanded = false
        
        var body: some View {
            ZStack {
                BookThemes.genesis.background
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ExpandableFAB(
                            languageMode: $languageMode,
                            readingMode: $readingMode,
                            theme: BookThemes.genesis,
                            uiLanguage: .en,
                            onLanguageToggle: { print("Toggle language") },
                            onReadingModeToggle: { print("Toggle reading mode") },
                            onSettings: { print("Open settings") },
                            onListening: { print("Open listening mode") },
                            isExpanded: $isExpanded
                        )
                        .padding(24)
                    }
                }
            }
        }
    }
    return PreviewWrapper()
}

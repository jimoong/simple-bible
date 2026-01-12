import SwiftUI

/// Morphing menu button - transforms from FAB into a menu panel
struct ExpandableFAB: View {
    @Binding var languageMode: LanguageMode
    var theme: BookTheme
    var onLanguageToggle: () -> Void
    var onSettings: () -> Void
    
    @State private var isExpanded = false
    
    // Layout
    private let collapsedSize: CGFloat = 52
    private let expandedWidth: CGFloat = 180
    private let menuItemHeight: CGFloat = 48
    private let menuPadding: CGFloat = 8
    
    private var menuItemCount: Int { 2 } // Settings + Language
    
    private var expandedHeight: CGFloat {
        CGFloat(menuItemCount) * menuItemHeight + menuPadding * 2
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Tap-outside overlay to close (only when expanded)
            if isExpanded {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        closeMenu()
                    }
                    .ignoresSafeArea()
            }
            
            // Morphing container + content
            morphingMenu
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
                    menuItem(icon: "gearshape.fill", label: "Settings") {
                        onSettings()
                        closeMenu()
                    }
                    
                    // Language toggle (doesn't close menu)
                    languageToggleItem
                }
                .padding(.vertical, menuPadding)
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
                cornerRadius: isExpanded ? 20 : collapsedSize / 2,
                style: .continuous
            )
        )
        .onTapGesture {
            if !isExpanded {
                openMenu()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.65), value: isExpanded)
    }
    
    // MARK: - Glass Background
    private var glassBackground: some View {
        RoundedRectangle(
            cornerRadius: isExpanded ? 20 : collapsedSize / 2,
            style: .continuous
        )
        .fill(Color.white.opacity(0.08))
        .overlay(
            RoundedRectangle(
                cornerRadius: isExpanded ? 20 : collapsedSize / 2,
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
            color: .black.opacity(isExpanded ? 0.15 : 0.12),
            radius: isExpanded ? 8 : 4,
            y: isExpanded ? 4 : 2
        )
    }
    
    // MARK: - Menu Item (standard - closes menu on tap)
    private func menuItem(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            HapticManager.shared.selection()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 24)
                
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                
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
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                onLanguageToggle()
            }
            HapticManager.shared.selection()
            // Note: Does NOT close menu
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 24)
                
                // Toggle indicator
                HStack(spacing: 6) {
                    Text("EN")
                        .font(.system(size: 16, weight: languageMode == .en ? .bold : .regular))
                        .foregroundStyle(languageMode == .en ? .white : .white.opacity(0.4))
                    
                    Text("/")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.25))
                    
                    Text("KR")
                        .font(.system(size: 16, weight: languageMode == .kr ? .bold : .regular))
                        .foregroundStyle(languageMode == .kr ? .white : .white.opacity(0.4))
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
        withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
            isExpanded = true
        }
        HapticManager.shared.selection()
    }
    
    private func closeMenu() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            isExpanded = false
        }
        HapticManager.shared.selection()
    }
}

// MARK: - Menu Item Button Style
private struct MenuItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.1 : 0))
            )
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        BookThemes.genesis.background
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                ExpandableFAB(
                    languageMode: .constant(.en),
                    theme: BookThemes.genesis,
                    onLanguageToggle: { print("Toggle language") },
                    onSettings: { print("Open settings") }
                )
                .padding(24)
            }
        }
    }
}

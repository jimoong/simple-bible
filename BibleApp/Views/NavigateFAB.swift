import SwiftUI

/// Expandable navigation button - transforms from FAB into a menu panel
/// Mirror behavior of ExpandableFAB for consistency
struct NavigateFAB: View {
    var theme: BookTheme
    var onBookshelf: () -> Void
    var onVoiceSearch: () -> Void
    @Binding var isExpanded: Bool
    var isHidden: Bool = false
    
    // Layout
    private let collapsedSize: CGFloat = 52
    private let expandedWidth: CGFloat = 180
    private let menuItemHeight: CGFloat = 48
    private let menuPadding: CGFloat = 8
    
    private var menuItemCount: Int { 2 } // Bookshelf + Voice
    
    private var expandedHeight: CGFloat {
        CGFloat(menuItemCount) * menuItemHeight + menuPadding * 2
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
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
                    // Voice search
                    menuItem(icon: "mic.fill", label: "Voice") {
                        onVoiceSearch()
                        closeMenu()
                    }
                    
                    // Bookshelf
                    menuItem(icon: "books.vertical", label: "Books") {
                        onBookshelf()
                        closeMenu()
                    }
                }
                .padding(.vertical, menuPadding)
                .padding(.horizontal, menuPadding)
                .transition(.opacity.animation(.easeOut(duration: 0.15).delay(0.1)))
            } else {
                // FAB icon - location icon
                Image(systemName: "location")
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
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isExpanded)
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
    
    // MARK: - Menu Item
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
        .buttonStyle(NavigateMenuItemButtonStyle())
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
private struct NavigateMenuItemButtonStyle: ButtonStyle {
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
    struct PreviewWrapper: View {
        @State private var isExpanded = false
        
        var body: some View {
            ZStack {
                BookThemes.genesis.background
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    HStack {
                        NavigateFAB(
                            theme: BookThemes.genesis,
                            onBookshelf: { print("Open bookshelf") },
                            onVoiceSearch: { print("Open voice search") },
                            isExpanded: $isExpanded
                        )
                        .padding(24)
                        Spacer()
                    }
                }
            }
        }
    }
    return PreviewWrapper()
}

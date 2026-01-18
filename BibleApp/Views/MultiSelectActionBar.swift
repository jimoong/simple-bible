//
//  MultiSelectActionBar.swift
//  BibleApp
//
//  Bottom action bar for multi-select mode
//

import SwiftUI

struct MultiSelectActionBar: View {
    let selectedCount: Int
    let languageMode: LanguageMode
    var useBlurBackground: Bool = false
    var onSave: () -> Void
    var onAsk: () -> Void
    var onClose: () -> Void
    
    private var hasSelection: Bool {
        selectedCount > 0
    }
    
    private var centerText: String {
        if selectedCount == 0 {
            return ""
        }
        
        if languageMode == .kr {
            return "\(selectedCount)절 선택됨"
        } else {
            return "\(selectedCount) selected"
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Save button (left)
            actionButton(icon: "heart") {
                onSave()
            }
            .opacity(hasSelection ? 1.0 : 0.6)
            .disabled(!hasSelection)
            
            Spacer()
            
            // Center: Counter or close button
            Button {
                onClose()
            } label: {
                if hasSelection {
                    // Counter with X
                    HStack(spacing: 6) {
                        Text(centerText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(centerButtonCapsuleBackground)
                } else {
                    // Just X icon
                    ZStack {
                        buttonBackground
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 48, height: 48)
                }
            }
            .buttonStyle(PlainButtonPressStyle())
            
            Spacer()
            
            // Ask button (right)
            actionButton(icon: "sparkle") {
                onAsk()
            }
            .opacity(hasSelection ? 1.0 : 0.6)
            .disabled(!hasSelection)
        }
    }
    
    @ViewBuilder
    private func actionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                buttonBackground
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(BookshelfButtonStyle())
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        if useBlurBackground {
            Circle()
                .fill(.regularMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    Circle()
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
                    color: .black.opacity(0.15),
                    radius: 6,
                    y: 3
                )
        } else {
            Circle()
                .fill(Color.white.opacity(0.08))
                .overlay(
                    Circle()
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
                    color: .black.opacity(0.12),
                    radius: 4,
                    y: 2
                )
        }
    }
    
    @ViewBuilder
    private var centerButtonCapsuleBackground: some View {
        if useBlurBackground {
            Capsule(style: .continuous)
                .fill(.regularMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    Capsule(style: .continuous)
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
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        } else {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    Capsule(style: .continuous)
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
                .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
        }
    }
}

// MARK: - Plain Button Press Style

private struct PlainButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("No Selection") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            MultiSelectActionBar(
                selectedCount: 0,
                languageMode: .kr,
                onSave: {},
                onAsk: {},
                onClose: {}
            )
            .padding(.horizontal, 28)
            .padding(.bottom, 34)
        }
    }
}

#Preview("With Selection") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            Spacer()
            MultiSelectActionBar(
                selectedCount: 3,
                languageMode: .kr,
                onSave: {},
                onAsk: {},
                onClose: {}
            )
            .padding(.horizontal, 28)
            .padding(.bottom, 34)
        }
    }
}

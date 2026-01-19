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
    var onNoSelectionTap: (() -> Void)? = nil  // Called when tapping buttons with no selection
    
    private var hasSelection: Bool {
        selectedCount > 0
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Save and Ask button group with labels
            HStack(spacing: 8) {
                // Save button with label
                labeledButton(
                    icon: "heart",
                    label: languageMode == .kr ? "저장" : "Save"
                ) {
                    if hasSelection {
                        onSave()
                    } else {
                        onNoSelectionTap?()
                    }
                }
                
                // Ask button with label
                labeledButton(
                    icon: "sparkle",
                    label: languageMode == .kr ? "물어보기" : "Ask"
                ) {
                    if hasSelection {
                        onAsk()
                    } else {
                        onNoSelectionTap?()
                    }
                }
            }
            
            Spacer()
            
            // Right: Done button (checkmark, 48x48)
            Button {
                onClose()
            } label: {
                ZStack {
                    buttonBackground
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 48, height: 48)
            }
            .buttonStyle(PlainButtonPressStyle())
        }
    }
    
    @ViewBuilder
    private func labeledButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(capsuleBackground)
        }
        .buttonStyle(PlainButtonPressStyle())
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
    private var capsuleBackground: some View {
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

import SwiftUI

/// Simple bookshelf navigation button - directly opens bookshelf on tap
struct NavigateFAB: View {
    var theme: BookTheme
    var onBookshelf: () -> Void
    var isHidden: Bool = false
    var useBlurBackground: Bool = false
    
    private let buttonSize: CGFloat = 52
    
    var body: some View {
        if !isHidden {
            Button {
                onBookshelf()
                HapticManager.shared.selection()
            } label: {
                ZStack {
                    glassBackground
                    
                    Image(systemName: "books.vertical")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: buttonSize, height: buttonSize)
            }
            .buttonStyle(BookshelfButtonStyle())
        }
    }
    
    // MARK: - Glass Background
    @ViewBuilder
    private var glassBackground: some View {
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
}

// MARK: - Bookshelf Button Style
struct BookshelfButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
                NavigateFAB(
                    theme: BookThemes.genesis,
                    onBookshelf: { print("Open bookshelf") }
                )
                .padding(24)
                Spacer()
            }
        }
    }
}

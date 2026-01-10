import SwiftUI

struct ContentView: View {
    @State private var viewModel = BibleViewModel()
    
    private var theme: BookTheme {
        viewModel.currentTheme
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main slot machine view
                SlotMachineView(viewModel: viewModel)
                
                // Floating controls at bottom - flush to bottom
                VStack {
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        languageToggleButton
                        Spacer()
                        navigationButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .sheet(isPresented: $viewModel.showBookshelf) {
            BookshelfOverlay(viewModel: viewModel)
        }
    }
    
    // MARK: - Language Toggle Button
    private var languageToggleButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                viewModel.toggleLanguage()
            }
        } label: {
            HStack(spacing: 4) {
                Text("EN")
                    .fontWeight(viewModel.languageMode == .en ? .bold : .regular)
                    .foregroundStyle(viewModel.languageMode == .en ? theme.textPrimary : theme.textSecondary.opacity(0.5))
                
                Text("/")
                    .foregroundStyle(theme.textSecondary.opacity(0.3))
                
                Text("KR")
                    .fontWeight(viewModel.languageMode == .kr ? .bold : .regular)
                    .foregroundStyle(viewModel.languageMode == .kr ? theme.textPrimary : theme.textSecondary.opacity(0.5))
            }
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                Capsule()
                    .stroke(theme.textPrimary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.3), value: viewModel.currentBook.id)
    }
    
    // MARK: - Navigation Button
    private var navigationButton: some View {
        Button {
            viewModel.openBookshelf()
        } label: {
            Image(systemName: "text.book.closed")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(theme.textPrimary)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    Circle()
                        .stroke(theme.textPrimary.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.3), value: viewModel.currentBook.id)
    }
}

#Preview {
    ContentView()
}

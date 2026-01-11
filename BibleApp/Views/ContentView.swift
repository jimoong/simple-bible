import SwiftUI

struct ContentView: View {
    @State private var viewModel = BibleViewModel()
    @State private var searchText: String = ""
    @FocusState private var isSearchFieldFocused: Bool
    
    private var theme: BookTheme {
        viewModel.currentTheme
    }
    
    // Dynamic sheet height: full screen for Books view, 60% for Book (chapter) view
    private var isFullScreen: Bool {
        viewModel.selectedBookForChapter == nil
    }
    
    var body: some View {
        GeometryReader { geometry in
            let halfSheetHeight = geometry.size.height * 0.6
            let fullHeight = geometry.size.height + geometry.safeAreaInsets.top
            let sheetHeight = isFullScreen ? fullHeight : halfSheetHeight
            
            ZStack {
                // Main slot machine view
                SlotMachineView(viewModel: viewModel)
                
                // Dimmed background - tap to dismiss (only when not full screen)
                if viewModel.showBookshelf && !isFullScreen {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            dismissBookshelf()
                        }
                        .zIndex(1)
                }
                
                // Bookshelf overlay (dynamic height sheet from bottom)
                if viewModel.showBookshelf {
                    VStack {
                        if !isFullScreen {
                            Spacer()
                        }
                        
                        BookshelfOverlay(
                            viewModel: viewModel,
                            searchText: $searchText,
                            onDismiss: { dismissBookshelf() }
                        )
                        .frame(height: isFullScreen ? nil : sheetHeight)
                        .frame(maxHeight: isFullScreen ? .infinity : nil)
                        .clipShape(RoundedRectangle(cornerRadius: isFullScreen ? 0 : 20, style: .continuous))
                        .shadow(color: isFullScreen ? .clear : .black.opacity(0.3), radius: 20, y: -5)
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
                }
                
                // Floating controls at bottom - always on top
                VStack {
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        leftActionButton
                        Spacer()
                        languageToggleButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 8)
                }
                .ignoresSafeArea(edges: .bottom)
                .zIndex(3)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.showBookshelf)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isFullScreen)
        }
    }
    
    private func dismissBookshelf() {
        viewModel.isSearchActive = false
        searchText = ""
        isSearchFieldFocused = false
        viewModel.dismissBookshelf()
        HapticManager.shared.selection()
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
            .font(.system(size: 17, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.regularMaterial)
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
    
    // MARK: - Context-Aware Left Action Button
    @ViewBuilder
    private var leftActionButton: some View {
        if !viewModel.showBookshelf {
            // Reading view → Bookshelf button
            actionButton(icon: "text.book.closed") {
                viewModel.openBookshelf()
            }
        } else if viewModel.selectedBookForChapter != nil {
            // Chapter view → Back to Books button
            actionButton(icon: "books.vertical") {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.selectedBookForChapter = nil
                }
                HapticManager.shared.selection()
            }
        } else if viewModel.isSearchActive {
            // Books view → Search input field (replaces button)
            searchInputField
        } else {
            // Books view → Search button
            actionButton(icon: "magnifyingglass") {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.isSearchActive = true
                }
                HapticManager.shared.selection()
            }
        }
    }
    
    // MARK: - Search Input Field
    private var searchInputField: some View {
        HStack(spacing: 8) {
            TextField("Search", text: $searchText)
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .focused($isSearchFieldFocused)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.isSearchActive = false
                    searchText = ""
                    isSearchFieldFocused = false
                }
            } label: {
                Text("Cancel")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.regularMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            isSearchFieldFocused = true
        }
    }
    
    private func actionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(.regularMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}

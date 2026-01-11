import SwiftUI

struct BookshelfOverlay: View {
    @Bindable var viewModel: BibleViewModel
    @Binding var searchText: String
    var onDismiss: () -> Void
    
    @State private var isClosing: Bool = false
    @State private var dragOffset: CGFloat = 0
    
    private let dismissThreshold: CGFloat = 100
    
    private var isFullScreen: Bool {
        viewModel.selectedBookForChapter == nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator (only show in half-sheet mode)
            if !isFullScreen {
                dragIndicator
            }
            
            // Content
            ZStack {
                Color.black
                
                if viewModel.selectedBookForChapter != nil {
                    // Chapter selection view
                    ChapterGridView(
                        viewModel: viewModel,
                        currentBook: $viewModel.selectedBookForChapter,
                        onDismiss: {
                            viewModel.selectedBookForChapter = nil
                        },
                        onClose: {
                            closeWithFade()
                        },
                        onChapterSelect: { book, chapter in
                            closeWithFade {
                                Task {
                                    await viewModel.navigateTo(book: book, chapter: chapter)
                                }
                            }
                        }
                    )
                    .transition(.opacity)
                } else {
                    // Book selection view
                    BooksNavigationView(
                        viewModel: viewModel,
                        searchText: $searchText,
                        onClose: { closeWithFade() }
                    )
                    .transition(.opacity)
                }
            }
        }
        .background(Color.black)
        .offset(y: dragOffset)
        .opacity(isClosing ? 0 : 1)
        .animation(.easeOut(duration: 0.25), value: viewModel.selectedBookForChapter)
        .gesture(swipeDownGesture)
    }
    
    // MARK: - Drag Indicator
    private var dragIndicator: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Swipe Down Gesture
    private var swipeDownGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                // Only allow dragging down when drag is more vertical than horizontal
                if value.translation.height > 0 && abs(value.translation.height) > abs(value.translation.width) {
                    dragOffset = value.translation.height
                }
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height - value.translation.height
                
                if value.translation.height > dismissThreshold || velocity > 500 {
                    // Dismiss
                    closeWithFade()
                } else {
                    // Snap back
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }
    
    private func closeWithFade(then action: (() -> Void)? = nil) {
        withAnimation(.easeOut(duration: 0.1)) {
            isClosing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onDismiss()
            action?()
        }
    }
}

// MARK: - Books Navigation View
private struct BooksNavigationView: View {
    @Bindable var viewModel: BibleViewModel
    @Binding var searchText: String
    let onClose: () -> Void
    
    var body: some View {
        NavigationStack {
            BookGridView(viewModel: viewModel, searchText: $searchText)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Books")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            onClose()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                    }
                }
                .toolbarBackground(.black, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        BookshelfOverlay(viewModel: BibleViewModel(), searchText: .constant(""), onDismiss: {})
    }
}

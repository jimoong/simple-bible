import SwiftUI

struct BookshelfOverlay: View {
    @Bindable var viewModel: BibleViewModel
    @Binding var searchText: String
    @State private var isClosing: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.selectedBookForChapter != nil {
                // Chapter selection view - full takeover
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
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // Book selection view
                BooksNavigationView(
                    viewModel: viewModel,
                    searchText: $searchText,
                    onClose: { closeWithFade() }
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .opacity(isClosing ? 0 : 1)
        .animation(.easeOut(duration: 0.25), value: viewModel.selectedBookForChapter)
    }
    
    private func closeWithFade(then action: (() -> Void)? = nil) {
        withAnimation(.easeOut(duration: 0.1)) {
            isClosing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewModel.dismissBookshelf()
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
        BookshelfOverlay(viewModel: BibleViewModel(), searchText: .constant(""))
    }
}

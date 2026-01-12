import SwiftUI

struct BookshelfOverlay: View {
    @Bindable var viewModel: BibleViewModel
    @Binding var searchText: String
    var maxHeight: CGFloat
    var safeAreaTop: CGFloat = 0
    var onDismiss: () -> Void
    
    var body: some View {
        Group {
            if viewModel.selectedBookForChapter != nil {
                // Chapter selection view
                ChapterGridView(
                    viewModel: viewModel,
                    currentBook: $viewModel.selectedBookForChapter,
                    maxHeight: maxHeight,
                    safeAreaTop: safeAreaTop,
                    onChapterSelect: { book, chapter in
                        onDismiss()
                        Task {
                            await viewModel.navigateTo(book: book, chapter: chapter)
                        }
                    }
                )
                .transition(.opacity)
            } else {
                // Book selection view
                BookGridView(
                    viewModel: viewModel,
                    searchText: $searchText,
                    maxHeight: maxHeight,
                    safeAreaTop: safeAreaTop
                )
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: viewModel.selectedBookForChapter)
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            BookshelfOverlay(viewModel: BibleViewModel(), searchText: .constant(""), maxHeight: 400, safeAreaTop: 59, onDismiss: {})
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }
}

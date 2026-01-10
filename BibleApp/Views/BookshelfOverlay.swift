import SwiftUI

struct BookshelfOverlay: View {
    @Bindable var viewModel: BibleViewModel
    @State private var searchText: String = ""
    
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
                        viewModel.dismissBookshelf()
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // Book selection view with search
                NavigationStack {
                    BookGridView(viewModel: viewModel, searchText: $searchText)
                        .navigationBarTitleDisplayMode(.inline)
                        .searchable(text: $searchText, prompt: "Search books")
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text("Books")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    viewModel.dismissBookshelf()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 13, weight: .semibold))
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
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.25), value: viewModel.selectedBookForChapter)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.black)
    }
}

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            BookshelfOverlay(viewModel: BibleViewModel())
        }
}

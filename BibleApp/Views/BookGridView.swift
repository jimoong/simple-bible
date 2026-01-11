import SwiftUI

struct BookGridView: View {
    @Bindable var viewModel: BibleViewModel
    @Binding var searchText: String
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var filteredBooks: [BibleBook] {
        let sorted = viewModel.sortedBooks
        
        if searchText.isEmpty {
            return sorted
        }
        
        return sorted.filter { book in
            book.nameEn.localizedCaseInsensitiveContains(searchText) ||
            book.nameKr.contains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Sort toggle
            sortToggle
            
            // Books grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(filteredBooks) { book in
                        BookCell(
                            book: book,
                            language: viewModel.languageMode,
                            isSelected: book == viewModel.currentBook
                        )
                        .onTapGesture {
                            viewModel.selectBook(book)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
    
    private var sortToggle: some View {
        Picker("Sort", selection: $viewModel.sortOrder) {
            Text("Canonical").tag(BookSortOrder.canonical)
            Text("A–Z").tag(BookSortOrder.alphabetical)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
    }
}

struct BookCell: View {
    let book: BibleBook
    let language: LanguageMode
    let isSelected: Bool
    
    private var theme: BookTheme {
        BookThemes.theme(for: book.id)
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(book.abbreviation(for: language))
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
            
            Text(book.name(for: language))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BookGridView(viewModel: BibleViewModel(), searchText: .constant(""))
    }
}

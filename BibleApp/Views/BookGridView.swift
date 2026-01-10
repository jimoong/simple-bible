import SwiftUI

struct BookGridView: View {
    @Bindable var viewModel: BibleViewModel
    @Binding var searchText: String
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
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
                LazyVGrid(columns: columns, spacing: 12) {
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
        HStack(spacing: 8) {
            ForEach(BookSortOrder.allCases, id: \.self) { order in
                Button {
                    if viewModel.sortOrder != order {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.toggleSortOrder()
                        }
                    }
                } label: {
                    Text(order == .canonical ? "Canonical" : "A–Z")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(viewModel.sortOrder == order ? .black : .white.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(viewModel.sortOrder == order ? .white : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
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
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(theme.textPrimary)
            
            Text(book.name(for: language))
                .font(.system(size: 10, weight: .medium))
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

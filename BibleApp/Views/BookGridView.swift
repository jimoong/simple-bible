import SwiftUI

struct BookGridView: View {
    @Bindable var viewModel: BibleViewModel
    @Binding var searchText: String
    var maxHeight: CGFloat = .infinity
    var safeAreaTop: CGFloat = 0
    var topPadding: CGFloat = 0  // Space for elements above
    var isFullscreen: Bool = false
    var onClose: (() -> Void)? = nil
    var onBookSelect: ((BibleBook) -> Void)? = nil
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    // Each cell is ~70pt height + 10pt spacing
    private let cellHeight: CGFloat = 70
    private let cellSpacing: CGFloat = 10
    private let headerHeight: CGFloat = 60  // Sort toggle + padding
    
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
    
    // Calculate content height based on number of rows (including safe area)
    private var contentHeight: CGFloat {
        let bookCount = filteredBooks.count
        let rowCount = ceil(Double(bookCount) / 3.0)
        let gridHeight = CGFloat(rowCount) * cellHeight + CGFloat(max(0, rowCount - 1)) * cellSpacing
        let totalHeight = safeAreaTop + headerHeight + gridHeight + 20  // 20 for bottom padding
        return min(totalHeight, maxHeight)
    }
    
    var body: some View {
        if isFullscreen {
            fullscreenView
        } else {
            compactView
        }
    }
    
    // MARK: - Fullscreen View (for books grid)
    private var fullscreenView: some View {
        VStack(spacing: 0) {
            // Title bar with "Books" and close button
            titleBar
            
            // Sort toggle
            sortToggle
                .padding(.top, 16)
            
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
                            if let onBookSelect {
                                onBookSelect(book)
                            } else {
                                viewModel.selectBook(book)
                            }
                            HapticManager.shared.selection()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 100)  // Space for bottom buttons
            }
        }
        .padding(.top, topPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    
    // MARK: - Title Bar
    private var titleBar: some View {
        ZStack {
            // Centered title
            Text("Books")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
            
            // Close button on right
            HStack {
                Spacer()
                
                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Compact View (for panel)
    private var compactView: some View {
        VStack(spacing: 16) {
            sortToggle
            
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
            }
        }
        .padding(.top, safeAreaTop + 16)
        .frame(height: contentHeight)
        .background(Color.black)
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

#Preview("Fullscreen") {
    BookGridView(
        viewModel: BibleViewModel(),
        searchText: .constant(""),
        topPadding: 100,
        isFullscreen: true,
        onClose: {}
    )
    .ignoresSafeArea()
}

#Preview("Compact") {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            BookGridView(viewModel: BibleViewModel(), searchText: .constant(""), maxHeight: 400, safeAreaTop: 59)
            Spacer()
        }
        .ignoresSafeArea(edges: .top)
    }
}

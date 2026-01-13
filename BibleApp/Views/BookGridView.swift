import SwiftUI

struct BookGridView: View {
    @Bindable var viewModel: BibleViewModel
    @Binding var searchText: String
    var maxHeight: CGFloat = .infinity
    var safeAreaTop: CGFloat = 0
    var safeAreaBottom: CGFloat = 0
    var topPadding: CGFloat = 0  // Space for elements above
    var isFullscreen: Bool = false
    var onClose: (() -> Void)? = nil
    var onBookSelect: ((BibleBook) -> Void)? = nil
    
    @State private var isSearchActive = false
    @FocusState private var isSearchFocused: Bool
    
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    // Each cell is ~70pt height + 10pt spacing
    private let cellHeight: CGFloat = 70
    private let cellSpacing: CGFloat = 10
    private let headerHeight: CGFloat = 60
    
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
    
    var oldTestamentBooks: [BibleBook] {
        filteredBooks.filter { $0.isOldTestament }
    }
    
    var newTestamentBooks: [BibleBook] {
        filteredBooks.filter { $0.isNewTestament }
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
        ZStack(alignment: .bottom) {
            // Content area - switches between book grid and timeline
            if viewModel.sortOrder == .timeline {
                // Timeline content (scrollable)
                BibleTimelineContentView(
                    languageMode: viewModel.languageMode,
                    topPadding: topPadding,
                    currentBook: viewModel.currentBook,
                    searchText: searchText,
                    onBookSelect: { book in
                        // Navigate to chapter grid when tapped in timeline
                        if let onBookSelect {
                            onBookSelect(book)
                        } else {
                            viewModel.selectBook(book)
                        }
                    }
                )
                .transition(.opacity)
            } else {
                // Books grid with sections (title scrolls with content)
                ScrollView {
                    VStack(spacing: 24) {
                        // Title (scrollable)
                        titleBar
                            .padding(.top, topPadding + 16)
                        
                        // Old Testament section
                        if !oldTestamentBooks.isEmpty {
                            bookSection(
                                title: viewModel.languageMode == .kr ? "구약" : "Old Testament",
                                books: oldTestamentBooks
                            )
                        }
                        
                        // New Testament section
                        if !newTestamentBooks.isEmpty {
                            bookSection(
                                title: viewModel.languageMode == .kr ? "신약" : "New Testament",
                                books: newTestamentBooks
                            )
                        }
                    }
                    .padding(.bottom, 120)  // Space for bottom controls
                }
                .transition(.opacity)
            }
            
            // Bottom bar - always visible
            bottomBar
                .padding(.horizontal, 24)
                .padding(.bottom, safeAreaBottom - 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .animation(.easeOut(duration: 0.3), value: viewModel.sortOrder)
    }
    
    // MARK: - Bottom Bar (iOS Photos style)
    private var bottomBar: some View {
        Group {
            if isSearchActive {
                // Search mode: Search input + close button
                searchInputBar
            } else {
                // Normal mode: Close + Segmented + Search
                normalBottomBar
            }
        }
    }
    
    // MARK: - Normal Bottom Bar
    private var normalBottomBar: some View {
        HStack(alignment: .bottom) {
            // Close button (left)
            Button {
                onClose?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.glassCircle)
            
            Spacer()
            
            // Segmented sort control - centered
            sortSegmentedControl
            
            Spacer()
            
            // Search button (right)
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    isSearchActive = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
                HapticManager.shared.selection()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.glassCircle)
        }
    }
    
    // MARK: - Search Input Bar
    private var searchInputBar: some View {
        HStack(spacing: 12) {
            // Search input field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                
                TextField(
                    viewModel.languageMode == .kr ? "검색" : "Search",
                    text: $searchText
                )
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .focused($isSearchFocused)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .glassBackground(.capsule, intensity: .regular)
            
            // Close search button
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    isSearchActive = false
                    searchText = ""
                    isSearchFocused = false
                }
                HapticManager.shared.selection()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.glassCircle)
        }
    }
    
    // MARK: - Segmented Sort Control
    private var sortSegmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(BookSortOrder.allCases, id: \.self) { order in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.sortOrder = order
                    }
                    HapticManager.shared.selection()
                } label: {
                    Text(order.displayName)
                        .font(.system(size: 14, weight: isOrderSelected(order) ? .semibold : .regular))
                        .foregroundStyle(isOrderSelected(order) ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(isOrderSelected(order) ? Color.white.opacity(0.15) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .glassBackground(.capsule, intensity: .regular)
    }
    
    private func isOrderSelected(_ order: BookSortOrder) -> Bool {
        return viewModel.sortOrder == order
    }
    
    // MARK: - Book Section
    private func bookSection(title: String, books: [BibleBook]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text(title)
                .font(viewModel.languageMode == .kr 
                    ? FontManager.koreanSans(size: 13, weight: .semibold)
                    : .system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 20)
            
            // Books grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(books) { book in
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
        }
    }
    
    // MARK: - Title
    private var titleBar: some View {
        Text(viewModel.languageMode == .kr ? "성경" : "Books")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Compact View (for panel)
    private var compactView: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 24) {
                    // Old Testament section
                    if !oldTestamentBooks.isEmpty {
                        compactBookSection(
                            title: viewModel.languageMode == .kr ? "구약" : "Old Testament",
                            books: oldTestamentBooks
                        )
                    }
                    
                    // New Testament section
                    if !newTestamentBooks.isEmpty {
                        compactBookSection(
                            title: viewModel.languageMode == .kr ? "신약" : "New Testament",
                            books: newTestamentBooks
                        )
                    }
                }
            }
        }
        .padding(.top, safeAreaTop + 16)
        .frame(height: contentHeight)
        .background(Color.black)
    }
    
    // MARK: - Compact Book Section
    private func compactBookSection(title: String, books: [BibleBook]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            Text(title)
                .font(viewModel.languageMode == .kr 
                    ? FontManager.koreanSans(size: 13, weight: .semibold)
                    : .system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 20)
            
            // Books grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(books) { book in
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
}

struct BookCell: View {
    let book: BibleBook
    let language: LanguageMode
    let isSelected: Bool
    
    private var theme: BookTheme {
        BookThemes.theme(for: book.id)
    }
    
    private var isFullyRead: Bool {
        ReadingProgressTracker.shared.isBookFullyRead(book: book)
    }
    
    // Very dark grey for fully read books (slightly brighter than pure black)
    private var cellBackground: Color {
        if isFullyRead {
            return Color(red: 0.12, green: 0.12, blue: 0.12)
        } else {
            return theme.surface
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 6) {
                Text(book.abbreviation(for: language))
                    .font(theme.display(24, language: language))
                    .foregroundStyle(isFullyRead ? theme.textPrimary.opacity(0.5) : theme.textPrimary)
                
                Text(book.name(for: language))
                    .font(language == .kr 
                        ? FontManager.koreanSans(size: 12, weight: .medium)
                        : .system(size: 12, weight: .medium, design: .default))
                    .foregroundStyle(isFullyRead ? theme.textSecondary.opacity(0.5) : theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cellBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 2)
            )
            
            // Checkmark indicator for fully read books
            if isFullyRead {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(8)
                    }
                    Spacer()
                }
            }
        }
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

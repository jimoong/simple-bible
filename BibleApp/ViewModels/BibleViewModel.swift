import SwiftUI
import Combine

@MainActor
@Observable
final class BibleViewModel {
    // MARK: - UserDefaults Keys
    private enum StorageKeys {
        static let bookId = "savedBookId"
        static let chapter = "savedChapter"
        static let verseIndex = "savedVerseIndex"
        static let languageMode = "savedLanguageMode"
    }
    
    // MARK: - State
    var currentBook: BibleBook {
        didSet { savePosition() }
    }
    var currentChapter: Int {
        didSet { savePosition() }
    }
    var verses: [BibleVerse] = []
    var currentVerseIndex: Int = 0 {
        didSet { savePosition() }
    }
    var languageMode: LanguageMode = .kr {
        didSet { saveLanguageMode() }
    }
    var sortOrder: BookSortOrder = .canonical
    
    var isLoading: Bool = false
    var errorMessage: String?
    var showBookshelf: Bool = false
    var selectedBookForChapter: BibleBook?
    
    // For chapter transition animation
    var transitionDirection: TransitionDirection = .none
    
    enum TransitionDirection {
        case none, left, right
    }
    
    // MARK: - Computed Properties
    var currentVerse: BibleVerse? {
        guard currentVerseIndex >= 0 && currentVerseIndex < verses.count else { return nil }
        return verses[currentVerseIndex]
    }
    
    var headerText: String {
        let bookName = currentBook.name(for: languageMode)
        return "\(bookName) \(currentChapter)"
    }
    
    var sortedBooks: [BibleBook] {
        BibleData.sortedBooks(by: sortOrder, language: languageMode)
    }
    
    var canGoToPreviousChapter: Bool {
        if currentChapter > 1 { return true }
        return BibleData.previousBook(before: currentBook) != nil
    }
    
    var canGoToNextChapter: Bool {
        if currentChapter < currentBook.chapterCount { return true }
        return BibleData.nextBook(after: currentBook) != nil
    }
    
    // MARK: - Current Theme
    var currentTheme: BookTheme {
        BookThemes.theme(for: currentBook.id)
    }
    
    // MARK: - Initialization
    init() {
        // Load saved position or default to John 1
        let defaults = UserDefaults.standard
        
        if let savedBookId = defaults.string(forKey: StorageKeys.bookId),
           let savedBook = BibleData.book(by: savedBookId) {
            self.currentBook = savedBook
            self.currentChapter = defaults.integer(forKey: StorageKeys.chapter)
            self.currentVerseIndex = defaults.integer(forKey: StorageKeys.verseIndex)
            
            // Validate chapter is in range
            if self.currentChapter < 1 || self.currentChapter > savedBook.chapterCount {
                self.currentChapter = 1
            }
        } else {
            // Default to John 1
            self.currentBook = BibleData.book(by: "john") ?? BibleData.books[0]
            self.currentChapter = 1
        }
        
        // Load saved language mode
        if let savedLanguage = defaults.string(forKey: StorageKeys.languageMode),
           let mode = LanguageMode(rawValue: savedLanguage) {
            self.languageMode = mode
        }
    }
    
    // MARK: - Persistence
    private func savePosition() {
        let defaults = UserDefaults.standard
        defaults.set(currentBook.id, forKey: StorageKeys.bookId)
        defaults.set(currentChapter, forKey: StorageKeys.chapter)
        defaults.set(currentVerseIndex, forKey: StorageKeys.verseIndex)
    }
    
    private func saveLanguageMode() {
        UserDefaults.standard.set(languageMode.rawValue, forKey: StorageKeys.languageMode)
    }
    
    // MARK: - Actions
    func loadCurrentChapter() async {
        isLoading = true
        errorMessage = nil
        
        do {
            verses = try await BibleAPIService.shared.fetchChapter(book: currentBook, chapter: currentChapter)
            
            // Clamp verse index to valid range
            if currentVerseIndex >= verses.count {
                currentVerseIndex = max(0, verses.count - 1)
            }
            
            // Prefetch adjacent chapters
            Task {
                await BibleAPIService.shared.prefetchAdjacentChapters(book: currentBook, currentChapter: currentChapter)
            }
        } catch {
            errorMessage = error.localizedDescription
            verses = []
        }
        
        isLoading = false
    }
    
    func goToNextVerse() {
        guard currentVerseIndex < verses.count - 1 else { return }
        currentVerseIndex += 1
        HapticManager.shared.lightClick()
    }
    
    func goToPreviousVerse() {
        guard currentVerseIndex > 0 else { return }
        currentVerseIndex -= 1
        HapticManager.shared.lightClick()
    }
    
    func onVerseSnap(to index: Int) {
        guard index != currentVerseIndex else { return }
        currentVerseIndex = index
        HapticManager.shared.lightClick()
    }
    
    func goToNextChapter() async {
        if currentChapter < currentBook.chapterCount {
            // Next chapter in same book
            transitionDirection = .left
            currentChapter += 1
            currentVerseIndex = 0
            HapticManager.shared.mediumClick()
            await loadCurrentChapter()
        } else if let nextBook = BibleData.nextBook(after: currentBook) {
            // First chapter of next book
            transitionDirection = .left
            currentBook = nextBook
            currentChapter = 1
            currentVerseIndex = 0
            HapticManager.shared.mediumClick()
            await loadCurrentChapter()
        }
        transitionDirection = .none
    }
    
    func goToPreviousChapter() async {
        if currentChapter > 1 {
            // Previous chapter in same book
            transitionDirection = .right
            currentChapter -= 1
            currentVerseIndex = 0
            HapticManager.shared.mediumClick()
            await loadCurrentChapter()
        } else if let previousBook = BibleData.previousBook(before: currentBook) {
            // Last chapter of previous book
            transitionDirection = .right
            currentBook = previousBook
            currentChapter = previousBook.chapterCount
            currentVerseIndex = 0
            HapticManager.shared.mediumClick()
            await loadCurrentChapter()
        }
        transitionDirection = .none
    }
    
    func navigateTo(book: BibleBook, chapter: Int, verse: Int = 0) async {
        currentBook = book
        currentChapter = chapter
        currentVerseIndex = verse
        showBookshelf = false
        selectedBookForChapter = nil
        HapticManager.shared.selection()
        await loadCurrentChapter()
    }
    
    func toggleLanguage() {
        let savedVerseIndex = currentVerseIndex
        languageMode = languageMode == .en ? .kr : .en
        currentVerseIndex = savedVerseIndex
        HapticManager.shared.selection()
    }
    
    func toggleSortOrder() {
        sortOrder = sortOrder == .canonical ? .alphabetical : .canonical
        HapticManager.shared.selection()
    }
    
    func selectBook(_ book: BibleBook) {
        selectedBookForChapter = book
        HapticManager.shared.selection()
    }
    
    func openBookshelf() {
        // Pre-select current book to show chapter view
        selectedBookForChapter = currentBook
        showBookshelf = true
        HapticManager.shared.selection()
    }
    
    func dismissBookshelf() {
        showBookshelf = false
        selectedBookForChapter = nil
    }
}

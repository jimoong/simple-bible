import SwiftUI

/// AI Bible Study Chat - Full Screen View
struct GamalielChatView: View {
    @Bindable var viewModel: GamalielViewModel
    let languageMode: LanguageMode
    let safeAreaTop: CGFloat
    let safeAreaBottom: CGFloat
    var onNavigateToVerse: ((BibleBook, Int, Int?) -> Void)? = nil  // book, chapter, verse
    
    @FocusState private var isInputFocused: Bool
    @State private var glowAnimating = false
    
    // Verse toast state
    @State private var showVerseToast = false
    @State private var selectedVerseBook: BibleBook?
    @State private var selectedVerseChapter: Int?
    @State private var selectedVerseNumber: Int?
    
    // Scroll to bottom state
    @State private var isAtBottom = true
    @State private var scrollProxy: ScrollViewProxy?
    
    // MARK: - Font Helper
    
    private func serifFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if languageMode == .kr {
            return FontManager.korean(size: size, weight: weight, design: .serif)
        } else {
            return .system(size: size, weight: weight, design: .serif)
        }
    }
    
    // Text constants (matching BookReadingView scroll mode)
    private let chatFontSize: CGFloat = 16
    private let chatLineSpacing: CGFloat = 7
    
    var body: some View {
        ZStack {
            // Background gradient (#0F0F0F top to #000000 bottom)
            LinearGradient(
                colors: [
                    Color(red: 15/255, green: 15/255, blue: 15/255),  // #0F0F0F
                    Color.black  // #000000
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Chat messages (scrolls behind header and input)
            chatContent
            
            // Header overlay at top
            VStack(spacing: 0) {
                header
                Spacer()
            }
            
            // Input area overlay at bottom with scroll button
            VStack(spacing: 0) {
                Spacer()
                
                // Scroll to bottom button (above input area, centered)
                if shouldShowScrollButton {
                    scrollToBottomButton
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
                
                inputArea
            }
            .animation(.easeOut(duration: 0.2), value: shouldShowScrollButton)
            
            // Verse toast overlay
            VStack {
                VerseToastContainer(
                    isVisible: $showVerseToast,
                    book: selectedVerseBook,
                    chapter: selectedVerseChapter,
                    verse: selectedVerseNumber,
                    languageMode: languageMode,
                    onTap: {
                        // Navigate to verse and close chat
                        if let book = selectedVerseBook, let chapter = selectedVerseChapter {
                            onNavigateToVerse?(book, chapter, selectedVerseNumber)
                            viewModel.showOverlay = false
                        }
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, safeAreaTop + 56)
                
                Spacer()
            }
        }
        .onAppear {
            viewModel.setLanguage(languageMode)
            // Start glow animation
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                glowAnimating = true
            }
            // Auto-focus input and show keyboard
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = true
            }
        }
    }
    
    // Handle verse reference tap
    private func handleVerseTap(book: BibleBook, chapter: Int, verse: Int?) {
        selectedVerseBook = book
        selectedVerseChapter = chapter
        selectedVerseNumber = verse
        showVerseToast = true
    }
    
    // MARK: - Header (App Logo + Glow, like BookGridView)
    
    private var header: some View {
        HStack {
            // Placeholder for symmetry (left)
            Color.clear
                .frame(width: 28, height: 28)
            
            Spacer()
            
            // App Logo with glow (center)
            Image("AppLogoTransparent")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(glowAnimating ? 0.38 : 0.25), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 22
                            )
                        )
                        .blur(radius: 6)
                        .scaleEffect(glowAnimating ? 1.15 : 1.0)
                        .allowsHitTesting(false)
                )
            
            Spacer()
            
            // Reset chat button (right side) - icon only
            Button {
                viewModel.clearChat()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .opacity(viewModel.hasMessages ? 1 : 0)
            .disabled(!viewModel.hasMessages)
        }
        .padding(.horizontal, 20)
        .padding(.top, safeAreaTop + 8)
        .padding(.bottom, 12)
        .background {
            ZStack {
                // Most transparent blur
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                // Black tint to blend with app background
                Color.black.opacity(0.7)
            }
        }
    }
    
    // Computed property to pair messages (user + assistant)
    private var conversationPairs: [ConversationPair] {
        var pairs: [ConversationPair] = []
        var i = 0
        let msgs = viewModel.messages
        
        while i < msgs.count {
            let message = msgs[i]
            
            if message.role == .user {
                // Check if next message is assistant response
                let response = (i + 1 < msgs.count && msgs[i + 1].role == .assistant) ? msgs[i + 1] : nil
                pairs.append(ConversationPair(userMessage: message, assistantMessage: response))
                i += (response != nil) ? 2 : 1
            } else {
                // Standalone assistant message (like welcome message)
                pairs.append(ConversationPair(userMessage: nil, assistantMessage: message))
                i += 1
            }
        }
        return pairs
    }
    
    // Calculate minimum height for conversation view
    private var conversationMinHeight: CGFloat {
        UIScreen.main.bounds.height - safeAreaTop - 70 - safeAreaBottom - 90
    }
    
    // Check if only welcome message exists (standalone assistant message with no user messages)
    private var isOnlyWelcomeMessage: Bool {
        viewModel.messages.count == 1 && viewModel.messages.first?.role == .assistant
    }
    
    // MARK: - Chat Content
    
    private var chatContent: some View {
        Group {
            if isOnlyWelcomeMessage {
                // Centered welcome message
                welcomeMessageView
            } else {
                // Regular chat content
                regularChatContent
            }
        }
    }
    
    // Welcome message view - centered with 60% width
    private var welcomeMessageView: some View {
        GeometryReader { geo in
            VStack {
                Spacer()
                
                if let welcomeMessage = viewModel.messages.first {
                    Text(welcomeMessage.content)
                        .font(serifFont(16))
                        .lineSpacing(7)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .frame(width: geo.size.width * 0.6)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // Regular chat content with message pairs
    private var regularChatContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 32) {
                    ForEach(Array(conversationPairs.enumerated()), id: \.element.id) { index, pair in
                        ConversationPairView(
                            pair: pair,
                            languageMode: languageMode,
                            isStreaming: viewModel.isStreaming && pair.assistantMessage?.id == viewModel.streamingMessageId,
                            isLastPair: index == conversationPairs.count - 1,
                            minHeight: conversationMinHeight,
                            onNavigateToVerse: handleVerseTap,
                        )
                        .id(pair.id)
                    }
                    
                    // Thinking indicator - show when thinking but no assistant message yet
                    if viewModel.isThinking && !viewModel.isStreaming {
                        ThinkingIndicator(languageMode: languageMode)
                            .id("thinking")
                    }
                    
                    // Error state
                    if let error = viewModel.errorMessage {
                        ErrorView(
                            message: error,
                            languageMode: languageMode,
                            onRetry: { viewModel.retryLastMessage() }
                        )
                    }
                    
                    // Bottom anchor for scroll detection
                    Color.clear
                        .frame(height: 1)
                        .id("scrollBottom")
                        .onAppear { isAtBottom = true }
                        .onDisappear { isAtBottom = false }
                }
                .padding(.horizontal, 20)
            }
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: safeAreaTop + 70)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: safeAreaBottom + 90)
            }
            .onAppear {
                scrollProxy = proxy
            }
            .onChange(of: viewModel.messages.count) { oldCount, newCount in
                // Scroll to the latest pair - position user message below header
                if let lastPair = conversationPairs.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastPair.id, anchor: .top)
                    }
                }
            }
            .onChange(of: viewModel.isThinking) { _, isThinking in
                if isThinking && !viewModel.isStreaming {
                    withAnimation {
                        proxy.scrollTo("thinking", anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // Scroll to bottom button - shows when not at bottom and no attached verse
    private var scrollToBottomButton: some View {
        Button {
            withAnimation(.easeOut(duration: 0.3)) {
                scrollProxy?.scrollTo("scrollBottom", anchor: .bottom)
            }
        } label: {
            Image(systemName: "arrow.down")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(.regularMaterial)
                        .environment(\.colorScheme, .dark)
                )
        }
    }
    
    // Should show scroll to bottom button
    private var shouldShowScrollButton: Bool {
        !isAtBottom && viewModel.attachedVerse == nil && !isOnlyWelcomeMessage
    }
    
    // MARK: - Input Area (matching search bar style)
    
    private var inputArea: some View {
        VStack(spacing: 8) {
            // Attached verse bubble (above input, centered)
            if let attachedVerse = viewModel.attachedVerse {
                AttachedVerseBubble(
                    verse: attachedVerse,
                    onRemove: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.clearAttachedVerse()
                        }
                    }
                )
                .transition(.scale.combined(with: .opacity))
            }
            
            HStack(spacing: 12) {
                // Text input field - same style as search bar
                HStack(spacing: 10) {
                    TextField(viewModel.inputPlaceholder, text: $viewModel.inputText, axis: .vertical)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .tint(.white)
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onChange(of: viewModel.inputText) { oldValue, newValue in
                            // Detect Enter key (newline) and send message instead
                            if newValue.contains("\n") && !oldValue.contains("\n") {
                                // Remove the newline and send
                                viewModel.inputText = newValue.replacingOccurrences(of: "\n", with: "")
                                if !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    viewModel.sendMessage()
                                }
                            }
                        }
                    
                    // Send button (inside input field, appears when there's text)
                    if !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            viewModel.sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                        }
                        .disabled(viewModel.isThinking)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .glassBackground(.capsule, intensity: .ultraThin)
                
                // Close/Dismiss keyboard button
                Button {
                    if isInputFocused {
                        // Dismiss keyboard
                        isInputFocused = false
                    } else {
                        // Close chat
                        viewModel.close()
                    }
                } label: {
                    Image(systemName: isInputFocused ? "chevron.down" : "xmark")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(.glassCircleUltraThin)
                .animation(.easeInOut(duration: 0.2), value: isInputFocused)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .padding(.bottom, safeAreaBottom)
        .animation(.easeOut(duration: 0.2), value: viewModel.attachedVerse != nil)
        .animation(.easeOut(duration: 0.15), value: viewModel.inputText.isEmpty)
    }
}

// MARK: - Attached Verse Bubble
// Shows the attached verse above the input field with book-specific styling

private struct AttachedVerseBubble: View {
    let verse: AttachedVerse
    let onRemove: () -> Void
    
    private var theme: BookTheme {
        BookThemes.theme(for: verse.book.id)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text(verse.referenceKr)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(theme.textSecondary)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.textSecondary.opacity(0.7))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.background)
        )
    }
}

// MARK: - Message Attached Verse Bubble
// Shows the attached verse in sent messages (no remove button)

private struct MessageAttachedVerseBubble: View {
    let verse: AttachedVerse
    
    private var theme: BookTheme {
        BookThemes.theme(for: verse.book.id)
    }
    
    var body: some View {
        Text(verse.referenceKr)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(theme.textSecondary)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.background)
            )
    }
}

// MARK: - Conversation Pair Model

private struct ConversationPair: Identifiable {
    let userMessage: GamalielMessage?
    let assistantMessage: GamalielMessage?
    
    // Stable ID based on message IDs
    var id: String {
        let usrId = userMessage?.id.uuidString ?? "no-user"
        let asstId = assistantMessage?.id.uuidString ?? "no-asst"
        return "\(usrId)-\(asstId)"
    }
}

// MARK: - Conversation Pair View

private struct ConversationPairView: View {
    let pair: ConversationPair
    let languageMode: LanguageMode
    let isStreaming: Bool
    let isLastPair: Bool  // Only the last pair can have minHeight
    let minHeight: CGFloat
    var onNavigateToVerse: ((BibleBook, Int, Int?) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // User message (if exists)
            if let userMessage = pair.userMessage {
                MessageBubble(message: userMessage, languageMode: languageMode, onNavigateToVerse: nil)
            }
            
            // Assistant message (if exists)
            if let assistantMessage = pair.assistantMessage {
                MessageBubble(message: assistantMessage, languageMode: languageMode, onNavigateToVerse: onNavigateToVerse)
            }
        }
        .frame(minHeight: shouldUseMinHeight ? minHeight : nil, alignment: .top)
    }
    
    // Use minimum height only when:
    // - This is the LAST pair AND
    // - This pair has a user message AND
    // - Either streaming is active OR assistant message is empty/nil
    private var shouldUseMinHeight: Bool {
        guard isLastPair else { return false }
        guard pair.userMessage != nil else { return false }
        
        if isStreaming {
            return true
        }
        
        // If assistant message is nil or empty, use min height
        if let assistantMessage = pair.assistantMessage {
            return assistantMessage.content.isEmpty
        }
        
        return true  // No assistant message yet
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: GamalielMessage
    let languageMode: LanguageMode
    var onNavigateToVerse: ((BibleBook, Int, Int?) -> Void)? = nil
    
    // Text constants
    private let chatFontSize: CGFloat = 16
    private let chatLineSpacing: CGFloat = 7
    private let paragraphSpacing: CGFloat = 24  // Spacing between paragraphs (double line breaks)
    
    private func serifFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if languageMode == .kr {
            return FontManager.korean(size: size, weight: weight, design: .serif)
        } else {
            return .system(size: size, weight: weight, design: .serif)
        }
    }
    
    // Split text into paragraphs (by double line breaks)
    private func paragraphs(_ text: String) -> [String] {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .assistant {
                // Assistant message - chunked by paragraphs with Bible reference chips
                VStack(alignment: .leading, spacing: paragraphSpacing) {
                    ForEach(Array(paragraphs(message.content).enumerated()), id: \.offset) { index, paragraph in
                        BibleReferenceTextView(
                            text: paragraph,
                            font: serifFont(chatFontSize),
                            lineSpacing: chatLineSpacing,
                            onNavigateToVerse: onNavigateToVerse
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // User message - with bubble (max 80% of screen width, right-aligned bubble, left-aligned text)
                VStack(alignment: .trailing, spacing: 2) {
                    // Attached verse bubble (if present)
                    if let attachedVerse = message.attachedVerse {
                        MessageAttachedVerseBubble(verse: attachedVerse)
                    }
                    
                    // User message bubble
                    Text(message.content)
                        .font(serifFont(15))
                        .foregroundStyle(.white.opacity(0.95))
                        .lineSpacing(5)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.12))
                        )
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

// MARK: - Bible Reference Text View
// Parses text for Bible references in parentheses and displays them as chips

private struct BibleReferenceTextView: View {
    let text: String
    let font: Font
    let lineSpacing: CGFloat
    var onNavigateToVerse: ((BibleBook, Int, Int?) -> Void)? = nil
    
    // Parsed reference for tap handling
    private struct ParsedRef {
        let range: Range<String.Index>
        let displayText: String
        let book: BibleBook
        let chapter: Int
        let verse: Int?
    }
    
    // Content block type for rendering
    private enum ContentBlock {
        case text(String)
        case bulletList([String])
        case orderedList([(number: String, content: String)])
    }
    
    // Check if line is a numbered list item (e.g., "1. ", "10. ")
    private func parseOrderedListItem(_ line: String) -> (number: String, content: String)? {
        let pattern = #"^(\d+)\.\s+(.*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(location: 0, length: line.utf16.count)
        guard let match = regex.firstMatch(in: line, options: [], range: range) else { return nil }
        
        if let numberRange = Range(match.range(at: 1), in: line),
           let contentRange = Range(match.range(at: 2), in: line) {
            return (String(line[numberRange]), String(line[contentRange]))
        }
        return nil
    }
    
    // Parse text into content blocks (regular text, bullet lists, ordered lists)
    private func parseContentBlocks(_ text: String) -> [ContentBlock] {
        var blocks: [ContentBlock] = []
        var currentTextLines: [String] = []
        var currentBulletLines: [String] = []
        var currentOrderedItems: [(number: String, content: String)] = []
        
        let lines = text.components(separatedBy: "\n")
        
        for line in lines {
            // Trim leading whitespace for prefix checking (handles indented lists)
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let isBullet = trimmedLine.hasPrefix("* ") || trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("• ")
            let orderedItem = parseOrderedListItem(trimmedLine)
            
            if isBullet {
                // Flush any accumulated text or ordered list
                if !currentTextLines.isEmpty {
                    blocks.append(.text(currentTextLines.joined(separator: "\n")))
                    currentTextLines = []
                }
                if !currentOrderedItems.isEmpty {
                    blocks.append(.orderedList(currentOrderedItems))
                    currentOrderedItems = []
                }
                // Add to bullet list - remove prefix and trim whitespace
                var bulletContent = trimmedLine
                if trimmedLine.hasPrefix("* ") {
                    bulletContent = String(trimmedLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                } else if trimmedLine.hasPrefix("- ") {
                    bulletContent = String(trimmedLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                } else if trimmedLine.hasPrefix("• ") {
                    bulletContent = String(trimmedLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                }
                currentBulletLines.append(bulletContent)
            } else if let item = orderedItem {
                // Flush any accumulated text or bullet list
                if !currentTextLines.isEmpty {
                    blocks.append(.text(currentTextLines.joined(separator: "\n")))
                    currentTextLines = []
                }
                if !currentBulletLines.isEmpty {
                    blocks.append(.bulletList(currentBulletLines))
                    currentBulletLines = []
                }
                currentOrderedItems.append(item)
            } else {
                // Flush any accumulated lists
                if !currentBulletLines.isEmpty {
                    blocks.append(.bulletList(currentBulletLines))
                    currentBulletLines = []
                }
                if !currentOrderedItems.isEmpty {
                    blocks.append(.orderedList(currentOrderedItems))
                    currentOrderedItems = []
                }
                currentTextLines.append(line)
            }
        }
        
        // Flush remaining
        if !currentBulletLines.isEmpty {
            blocks.append(.bulletList(currentBulletLines))
        }
        if !currentOrderedItems.isEmpty {
            blocks.append(.orderedList(currentOrderedItems))
        }
        if !currentTextLines.isEmpty {
            blocks.append(.text(currentTextLines.joined(separator: "\n")))
        }
        
        return blocks
    }
    
    var body: some View {
        let blocks = parseContentBlocks(text)
        
        VStack(alignment: .leading, spacing: lineSpacing + 4) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .text(let content):
                    let (attributedText, refs) = buildAttributedText(from: content)
                    Text(attributedText)
                        .font(font)
                        .lineSpacing(lineSpacing)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .environment(\.openURL, OpenURLAction { url in
                            if url.scheme == "bible",
                               let host = url.host,
                               let ref = refs.first(where: { $0.displayText.hashValue == Int(host) }) {
                                onNavigateToVerse?(ref.book, ref.chapter, ref.verse)
                                return .handled
                            }
                            return .systemAction
                        })
                    
                case .bulletList(let items):
                    VStack(alignment: .leading, spacing: lineSpacing + 10) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            BulletItemView(
                                content: item,
                                font: font,
                                lineSpacing: lineSpacing,
                                onNavigateToVerse: onNavigateToVerse
                            )
                        }
                    }
                    
                case .orderedList(let items):
                    VStack(alignment: .leading, spacing: lineSpacing + 10) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            OrderedItemView(
                                number: item.number,
                                content: item.content,
                                font: font,
                                lineSpacing: lineSpacing,
                                onNavigateToVerse: onNavigateToVerse
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Build AttributedString with styled Bible references as tappable links
    private func buildAttributedText(from text: String) -> (AttributedString, [ParsedRef]) {
        // Match parenthesized references only: (창세기 1:1), (시편 23:1), etc.
        let pattern = #"\(([^)]+\s+\d+[:\s]\d+|[^)]+\s+\d+장\s*\d*절?|[^)]+\s+\d+편\s*\d*절?)\)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return (formattedContent(text), [])
        }
        
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, options: [], range: range)
        
        guard !matches.isEmpty else {
            return (formattedContent(text), [])
        }
        
        // Build result by processing text segments
        var result = AttributedString()
        var refs: [ParsedRef] = []
        var lastEnd = 0
        
        for match in matches {
            // Add text before this match (with markdown)
            if match.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let beforeText = nsText.substring(with: beforeRange)
                result.append(formattedContent(beforeText))
            }
            
            // Process the reference
            let fullMatch = nsText.substring(with: match.range)
            let referenceText = String(fullMatch.dropFirst().dropLast())  // Remove ( and )
            
            let parsed = BibleReferenceParser.shared.parse(referenceText)
            if let book = parsed.book, let chapter = parsed.chapter {
                // Create styled reference without parentheses
                // Use non-breaking spaces (U+00A0) to prevent line wrapping
                let nbsp = "\u{00A0}"
                let noWrapRef = referenceText.replacingOccurrences(of: " ", with: nbsp)
                var refAttr = AttributedString("\(nbsp)\(noWrapRef)\(nbsp)")
                refAttr.foregroundColor = Color(hex: "C2BBA8")
                refAttr.font = .system(size: 12, weight: .medium, design: .default)  // Sans-serif
                refAttr.link = URL(string: "bible://\(referenceText.hashValue)")
                
                result.append(refAttr)
                
                if let swiftRange = Range(match.range, in: text) {
                    refs.append(ParsedRef(
                        range: swiftRange,
                        displayText: referenceText,
                        book: book,
                        chapter: chapter,
                        verse: parsed.verse
                    ))
                }
            } else {
                // Couldn't parse - keep original text
                result.append(formattedContent(fullMatch))
            }
            
            lastEnd = match.range.location + match.range.length
        }
        
        // Add remaining text
        if lastEnd < nsText.length {
            let remainingText = nsText.substring(from: lastEnd)
            result.append(formattedContent(remainingText))
        }
        
        return (result, refs)
    }
    
    // Parse markdown to AttributedString
    private func formattedContent(_ text: String) -> AttributedString {
        var result: AttributedString
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            result = attributed
        } else {
            result = AttributedString(text)
        }
        
        // Set default text color
        result.foregroundColor = .white.opacity(0.95)
        return result
    }
}

// MARK: - Bullet Item View
// Renders a single bullet item with proper hanging indent

private struct BulletItemView: View {
    let content: String
    let font: Font
    let lineSpacing: CGFloat
    var onNavigateToVerse: ((BibleBook, Int, Int?) -> Void)? = nil
    
    // Parsed reference for tap handling
    private struct ParsedRef {
        let displayText: String
        let book: BibleBook
        let chapter: Int
        let verse: Int?
    }
    
    var body: some View {
        let (attributedText, refs) = buildAttributedText(from: content)
        
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(font)
                .foregroundStyle(.white.opacity(0.95))
                .offset(y: 2)  // Fine-tune vertical alignment with text
            
            Text(attributedText)
                .font(font)
                .lineSpacing(lineSpacing)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)  // 텍스트 전체를 왼쪽으로 4pt 이동
                .environment(\.openURL, OpenURLAction { url in
                    if url.scheme == "bible",
                       let host = url.host,
                       let ref = refs.first(where: { $0.displayText.hashValue == Int(host) }) {
                        onNavigateToVerse?(ref.book, ref.chapter, ref.verse)
                        return .handled
                    }
                    return .systemAction
                })
        }
    }
    
    // Build AttributedString with styled Bible references as tappable links
    private func buildAttributedText(from text: String) -> (AttributedString, [ParsedRef]) {
        let pattern = #"\(([^)]+\s+\d+[:\s]\d+|[^)]+\s+\d+장\s*\d*절?|[^)]+\s+\d+편\s*\d*절?)\)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return (formattedContent(text), [])
        }
        
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, options: [], range: range)
        
        guard !matches.isEmpty else {
            return (formattedContent(text), [])
        }
        
        var result = AttributedString()
        var refs: [ParsedRef] = []
        var lastEnd = 0
        
        for match in matches {
            if match.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let beforeText = nsText.substring(with: beforeRange)
                result.append(formattedContent(beforeText))
            }
            
            let fullMatch = nsText.substring(with: match.range)
            let referenceText = String(fullMatch.dropFirst().dropLast())
            
            let parsed = BibleReferenceParser.shared.parse(referenceText)
            if let book = parsed.book, let chapter = parsed.chapter {
                let nbsp = "\u{00A0}"
                let noWrapRef = referenceText.replacingOccurrences(of: " ", with: nbsp)
                var refAttr = AttributedString("\(nbsp)\(noWrapRef)\(nbsp)")
                refAttr.foregroundColor = Color(hex: "C2BBA8")
                refAttr.font = .system(size: 12, weight: .medium, design: .default)
                refAttr.link = URL(string: "bible://\(referenceText.hashValue)")
                
                result.append(refAttr)
                refs.append(ParsedRef(
                    displayText: referenceText,
                    book: book,
                    chapter: chapter,
                    verse: parsed.verse
                ))
            } else {
                result.append(formattedContent(fullMatch))
            }
            
            lastEnd = match.range.location + match.range.length
        }
        
        if lastEnd < nsText.length {
            let remainingText = nsText.substring(from: lastEnd)
            result.append(formattedContent(remainingText))
        }
        
        return (result, refs)
    }
    
    // Parse markdown to AttributedString
    private func formattedContent(_ text: String) -> AttributedString {
        var result: AttributedString
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            result = attributed
        } else {
            result = AttributedString(text)
        }
        result.foregroundColor = .white.opacity(0.95)
        return result
    }
}

// MARK: - Ordered List Item View
// Renders a single numbered list item with proper hanging indent

private struct OrderedItemView: View {
    let number: String
    let content: String
    let font: Font
    let lineSpacing: CGFloat
    var onNavigateToVerse: ((BibleBook, Int, Int?) -> Void)? = nil
    
    // Parsed reference for tap handling
    private struct ParsedRef {
        let displayText: String
        let book: BibleBook
        let chapter: Int
        let verse: Int?
    }
    
    var body: some View {
        let (attributedText, refs) = buildAttributedText(from: content)
        
        HStack(alignment: .top, spacing: 6) {
            // Number with fixed width for alignment
            Text("\(number).")
                .font(font)
                .foregroundStyle(.white.opacity(0.95))
                .frame(minWidth: 20, alignment: .trailing)
            
            Text(attributedText)
                .font(font)
                .lineSpacing(lineSpacing)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .environment(\.openURL, OpenURLAction { url in
                    if url.scheme == "bible",
                       let host = url.host,
                       let ref = refs.first(where: { $0.displayText.hashValue == Int(host) }) {
                        onNavigateToVerse?(ref.book, ref.chapter, ref.verse)
                        return .handled
                    }
                    return .systemAction
                })
        }
    }
    
    // Build AttributedString with styled Bible references as tappable links
    private func buildAttributedText(from text: String) -> (AttributedString, [ParsedRef]) {
        let pattern = #"\(([^)]+\s+\d+[:\s]\d+|[^)]+\s+\d+장\s*\d*절?|[^)]+\s+\d+편\s*\d*절?)\)"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return (formattedContent(text), [])
        }
        
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let matches = regex.matches(in: text, options: [], range: range)
        
        guard !matches.isEmpty else {
            return (formattedContent(text), [])
        }
        
        var result = AttributedString()
        var refs: [ParsedRef] = []
        var lastEnd = 0
        
        for match in matches {
            if match.range.location > lastEnd {
                let beforeRange = NSRange(location: lastEnd, length: match.range.location - lastEnd)
                let beforeText = nsText.substring(with: beforeRange)
                result.append(formattedContent(beforeText))
            }
            
            let fullMatch = nsText.substring(with: match.range)
            let referenceText = String(fullMatch.dropFirst().dropLast())
            
            let parsed = BibleReferenceParser.shared.parse(referenceText)
            if let book = parsed.book, let chapter = parsed.chapter {
                let nbsp = "\u{00A0}"
                let noWrapRef = referenceText.replacingOccurrences(of: " ", with: nbsp)
                var refAttr = AttributedString("\(nbsp)\(noWrapRef)\(nbsp)")
                refAttr.foregroundColor = Color(hex: "C2BBA8")
                refAttr.font = .system(size: 12, weight: .medium, design: .default)
                refAttr.link = URL(string: "bible://\(referenceText.hashValue)")
                
                result.append(refAttr)
                refs.append(ParsedRef(
                    displayText: referenceText,
                    book: book,
                    chapter: chapter,
                    verse: parsed.verse
                ))
            } else {
                result.append(formattedContent(fullMatch))
            }
            
            lastEnd = match.range.location + match.range.length
        }
        
        if lastEnd < nsText.length {
            let remainingText = nsText.substring(from: lastEnd)
            result.append(formattedContent(remainingText))
        }
        
        return (result, refs)
    }
    
    // Parse markdown to AttributedString
    private func formattedContent(_ text: String) -> AttributedString {
        var result: AttributedString
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            result = attributed
        } else {
            result = AttributedString(text)
        }
        result.foregroundColor = .white.opacity(0.95)
        return result
    }
}

// MARK: - Thinking Indicator

private struct ThinkingIndicator: View {
    let languageMode: LanguageMode
    
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    private func serifFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if languageMode == .kr {
            return FontManager.korean(size: size, weight: weight, design: .serif)
        } else {
            return .system(size: size, weight: weight, design: .serif)
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(languageMode == .kr ? "생각 중" : "Thinking")
                .font(serifFont(15))
                .foregroundStyle(.white.opacity(0.5))
            
            Text(String(repeating: ".", count: dotCount))
                .font(serifFont(15))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 20, alignment: .leading)
            
            Spacer()
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let message: String
    let languageMode: LanguageMode
    let onRetry: () -> Void
    
    private func serifFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if languageMode == .kr {
            return FontManager.korean(size: size, weight: weight, design: .serif)
        } else {
            return .system(size: size, weight: weight, design: .serif)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.orange)
                
                Text(message)
                    .font(serifFont(15))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.orange.opacity(0.08))
            )
            
            Button {
                onRetry()
            } label: {
                Text(languageMode == .kr ? "다시 시도" : "Try Again")
                    .font(serifFont(15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }
}

// MARK: - Verse Toast (matches ChapterToast style exactly)

private struct VerseToast: View {
    let book: BibleBook
    let chapter: Int
    let verse: Int?
    let verseText: String?
    let languageMode: LanguageMode
    let theme: BookTheme
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Verse reference (like chapter title)
                Text(verseReference)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.textSecondary)
                
                // Verse text
                if let text = verseText, !text.isEmpty {
                    Text(text)
                        .font(theme.verseText(14, language: languageMode))
                        .foregroundStyle(theme.textPrimary)
                        .lineSpacing(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.surface)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var verseReference: String {
        let bookName = languageMode == .kr ? book.nameKr : book.nameEn
        if let verse = verse {
            if languageMode == .kr {
                return "\(bookName) \(chapter)장 \(verse)절"
            } else {
                return "\(bookName) \(chapter):\(verse)"
            }
        } else {
            if languageMode == .kr {
                return "\(bookName) \(chapter)장"
            } else {
                return "\(bookName) \(chapter)"
            }
        }
    }
}

private struct VerseToastContainer: View {
    @Binding var isVisible: Bool
    let book: BibleBook?
    let chapter: Int?
    let verse: Int?
    let languageMode: LanguageMode
    var onTap: () -> Void
    
    @State private var opacity: Double = 0
    @State private var offsetY: CGFloat = -12
    @State private var verseText: String?
    @State private var dismissTask: Task<Void, Never>?
    @State private var fetchTask: Task<Void, Never>?
    
    // Track current toast to detect changes
    @State private var currentToastId: String = ""
    
    private let displayDuration: Double = 5.0
    private let fadeInDuration: Double = 0.4
    private let fadeOutDuration: Double = 0.4
    private let quickFadeOutDuration: Double = 0.1
    private let quickFadeInDuration: Double = 0.2
    
    private var theme: BookTheme {
        guard let book = book else { return BookThemes.genesis }
        return BookThemes.theme(for: book.id)
    }
    
    private var toastId: String {
        guard let book = book, let chapter = chapter else { return "" }
        return "\(book.id)-\(chapter)-\(verse ?? 0)"
    }
    
    var body: some View {
        ZStack {
            if let book = book, let chapter = chapter, isVisible {
                VerseToast(
                    book: book,
                    chapter: chapter,
                    verse: verse,
                    verseText: verseText,
                    languageMode: languageMode,
                    theme: theme,
                    onTap: {
                        dismissToast(quick: false)
                        onTap()
                    }
                )
                .opacity(opacity)
                .offset(y: offsetY)
                .onChange(of: toastId) { oldId, newId in
                    if oldId != newId && !oldId.isEmpty {
                        switchToNewToast()
                    }
                }
                .onAppear {
                    currentToastId = toastId
                    fetchVerseTextThenShow()
                }
                .onDisappear {
                    dismissTask?.cancel()
                    fetchTask?.cancel()
                }
            }
        }
    }
    
    private func fetchVerseTextThenShow() {
        guard let book = book, let chapter = chapter else { return }
        
        fetchTask?.cancel()
        fetchTask = Task {
            do {
                let verses = try await BibleAPIService.shared.fetchChapter(book: book, chapter: chapter)
                if !Task.isCancelled {
                    await MainActor.run {
                        if let verseNum = verse, let foundVerse = verses.first(where: { $0.verseNumber == verseNum }) {
                            verseText = foundVerse.text(for: languageMode)
                        } else if let firstVerse = verses.first {
                            verseText = firstVerse.text(for: languageMode)
                        }
                        // Start animation after text is loaded
                        showToast()
                    }
                }
            } catch {
                // Still show toast even if fetch fails
                await MainActor.run {
                    showToast()
                }
            }
        }
    }
    
    private func showToast() {
        dismissTask?.cancel()
        
        // Reset initial state
        opacity = 0
        offsetY = -12
        
        // Fade in + slide down
        withAnimation(.easeOut(duration: fadeInDuration)) {
            opacity = 1
            offsetY = 0
        }
        
        // Schedule auto-dismiss
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(displayDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                dismissToast(quick: false)
            }
        }
    }
    
    private func switchToNewToast() {
        dismissTask?.cancel()
        fetchTask?.cancel()
        
        // Quick fade out + slide up
        withAnimation(.easeOut(duration: quickFadeOutDuration)) {
            opacity = 0
            offsetY = -12
        }
        
        // Then fetch new content and fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + quickFadeOutDuration) {
            verseText = nil
            currentToastId = toastId
            
            guard let book = book, let chapter = chapter else { return }
            
            fetchTask = Task {
                do {
                    let verses = try await BibleAPIService.shared.fetchChapter(book: book, chapter: chapter)
                    if !Task.isCancelled {
                        await MainActor.run {
                            if let verseNum = verse, let foundVerse = verses.first(where: { $0.verseNumber == verseNum }) {
                                verseText = foundVerse.text(for: languageMode)
                            } else if let firstVerse = verses.first {
                                verseText = firstVerse.text(for: languageMode)
                            }
                            showToastQuick()
                        }
                    }
                } catch {
                    await MainActor.run {
                        showToastQuick()
                    }
                }
            }
        }
    }
    
    private func showToastQuick() {
        withAnimation(.easeOut(duration: quickFadeInDuration)) {
            opacity = 1
            offsetY = 0
        }
        
        // Reset auto-dismiss timer
        dismissTask?.cancel()
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(displayDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                dismissToast(quick: false)
            }
        }
    }
    
    private func dismissToast(quick: Bool) {
        dismissTask?.cancel()
        fetchTask?.cancel()
        
        let duration = quick ? quickFadeOutDuration : fadeOutDuration
        
        // Fade out + slide up
        withAnimation(.easeOut(duration: duration)) {
            opacity = 0
            offsetY = -12
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            isVisible = false
            verseText = nil
            currentToastId = ""
        }
    }
}

// MARK: - Preview

#Preview {
    GamalielChatView(
        viewModel: GamalielViewModel(),
        languageMode: .kr,
        safeAreaTop: 59,
        safeAreaBottom: 34
    )
}

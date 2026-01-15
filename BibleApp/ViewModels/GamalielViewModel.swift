import SwiftUI
import Combine

/// State for the Gamaliel chat interface
enum GamalielState: Equatable {
    case idle
    case thinking
    case error(String)
}

/// A single chat message
struct GamalielMessage: Identifiable, Equatable {
    let id = UUID()
    let role: MessageRole
    var content: String  // Mutable for streaming
    let timestamp: Date
    var attachedVerse: AttachedVerse? = nil  // Optional attached verse for user messages
    
    enum MessageRole: String, Equatable {
        case user
        case assistant
    }
}

/// Attached verse for context-aware questions
struct AttachedVerse: Equatable {
    let book: BibleBook
    let chapter: Int
    let verseNumber: Int
    let text: String
    
    var referenceKr: String {
        "\(book.nameKr) \(chapter)장 \(verseNumber)절"
    }
    
    var referenceEn: String {
        "\(book.nameEn) \(chapter):\(verseNumber)"
    }
    
    func reference(for language: LanguageMode) -> String {
        language == .kr ? referenceKr : referenceEn
    }
}

@MainActor
@Observable
final class GamalielViewModel {
    
    // MARK: - State
    var state: GamalielState = .idle
    var showOverlay = false
    var messages: [GamalielMessage] = []
    var inputText: String = ""
    var isStreaming = false  // Track if response is currently streaming
    var streamingMessageId: UUID? = nil  // ID of message being streamed
    var attachedVerse: AttachedVerse? = nil  // Verse attached to next message
    
    // MARK: - Settings
    private var language: LanguageMode = .kr
    
    // MARK: - Computed Properties
    
    var isThinking: Bool {
        if case .thinking = state { return true }
        return false
    }
    
    var errorMessage: String? {
        if case .error(let message) = state {
            return message
        }
        return nil
    }
    
    var hasMessages: Bool {
        !messages.isEmpty
    }
    
    var isConfigured: Bool {
        get async {
            await GamalielService.shared.isConfigured()
        }
    }
    
    // Welcome message based on language
    var welcomeMessage: String {
        if language == .kr {
            return "안녕하세요! 저는 가말리엘입니다. 성경에 관한 질문이 있으시면 무엇이든 물어보세요."
        } else {
            return "Hello! I'm Gamaliel. Feel free to ask me anything about the Bible."
        }
    }
    
    var inputPlaceholder: String {
        if language == .kr {
            return "성경에 관해 질문하세요..."
        } else {
            return "Ask about the Bible..."
        }
    }
    
    // MARK: - Actions
    
    func open(with languageMode: LanguageMode) {
        self.language = languageMode
        showOverlay = true
        state = .idle
        
        // Add welcome message if no messages
        if messages.isEmpty {
            messages.append(GamalielMessage(
                role: .assistant,
                content: welcomeMessage,
                timestamp: Date()
            ))
        }
    }
    
    func close() {
        showOverlay = false
        inputText = ""
    }
    
    func setLanguage(_ mode: LanguageMode) {
        self.language = mode
    }
    
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Remove welcome message if it's the first user message
        if messages.count == 1, messages.first?.role == .assistant {
            messages.removeAll()
        }
        
        // Capture attached verse before clearing
        let currentAttachedVerse = attachedVerse
        
        // Add user message with attached verse
        let userMessage = GamalielMessage(
            role: .user,
            content: text,
            timestamp: Date(),
            attachedVerse: currentAttachedVerse
        )
        messages.append(userMessage)
        inputText = ""
        attachedVerse = nil  // Clear attachment after sending
        
        // Start thinking
        state = .thinking
        HapticManager.shared.lightClick()
        
        // Send to API with verse context
        Task {
            await fetchResponse(for: text, verseContext: currentAttachedVerse)
        }
    }
    
    func clearAttachedVerse() {
        attachedVerse = nil
    }
    
    /// Open chat with an attached verse for asking questions
    func openWithVerse(_ verse: AttachedVerse, languageMode: LanguageMode) {
        self.language = languageMode
        self.attachedVerse = verse
        showOverlay = true
        state = .idle
        
        // Add welcome message if no messages
        if messages.isEmpty {
            messages.append(GamalielMessage(
                role: .assistant,
                content: welcomeMessage,
                timestamp: Date()
            ))
        }
    }
    
    private func fetchResponse(for question: String, verseContext: AttachedVerse? = nil) async {
        do {
            // Build the question with verse context if provided
            var fullQuestion = question
            if let verse = verseContext {
                let contextPrefix = language == .kr
                    ? "다음 성경 구절을 참고하여 답변해 주세요:\n\(verse.referenceKr): \"\(verse.text)\"\n\n질문: "
                    : "Please answer with reference to this Bible verse:\n\(verse.referenceEn): \"\(verse.text)\"\n\nQuestion: "
                fullQuestion = contextPrefix + question
            }
            
            // Build conversation history for context (Gemini uses "model" instead of "assistant")
            var conversationMessages = messages.dropLast().suffix(9).map { msg in
                // For messages with attached verses, include the context
                var content = msg.content
                if let attachedVerse = msg.attachedVerse, msg.role == .user {
                    let prefix = language == .kr
                        ? "[\(attachedVerse.referenceKr) 참조]\n"
                        : "[Ref: \(attachedVerse.referenceEn)]\n"
                    content = prefix + content
                }
                return GamalielService.ChatMessage(
                    role: msg.role == .user ? "user" : "model",
                    content: content
                )
            }
            
            // Add current question with context
            conversationMessages.append(GamalielService.ChatMessage(
                role: "user",
                content: fullQuestion
            ))
            
            // Create placeholder message for streaming
            let assistantMessage = GamalielMessage(
                role: .assistant,
                content: "",
                timestamp: Date()
            )
            messages.append(assistantMessage)
            let messageIndex = messages.count - 1
            
            // Mark streaming started
            isStreaming = true
            streamingMessageId = assistantMessage.id
            
            // Stream the response
            let stream = await GamalielService.shared.chatStream(
                messages: conversationMessages,
                language: language == .kr ? "ko" : "en"
            )
            
            for try await chunk in stream {
                messages[messageIndex].content += chunk
            }
            
            // Mark streaming complete
            isStreaming = false
            streamingMessageId = nil
            state = .idle
            HapticManager.shared.success()
            
        } catch {
            // Remove empty placeholder message on error
            if let lastMessage = messages.last, lastMessage.role == .assistant && lastMessage.content.isEmpty {
                messages.removeLast()
            }
            isStreaming = false
            streamingMessageId = nil
            state = .error(error.localizedDescription)
            HapticManager.shared.error()
        }
    }
    
    func clearChat() {
        messages.removeAll()
        state = .idle
        
        // Re-add welcome message
        messages.append(GamalielMessage(
            role: .assistant,
            content: welcomeMessage,
            timestamp: Date()
        ))
    }
    
    func retryLastMessage() {
        // Find and retry the last user message
        if let lastUserMessage = messages.last(where: { $0.role == .user }) {
            state = .thinking
            Task {
                await fetchResponse(for: lastUserMessage.content)
            }
        }
    }
    
    /// Ask about a specific verse (context-aware)
    func askAboutVerse(book: String, chapter: Int, verse: Int, text: String) {
        let question: String
        if language == .kr {
            question = "\(book) \(chapter)장 \(verse)절 '\(text)'에 대해 설명해 주세요."
        } else {
            question = "Please explain \(book) \(chapter):\(verse) '\(text)'."
        }
        
        inputText = question
        sendMessage()
    }
    
    /// Ask about the current chapter
    func askAboutChapter(book: String, chapter: Int) {
        let question: String
        if language == .kr {
            question = "\(book) \(chapter)장의 핵심 메시지와 중요한 내용을 설명해 주세요."
        } else {
            question = "Please explain the key message and important content of \(book) chapter \(chapter)."
        }
        
        inputText = question
        sendMessage()
    }
}

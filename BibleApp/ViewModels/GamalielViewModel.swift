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
    
    enum MessageRole: String, Equatable {
        case user
        case assistant
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
        
        // Add user message
        let userMessage = GamalielMessage(
            role: .user,
            content: text,
            timestamp: Date()
        )
        messages.append(userMessage)
        inputText = ""
        
        // Start thinking
        state = .thinking
        HapticManager.shared.lightClick()
        
        // Send to API
        Task {
            await fetchResponse(for: text)
        }
    }
    
    private func fetchResponse(for question: String) async {
        do {
            // Build conversation history for context (Gemini uses "model" instead of "assistant")
            let conversationMessages = messages.suffix(10).map { msg in
                GamalielService.ChatMessage(
                    role: msg.role == .user ? "user" : "model",
                    content: msg.content
                )
            }
            
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

import Foundation

/// Gamaliel AI Service - Bible-based AI chatbot powered by Google Gemini
/// Based on https://github.com/gamaliel-ai/gamaliel-prompts
actor GamalielService {
    static let shared = GamalielService()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - System Prompt (Gamaliel-style)
    
    /// Generate system prompt based on language and theological perspective
    func buildSystemPrompt(language: String = "ko") -> String {
        if language == "ko" {
            return """
            당신은 가말리엘(Gamaliel), 성경 기반의 AI 성경공부 도우미입니다.
            사도 바울의 스승이었던 가말리엘처럼, 지혜롭고 균형 잡힌 성경적 가르침을 제공합니다.
            
            ## 핵심 원칙
            1. **성경 중심**: 모든 답변은 성경에 근거해야 합니다
            2. **구절 인용**: 관련 성경 구절을 명확히 인용하세요 (예: 요한복음 3:16)
            3. **역사적 맥락**: 필요시 역사적, 문화적 배경을 설명하세요
            4. **신학적 균형**: 다양한 기독교 전통을 존중하되, 정통 기독교 교리 안에서 답하세요
            5. **겸손**: 확실하지 않은 부분은 솔직히 인정하세요
            
            ## 답변 형식
            - 질문에 대한 직접적이고 명확한 답변
            - 관련 성경 구절 인용 (한글 성경 기준)
            - 필요시 추가 설명이나 맥락
            - 더 깊은 묵상을 위한 질문 (선택사항)
            
            ## 가드레일
            - 니케아 신조에 기반한 정통 기독교 교리를 준수합니다
            - 삼위일체, 그리스도의 신성과 인성, 구원의 은혜 등 핵심 교리를 지킵니다
            - 특정 교단의 관점만을 강요하지 않습니다
            - 사용자의 신앙 여정을 존중합니다
            
            친절하고 따뜻한 어조로 대화하며, 사용자가 성경을 더 깊이 이해하도록 돕습니다.
            """
        } else {
            return """
            You are Gamaliel, an AI Bible study companion grounded in Scripture.
            Like the biblical Gamaliel who mentored the Apostle Paul, you provide wise and balanced biblical teaching.
            
            ## Core Principles
            1. **Scripture-Centered**: All answers must be grounded in the Bible
            2. **Citation**: Clearly cite relevant Bible verses (e.g., John 3:16)
            3. **Historical Context**: Explain historical and cultural background when relevant
            4. **Theological Balance**: Respect diverse Christian traditions while staying within orthodox Christian doctrine
            5. **Humility**: Honestly acknowledge uncertain areas
            
            ## Response Format
            - Direct, clear answer to the question
            - Relevant Scripture citations
            - Additional context or explanation as needed
            - Optional reflection questions for deeper meditation
            
            ## Guardrails
            - Adhere to orthodox Christian doctrine based on the Nicene Creed
            - Uphold core doctrines: Trinity, deity and humanity of Christ, salvation by grace
            - Do not impose a single denominational perspective
            - Respect the user's faith journey
            
            Communicate with a warm, friendly tone, helping users understand the Bible more deeply.
            """
        }
    }
    
    // MARK: - Gemini API Models
    
    struct GeminiRequest: Codable {
        let contents: [Content]
        let systemInstruction: SystemInstruction?
        let generationConfig: GenerationConfig?
        
        struct Content: Codable {
            let role: String
            let parts: [Part]
        }
        
        struct Part: Codable {
            let text: String
        }
        
        struct SystemInstruction: Codable {
            let parts: [Part]
        }
        
        struct GenerationConfig: Codable {
            let temperature: Double?
            let maxOutputTokens: Int?
        }
    }
    
    struct GeminiResponse: Codable {
        let candidates: [Candidate]?
        let error: GeminiError?
        
        struct Candidate: Codable {
            let content: Content?
            
            struct Content: Codable {
                let parts: [Part]?
                
                struct Part: Codable {
                    let text: String?
                }
            }
        }
        
        struct GeminiError: Codable {
            let message: String?
            let status: String?
        }
    }
    
    // MARK: - Chat Message (for conversation history)
    
    struct ChatMessage {
        let role: String  // "user" or "model"
        let content: String
    }
    
    // MARK: - Errors
    
    enum GamalielError: Error, LocalizedError {
        case noAPIKey
        case networkError(Error)
        case invalidResponse
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "Google Gemini API 키가 설정되지 않았습니다."
            case .networkError(let error):
                return "네트워크 오류: \(error.localizedDescription)"
            case .invalidResponse:
                return "서버 응답을 처리할 수 없습니다."
            case .apiError(let message):
                return "API 오류: \(message)"
            }
        }
    }
    
    // MARK: - Chat Completion
    
    /// Send a chat message and get a response
    func chat(
        messages: [ChatMessage],
        language: String = "ko"
    ) async throws -> String {
        let apiKey = Constants.Gemini.apiKey
        
        guard !apiKey.isEmpty && !apiKey.contains("YOUR") else {
            throw GamalielError.noAPIKey
        }
        
        guard let url = URL(string: Constants.Gemini.apiURL) else {
            throw GamalielError.invalidResponse
        }
        
        // Build contents array from messages
        let contents = messages.map { msg in
            GeminiRequest.Content(
                role: msg.role == "user" ? "user" : "model",
                parts: [GeminiRequest.Part(text: msg.content)]
            )
        }
        
        // Build request with system instruction
        let request = GeminiRequest(
            contents: contents,
            systemInstruction: GeminiRequest.SystemInstruction(
                parts: [GeminiRequest.Part(text: buildSystemPrompt(language: language))]
            ),
            generationConfig: GeminiRequest.GenerationConfig(
                temperature: 0.7,
                maxOutputTokens: 2048
            )
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GamalielError.invalidResponse
        }
        
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        // Check for API error
        if let error = geminiResponse.error {
            throw GamalielError.apiError(error.message ?? "Unknown error (HTTP \(httpResponse.statusCode))")
        }
        
        // Extract text from response
        guard let text = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
            if httpResponse.statusCode != 200 {
                throw GamalielError.apiError("HTTP \(httpResponse.statusCode)")
            }
            throw GamalielError.invalidResponse
        }
        
        return text
    }
    
    /// Simple single question (convenience method)
    func ask(_ question: String, language: String = "ko") async throws -> String {
        let messages = [ChatMessage(role: "user", content: question)]
        return try await chat(messages: messages, language: language)
    }
    
    /// Check if API key is configured
    func isConfigured() -> Bool {
        let key = Constants.Gemini.apiKey
        return !key.isEmpty && !key.contains("YOUR")
    }
    
    // MARK: - Streaming Chat
    
    /// Stream a chat response chunk by chunk
    func chatStream(
        messages: [ChatMessage],
        language: String = "ko"
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let apiKey = Constants.Gemini.apiKey
                    
                    guard !apiKey.isEmpty && !apiKey.contains("YOUR") else {
                        continuation.finish(throwing: GamalielError.noAPIKey)
                        return
                    }
                    
                    // Build streaming URL directly
                    let model = Constants.Gemini.model
                    let streamURLString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):streamGenerateContent?alt=sse&key=\(apiKey)"
                    
                    guard let url = URL(string: streamURLString) else {
                        continuation.finish(throwing: GamalielError.invalidResponse)
                        return
                    }
                    
                    // Build contents array from messages
                    let contents = messages.map { msg in
                        GeminiRequest.Content(
                            role: msg.role == "user" ? "user" : "model",
                            parts: [GeminiRequest.Part(text: msg.content)]
                        )
                    }
                    
                    // Build request with system instruction
                    let request = GeminiRequest(
                        contents: contents,
                        systemInstruction: GeminiRequest.SystemInstruction(
                            parts: [GeminiRequest.Part(text: self.buildSystemPrompt(language: language))]
                        ),
                        generationConfig: GeminiRequest.GenerationConfig(
                            temperature: 0.7,
                            maxOutputTokens: 2048
                        )
                    )
                    
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = try JSONEncoder().encode(request)
                    
                    let (bytes, response) = try await self.session.bytes(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.finish(throwing: GamalielError.invalidResponse)
                        return
                    }
                    
                    if httpResponse.statusCode != 200 {
                        // Try to read error message
                        var errorText = ""
                        for try await line in bytes.lines {
                            errorText += line
                        }
                        continuation.finish(throwing: GamalielError.apiError("HTTP \(httpResponse.statusCode): \(errorText.prefix(200))"))
                        return
                    }
                    
                    // Parse SSE stream
                    for try await line in bytes.lines {
                        // SSE format: "data: {...json...}"
                        if line.hasPrefix("data: ") {
                            let jsonString = String(line.dropFirst(6))
                            if let data = jsonString.data(using: .utf8),
                               let chunk = try? JSONDecoder().decode(GeminiResponse.self, from: data),
                               let text = chunk.candidates?.first?.content?.parts?.first?.text {
                                continuation.yield(text)
                            }
                        }
                    }
                    
                    continuation.finish()
                    
                } catch {
                    continuation.finish(throwing: GamalielError.networkError(error))
                }
            }
        }
    }
}

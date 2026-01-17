import Foundation

/// ⚠️ TEMPLATE FILE - Copy this to Secrets.swift and add your API keys
/// 
/// Steps:
/// 1. Copy this file: cp Secrets.template.swift Secrets.swift
/// 2. Add your actual API keys in Secrets.swift
/// 3. Secrets.swift is gitignored, so your keys stay safe
///
enum Secrets {
    
    /// OpenAI API Key (for Chat + TTS)
    /// Get your key at: https://platform.openai.com/api-keys
    static let openAIKey = "YOUR-OPENAI-API-KEY-HERE"
    
    /// Google Gemini API Key (Legacy - optional)
    /// Get your key at: https://aistudio.google.com/app/apikey
    static let geminiKey = "YOUR-GEMINI-API-KEY-HERE"
    
    /// Error Reporting Webhook URL (Discord or Slack)
    /// Discord: https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN
    /// Slack: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
    /// Leave empty to disable remote error reporting
    static let errorReportingWebhookURL = ""
}

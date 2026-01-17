//
//  ErrorReporter.swift
//  BibleApp
//
//  Remote error reporting service via Discord/Slack webhook
//

import Foundation

// MARK: - Error Reporter

actor ErrorReporter {
    static let shared = ErrorReporter()
    
    private var lastReportTime: Date?
    private let minReportInterval: TimeInterval = 5.0 // Prevent spam
    private let maxReportsPerHour = 20
    private var reportsThisHour = 0
    private var hourStartTime = Date()
    
    private init() {}
    
    // MARK: - Reporting
    
    /// Report an error via webhook
    func report(error: Error, context: ErrorContext) async {
        let log = ErrorLog(error: error, context: context)
        await sendReport(log)
    }
    
    /// Report an error message via webhook
    func report(message: String, code: String?, context: ErrorContext) async {
        let log = ErrorLog(error: nil, message: message, code: code, context: context)
        await sendReport(log)
    }
    
    // MARK: - Private Methods
    
    private func sendReport(_ log: ErrorLog) async {
        // Check rate limiting
        guard shouldSendReport() else {
            print("⚠️ ErrorReporter: Rate limited, skipping report")
            return
        }
        
        // Check if webhook URL is configured
        guard let webhookURL = getWebhookURL() else {
            print("⚠️ ErrorReporter: No webhook URL configured")
            return
        }
        
        // Determine webhook type and send appropriate format
        if webhookURL.contains("discord") {
            await sendDiscordReport(log, url: webhookURL)
        } else if webhookURL.contains("slack") {
            await sendSlackReport(log, url: webhookURL)
        } else {
            // Generic JSON POST
            await sendGenericReport(log, url: webhookURL)
        }
        
        lastReportTime = Date()
        reportsThisHour += 1
    }
    
    private func shouldSendReport() -> Bool {
        // Reset hourly counter if needed
        if Date().timeIntervalSince(hourStartTime) > 3600 {
            hourStartTime = Date()
            reportsThisHour = 0
        }
        
        // Check hourly limit
        guard reportsThisHour < maxReportsPerHour else {
            return false
        }
        
        // Check minimum interval
        if let lastTime = lastReportTime {
            guard Date().timeIntervalSince(lastTime) >= minReportInterval else {
                return false
            }
        }
        
        return true
    }
    
    private func getWebhookURL() -> String? {
        // Try to get webhook URL from Secrets
        // Return nil if not configured (empty or placeholder)
        let url = Secrets.errorReportingWebhookURL
        guard !url.isEmpty && !url.contains("YOUR") else {
            return nil
        }
        return url
    }
    
    // MARK: - Discord Format
    
    private func sendDiscordReport(_ log: ErrorLog, url: String) async {
        guard let requestURL = URL(string: url) else { return }
        
        // Build Discord embed
        let embed: [String: Any] = [
            "title": "🔴 Error Report",
            "color": 15158332, // Red color
            "fields": [
                ["name": "Context", "value": log.context, "inline": false],
                ["name": "Message", "value": String(log.errorMessage.prefix(1000)), "inline": false],
                ["name": "Code", "value": log.errorCode ?? "N/A", "inline": true],
                ["name": "Device", "value": log.deviceInfo.model, "inline": true],
                ["name": "OS", "value": log.deviceInfo.osVersion, "inline": true],
                ["name": "App Version", "value": "\(log.deviceInfo.appVersion) (\(log.deviceInfo.buildNumber))", "inline": true],
                ["name": "Language", "value": log.deviceInfo.language, "inline": true],
                ["name": "Device ID", "value": log.deviceInfo.deviceId, "inline": true]
            ],
            "timestamp": ISO8601DateFormatter().string(from: log.timestamp)
        ]
        
        let payload: [String: Any] = [
            "embeds": [embed]
        ]
        
        await sendWebhook(url: requestURL, payload: payload)
    }
    
    // MARK: - Slack Format
    
    private func sendSlackReport(_ log: ErrorLog, url: String) async {
        guard let requestURL = URL(string: url) else { return }
        
        let payload: [String: Any] = [
            "blocks": [
                [
                    "type": "header",
                    "text": [
                        "type": "plain_text",
                        "text": "🔴 Error Report",
                        "emoji": true
                    ]
                ],
                [
                    "type": "section",
                    "fields": [
                        ["type": "mrkdwn", "text": "*Context:*\n\(log.context)"],
                        ["type": "mrkdwn", "text": "*Code:*\n\(log.errorCode ?? "N/A")"]
                    ]
                ],
                [
                    "type": "section",
                    "text": [
                        "type": "mrkdwn",
                        "text": "*Message:*\n```\(String(log.errorMessage.prefix(500)))```"
                    ]
                ],
                [
                    "type": "section",
                    "fields": [
                        ["type": "mrkdwn", "text": "*Device:*\n\(log.deviceInfo.model)"],
                        ["type": "mrkdwn", "text": "*OS:*\n\(log.deviceInfo.osVersion)"],
                        ["type": "mrkdwn", "text": "*App Version:*\n\(log.deviceInfo.appVersion)"],
                        ["type": "mrkdwn", "text": "*Device ID:*\n\(log.deviceInfo.deviceId)"]
                    ]
                ],
                [
                    "type": "context",
                    "elements": [
                        [
                            "type": "mrkdwn",
                            "text": "Reported at \(ISO8601DateFormatter().string(from: log.timestamp))"
                        ]
                    ]
                ]
            ]
        ]
        
        await sendWebhook(url: requestURL, payload: payload)
    }
    
    // MARK: - Generic JSON Format
    
    private func sendGenericReport(_ log: ErrorLog, url: String) async {
        guard let requestURL = URL(string: url),
              let jsonData = log.jsonData else { return }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    print("✅ ErrorReporter: Report sent successfully")
                } else {
                    print("⚠️ ErrorReporter: HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("⚠️ ErrorReporter: Failed to send report - \(error.localizedDescription)")
        }
    }
    
    // MARK: - Webhook Sender
    
    private func sendWebhook(url: URL, payload: [String: Any]) async {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                    print("✅ ErrorReporter: Report sent successfully")
                } else {
                    print("⚠️ ErrorReporter: HTTP \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("⚠️ ErrorReporter: Failed to send report - \(error.localizedDescription)")
        }
    }
}

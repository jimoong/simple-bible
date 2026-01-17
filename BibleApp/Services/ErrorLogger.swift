//
//  ErrorLogger.swift
//  BibleApp
//
//  Local error logging service with device/environment info collection
//

import Foundation
import UIKit

// MARK: - Device Info

struct DeviceInfo: Codable {
    let model: String
    let osVersion: String
    let language: String
    let appVersion: String
    let buildNumber: String
    let deviceId: String  // Anonymous device identifier
    
    static var current: DeviceInfo {
        let device = UIDevice.current
        let bundle = Bundle.main
        
        return DeviceInfo(
            model: deviceModelName(),
            osVersion: "\(device.systemName) \(device.systemVersion)",
            language: Locale.current.identifier,
            appVersion: bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            buildNumber: bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            deviceId: anonymousDeviceId()
        )
    }
    
    /// Get human-readable device model name
    private static func deviceModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        // Map common identifiers to friendly names
        let modelMap: [String: String] = [
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus",
            "x86_64": "Simulator (Intel)",
            "arm64": "Simulator (Apple Silicon)"
        ]
        
        return modelMap[identifier] ?? identifier
    }
    
    /// Generate anonymous device identifier (persisted in UserDefaults)
    private static func anonymousDeviceId() -> String {
        let key = "anonymous_device_id"
        if let existingId = UserDefaults.standard.string(forKey: key) {
            return existingId
        }
        let newId = UUID().uuidString.prefix(8).lowercased()
        UserDefaults.standard.set(String(newId), forKey: key)
        return String(newId)
    }
}

// MARK: - Error Log Entry

struct ErrorLog: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let errorCode: String?
    let errorMessage: String
    let errorDomain: String?
    let context: String
    let stackTrace: String?
    let deviceInfo: DeviceInfo
    
    init(
        error: Error?,
        message: String? = nil,
        code: String? = nil,
        context: ErrorContext
    ) {
        self.id = UUID()
        self.timestamp = Date()
        
        if let nsError = error as NSError? {
            self.errorCode = code ?? String(nsError.code)
            self.errorMessage = message ?? nsError.localizedDescription
            self.errorDomain = nsError.domain
        } else if let error = error {
            self.errorCode = code
            self.errorMessage = message ?? error.localizedDescription
            self.errorDomain = nil
        } else {
            self.errorCode = code
            self.errorMessage = message ?? "Unknown error"
            self.errorDomain = nil
        }
        
        self.context = context.description
        self.stackTrace = Thread.callStackSymbols.joined(separator: "\n")
        self.deviceInfo = DeviceInfo.current
    }
    
    /// Formatted string for display/reporting
    var formatted: String {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var lines: [String] = []
        lines.append("=== Error Log ===")
        lines.append("Time: \(dateFormatter.string(from: timestamp))")
        lines.append("Context: \(context)")
        
        if let code = errorCode {
            lines.append("Code: \(code)")
        }
        if let domain = errorDomain {
            lines.append("Domain: \(domain)")
        }
        lines.append("Message: \(errorMessage)")
        
        lines.append("")
        lines.append("--- Device Info ---")
        lines.append("Model: \(deviceInfo.model)")
        lines.append("OS: \(deviceInfo.osVersion)")
        lines.append("Language: \(deviceInfo.language)")
        lines.append("App Version: \(deviceInfo.appVersion) (\(deviceInfo.buildNumber))")
        lines.append("Device ID: \(deviceInfo.deviceId)")
        
        return lines.joined(separator: "\n")
    }
    
    /// JSON representation for API reporting
    var jsonData: Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(self)
    }
}

// MARK: - Error Logger

class ErrorLogger {
    static let shared = ErrorLogger()
    
    private let maxStoredLogs = 100
    private let logsKey = "stored_error_logs"
    
    private init() {}
    
    // MARK: - Logging
    
    /// Log an error with context
    func log(error: Error, context: ErrorContext) {
        let logEntry = ErrorLog(error: error, context: context)
        store(logEntry)
        printToConsole(logEntry)
    }
    
    /// Log an error message with optional code
    func log(message: String, code: String? = nil, context: ErrorContext) {
        let logEntry = ErrorLog(error: nil, message: message, code: code, context: context)
        store(logEntry)
        printToConsole(logEntry)
    }
    
    // MARK: - Storage
    
    /// Store log entry locally
    private func store(_ entry: ErrorLog) {
        var logs = getStoredLogs()
        logs.insert(entry, at: 0)
        
        // Keep only recent logs
        if logs.count > maxStoredLogs {
            logs = Array(logs.prefix(maxStoredLogs))
        }
        
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: logsKey)
        }
    }
    
    /// Get all stored logs
    func getStoredLogs() -> [ErrorLog] {
        guard let data = UserDefaults.standard.data(forKey: logsKey),
              let logs = try? JSONDecoder().decode([ErrorLog].self, from: data) else {
            return []
        }
        return logs
    }
    
    /// Get recent logs (last 24 hours)
    func getRecentLogs() -> [ErrorLog] {
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        return getStoredLogs().filter { $0.timestamp > cutoff }
    }
    
    /// Clear all stored logs
    func clearLogs() {
        UserDefaults.standard.removeObject(forKey: logsKey)
    }
    
    /// Export logs as JSON string
    func exportLogs() -> String? {
        let logs = getStoredLogs()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        
        guard let data = try? encoder.encode(logs) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Console Output
    
    private func printToConsole(_ entry: ErrorLog) {
        #if DEBUG
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔴 ERROR: \(entry.context)")
        if let code = entry.errorCode {
            print("   Code: \(code)")
        }
        print("   Message: \(entry.errorMessage)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        #endif
    }
}

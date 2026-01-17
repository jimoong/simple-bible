//
//  FeedbackManager.swift
//  BibleApp
//
//  Centralized manager for user feedback UI (Toast, Alert) and error reporting
//

import SwiftUI

// MARK: - Toast Types

enum ToastType {
    case error
    case warning
    case success
    case info
    
    var icon: String {
        switch self {
        case .error: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .error: return .red
        case .warning: return .yellow
        case .success: return .green
        case .info: return .blue
        }
    }
    
    var duration: Double {
        switch self {
        case .error: return 5.0
        case .warning: return 4.0
        case .success: return 3.0
        case .info: return 3.0
        }
    }
}

// MARK: - Alert Action

struct AlertAction: Identifiable {
    let id = UUID()
    let title: String
    let role: ButtonRole?
    let handler: () -> Void
    
    init(_ title: String, role: ButtonRole? = nil, handler: @escaping () -> Void = {}) {
        self.title = title
        self.role = role
        self.handler = handler
    }
}

// MARK: - Error Context

struct ErrorContext {
    let service: String
    let action: String
    let additionalInfo: [String: String]
    
    init(service: String, action: String, additionalInfo: [String: String] = [:]) {
        self.service = service
        self.action = action
        self.additionalInfo = additionalInfo
    }
    
    var description: String {
        var desc = "\(service).\(action)"
        if !additionalInfo.isEmpty {
            let info = additionalInfo.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            desc += " [\(info)]"
        }
        return desc
    }
}

// MARK: - Feedback Manager

@Observable
class FeedbackManager {
    static let shared = FeedbackManager()
    
    // MARK: - Toast State
    var showToast = false
    var toastMessage = ""
    var toastType: ToastType = .info
    var toastActionLabel: String? = nil
    var toastAction: (() -> Void)? = nil
    
    // MARK: - Alert State
    var showAlert = false
    var alertTitle = ""
    var alertMessage = ""
    var alertPrimaryAction: AlertAction?
    var alertSecondaryAction: AlertAction?
    
    private init() {}
    
    // MARK: - Toast Methods
    
    /// Show a toast notification
    /// - Parameters:
    ///   - message: The message to display
    ///   - type: The type of toast (error, warning, success, info)
    ///   - actionLabel: Optional action button label
    ///   - action: Optional action callback
    func showToast(_ message: String, type: ToastType = .info, actionLabel: String? = nil, action: (() -> Void)? = nil) {
        Task { @MainActor in
            // If a toast is already showing, dismiss it first
            if showToast {
                showToast = false
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay
            }
            
            toastMessage = message
            toastType = type
            toastActionLabel = actionLabel
            toastAction = action
            showToast = true
        }
    }
    
    /// Show an error toast
    func showError(_ message: String) {
        showToast(message, type: .error)
    }
    
    /// Show a warning toast
    func showWarning(_ message: String) {
        showToast(message, type: .warning)
    }
    
    /// Show a success toast
    func showSuccess(_ message: String, actionLabel: String? = nil, action: (() -> Void)? = nil) {
        showToast(message, type: .success, actionLabel: actionLabel, action: action)
    }
    
    /// Show an info toast
    func showInfo(_ message: String) {
        showToast(message, type: .info)
    }
    
    /// Dismiss the current toast
    func dismissToast() {
        showToast = false
        toastActionLabel = nil
        toastAction = nil
    }
    
    // MARK: - Alert Methods
    
    /// Show a confirmation dialog with primary and optional secondary actions
    /// - Parameters:
    ///   - title: Alert title
    ///   - message: Alert message
    ///   - primaryButton: Primary action button title
    ///   - primaryRole: Primary button role (nil, .destructive, .cancel)
    ///   - onPrimary: Primary action handler
    ///   - secondaryButton: Secondary action button title (optional, defaults to cancel)
    ///   - onSecondary: Secondary action handler
    func showConfirmation(
        title: String,
        message: String,
        primaryButton: String,
        primaryRole: ButtonRole? = nil,
        onPrimary: @escaping () -> Void,
        secondaryButton: String? = nil,
        onSecondary: @escaping () -> Void = {}
    ) {
        Task { @MainActor in
            alertTitle = title
            alertMessage = message
            alertPrimaryAction = AlertAction(primaryButton, role: primaryRole, handler: onPrimary)
            
            if let secondary = secondaryButton {
                alertSecondaryAction = AlertAction(secondary, role: .cancel, handler: onSecondary)
            } else {
                alertSecondaryAction = AlertAction("취소", role: .cancel, handler: onSecondary)
            }
            
            showAlert = true
        }
    }
    
    /// Show a simple alert with just an OK button
    func showAlert(title: String, message: String) {
        Task { @MainActor in
            alertTitle = title
            alertMessage = message
            alertPrimaryAction = AlertAction("확인", handler: {})
            alertSecondaryAction = nil
            showAlert = true
        }
    }
    
    // MARK: - Error Reporting
    
    /// Report an error for logging and potential remote reporting
    /// - Parameters:
    ///   - error: The error that occurred
    ///   - context: Context information about where the error occurred
    ///   - showToast: Whether to show a toast to the user (default: true)
    ///   - userMessage: Custom user-facing message (optional)
    func reportError(
        _ error: Error,
        context: ErrorContext,
        showToast: Bool = true,
        userMessage: String? = nil
    ) {
        // Log the error
        ErrorLogger.shared.log(error: error, context: context)
        
        // Show toast if requested
        if showToast {
            let message = userMessage ?? defaultUserMessage(for: error, context: context)
            self.showToast(message, type: .error)
        }
        
        // Report critical errors
        if shouldReportRemotely(error: error) {
            Task {
                await ErrorReporter.shared.report(error: error, context: context)
            }
        }
    }
    
    /// Report an error with just a message (no Error object)
    func reportError(
        message: String,
        code: String? = nil,
        context: ErrorContext,
        showToast: Bool = true,
        userMessage: String? = nil
    ) {
        // Log the error
        ErrorLogger.shared.log(message: message, code: code, context: context)
        
        // Show toast if requested
        if showToast {
            self.showToast(userMessage ?? message, type: .error)
        }
        
        // Report to remote
        Task {
            await ErrorReporter.shared.report(message: message, code: code, context: context)
        }
    }
    
    // MARK: - Private Helpers
    
    private func defaultUserMessage(for error: Error, context: ErrorContext) -> String {
        // Provide user-friendly messages based on context
        switch context.service {
        case "TTSService":
            return "음성 변환에 문제가 있습니다"
        case "GamalielService":
            return "AI 응답을 가져오는데 문제가 있습니다"
        case "BibleAPIService":
            return "성경 데이터를 불러오는데 문제가 있습니다"
        case "VoiceSearchService":
            return "음성 인식에 문제가 있습니다"
        default:
            return "문제가 발생했습니다"
        }
    }
    
    private func shouldReportRemotely(error: Error) -> Bool {
        // Report all errors for now - can be filtered later
        // Skip cancellation errors
        if (error as NSError).code == NSURLErrorCancelled {
            return false
        }
        return true
    }
}

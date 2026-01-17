//
//  AppToast.swift
//  BibleApp
//
//  Global toast notification component with glass style
//

import SwiftUI

// MARK: - App Toast View

struct AppToast: View {
    let message: String
    let type: ToastType
    var actionLabel: String? = nil
    var onAction: (() -> Void)? = nil
    var onDismiss: () -> Void
    
    private var showIcon: Bool {
        type == .error
    }
    
    var body: some View {
        HStack(spacing: showIcon ? 10 : 0) {
            // Status icon (only for error type)
            if showIcon {
                Image(systemName: type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(type.color)
            }
            
            // Message
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            // Action button (optional)
            if let label = actionLabel, let action = onAction {
                Button {
                    action()
                    onDismiss()
                } label: {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            
            // Close button
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(.white.opacity(0.1))
                    )
            }
            .buttonStyle(.plain)
            .padding(.leading, actionLabel != nil ? 4 : 12)
        }
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .padding(.vertical, 12)
        .glassBackground(.roundedRect(radius: 14), intensity: .regular)
    }
}

// MARK: - Toast Container with Animation

struct AppToastContainer: View {
    @State private var feedbackManager = FeedbackManager.shared
    
    @State private var opacity: Double = 0
    @State private var offsetY: CGFloat = -20
    @State private var dragOffset: CGFloat = 0
    @State private var dismissTask: Task<Void, Never>?
    
    private let animationDuration: Double = 0.35
    private let swipeThreshold: CGFloat = -30
    
    var body: some View {
        VStack {
            if feedbackManager.showToast {
                HStack {
                    Spacer(minLength: 16)
                    
                    AppToast(
                        message: feedbackManager.toastMessage,
                        type: feedbackManager.toastType,
                        actionLabel: feedbackManager.toastActionLabel,
                        onAction: feedbackManager.toastAction,
                        onDismiss: {
                            dismissToast()
                        }
                    )
                    
                    Spacer(minLength: 16)
                }
                .padding(.top, 8)
                .opacity(opacity)
                .offset(y: offsetY + dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow upward drag
                            if value.translation.height < 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height < swipeThreshold {
                                // Swipe up detected - dismiss
                                dismissToast()
                            } else {
                                // Snap back
                                withAnimation(.easeOut(duration: 0.2)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                .onAppear {
                    startDisplayTimer()
                }
                .onChange(of: feedbackManager.toastMessage) { _, _ in
                    // Reset animation when message changes
                    startDisplayTimer()
                }
            }
            Spacer()
        }
        .allowsHitTesting(feedbackManager.showToast)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: feedbackManager.showToast)
    }
    
    private func startDisplayTimer() {
        // Cancel any existing timer
        dismissTask?.cancel()
        
        // Reset to initial state
        opacity = 0
        offsetY = -20
        dragOffset = 0
        
        // Slide down + fade in
        withAnimation(.easeOut(duration: animationDuration)) {
            opacity = 1
            offsetY = 0
        }
        
        // Schedule auto-dismiss based on toast type
        let duration = feedbackManager.toastType.duration
        dismissTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                dismissToast()
            }
        }
    }
    
    private func dismissToast() {
        dismissTask?.cancel()
        
        // Slide up + fade out
        withAnimation(.easeOut(duration: animationDuration)) {
            opacity = 0
            offsetY = -20
            dragOffset = 0
        }
        
        // Actually hide after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            feedbackManager.dismissToast()
        }
    }
}

// MARK: - Alert Modifier

struct AppAlertModifier: ViewModifier {
    @State private var feedbackManager = FeedbackManager.shared
    
    func body(content: Content) -> some View {
        content
            .alert(
                feedbackManager.alertTitle,
                isPresented: Binding(
                    get: { feedbackManager.showAlert },
                    set: { feedbackManager.showAlert = $0 }
                )
            ) {
                if let primary = feedbackManager.alertPrimaryAction {
                    Button(primary.title, role: primary.role) {
                        primary.handler()
                    }
                }
                
                if let secondary = feedbackManager.alertSecondaryAction {
                    Button(secondary.title, role: secondary.role) {
                        secondary.handler()
                    }
                }
            } message: {
                Text(feedbackManager.alertMessage)
            }
    }
}

extension View {
    /// Add app-wide alert support
    func appAlert() -> some View {
        self.modifier(AppAlertModifier())
    }
}

// MARK: - Preview

#Preview("Toast Types") {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.06, green: 0.04, blue: 0.12), Color(red: 0.04, green: 0.03, blue: 0.10)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack(spacing: 16) {
            // Error - with icon
            HStack {
                Spacer()
                AppToast(
                    message: "음성 변환에 문제가 있습니다",
                    type: .error,
                    onDismiss: {}
                )
                Spacer()
            }
            
            // Success - no icon, short message
            HStack {
                Spacer()
                AppToast(
                    message: "복사됨",
                    type: .success,
                    onDismiss: {}
                )
                Spacer()
            }
            
            // Success with action
            HStack {
                Spacer()
                AppToast(
                    message: "저장했어요",
                    type: .success,
                    actionLabel: "목록 보기",
                    onAction: { print("View list") },
                    onDismiss: {}
                )
                Spacer()
            }
            
            // Info - no icon, long message wraps
            HStack {
                Spacer(minLength: 16)
                AppToast(
                    message: "오프라인 모드로 전환되었습니다. 인터넷 연결을 확인해주세요.",
                    type: .info,
                    onDismiss: {}
                )
                Spacer(minLength: 16)
            }
        }
    }
}

#Preview("Toast Container") {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.06, green: 0.04, blue: 0.12), Color(red: 0.04, green: 0.03, blue: 0.10)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            Button("Show Error Toast") {
                FeedbackManager.shared.showError("음성 변환에 문제가 있습니다")
            }
            .buttonStyle(.glass)
            .foregroundStyle(.white)
            .padding()
            
            Button("Show Success Toast") {
                FeedbackManager.shared.showSuccess("저장했어요", actionLabel: "목록 보기") {
                    print("View list")
                }
            }
            .buttonStyle(.glass)
            .foregroundStyle(.white)
            .padding()
            
            Button("Show Alert") {
                FeedbackManager.shared.showConfirmation(
                    title: "AI 응답 중단",
                    message: "AI 응답이 중단되었습니다. 다시 시작하시겠습니까?",
                    primaryButton: "다시 시작",
                    onPrimary: {
                        print("Restart")
                    }
                )
            }
            .buttonStyle(.glass)
            .foregroundStyle(.white)
            .padding()
            
            Spacer()
        }
    }
    .overlay(alignment: .top) {
        AppToastContainer()
            .padding(.top, 50)
    }
    .appAlert()
}

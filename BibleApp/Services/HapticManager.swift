import UIKit

final class HapticManager {
    static let shared = HapticManager()
    
    #if targetEnvironment(simulator)
    private let isSimulator = true
    #else
    private let isSimulator = false
    #endif
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        guard !isSimulator else { return }
        // Prepare generators for low latency
        lightGenerator.prepare()
        mediumGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    /// Light click haptic - used for verse snap
    func lightClick() {
        guard !isSimulator else { return }
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }
    
    /// Medium click haptic - used for chapter transitions
    func mediumClick() {
        guard !isSimulator else { return }
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }
    
    /// Heavy click haptic - used for significant actions
    func heavyClick() {
        guard !isSimulator else { return }
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }
    
    /// Selection haptic - used for UI selections
    func selection() {
        guard !isSimulator else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
    
    /// Success notification haptic - used for successful actions
    func success() {
        guard !isSimulator else { return }
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    /// Warning notification haptic
    func warning() {
        guard !isSimulator else { return }
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    /// Error notification haptic
    func error() {
        guard !isSimulator else { return }
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    /// Prepare all generators (call before intensive UI)
    func prepareAll() {
        guard !isSimulator else { return }
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
}

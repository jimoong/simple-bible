import UIKit

final class HapticManager {
    static let shared = HapticManager()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        // Prepare generators for low latency
        lightGenerator.prepare()
        mediumGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    /// Light click haptic - used for verse snap
    func lightClick() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }
    
    /// Medium click haptic - used for chapter transitions
    func mediumClick() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }
    
    /// Heavy click haptic - used for significant actions
    func heavyClick() {
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }
    
    /// Selection haptic - used for UI selections
    func selection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
    
    /// Success notification haptic - used for successful actions
    func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    /// Warning notification haptic
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    /// Error notification haptic
    func error() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    /// Prepare all generators (call before intensive UI)
    func prepareAll() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
}

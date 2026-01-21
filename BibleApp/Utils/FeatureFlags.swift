import Foundation

/// Feature flags for controlling app behavior between development and production builds
enum FeatureFlags {
    
    // MARK: - Build Configuration
    
    /// Controls whether development-only features are enabled
    /// Set to `true` for development/testing, `false` for App Store release
    ///
    /// Features hidden behind this flag:
    /// - Developer section in Settings (Cache clear, App reset)
    /// - API-based Bible translation picker (language selection)
    /// - Other debug/testing features
    ///
    /// To enable development mode:
    /// 1. Change this value to `true`
    /// 2. Or use DEBUG build configuration (automatically enabled)
    ///
    static var isDevelopment: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Feature Toggles
    
    /// Enables the developer section in Settings (Clear cache, Reset app)
    static var showDeveloperSettings: Bool {
        isDevelopment
    }
    
    /// Enables API-based translation picker for selecting Bible versions
    /// When disabled, tapping language items in Settings will have no action
    static var enableTranslationPicker: Bool {
        isDevelopment
    }
    
    /// Enables verbose logging throughout the app
    static var enableVerboseLogging: Bool {
        isDevelopment
    }
}

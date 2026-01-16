import SwiftUI

// MARK: - Font Size Mode
enum FontSizeMode: String, CaseIterable {
    case regular
    case large
    
    var displayName: String {
        switch self {
        case .regular: return "Regular"
        case .large: return "Large"
        }
    }
    
    func displayName(for language: LanguageMode) -> String {
        switch self {
        case .regular: return language == .kr ? "보통" : "Regular"
        case .large: return language == .kr ? "크게" : "Large"
        }
    }
    
    // MARK: - Font Sizes
    
    /// Scroll mode verse text (BookReadingView)
    var scrollBodySize: CGFloat {
        switch self {
        case .regular: return 17
        case .large: return 19
        }
    }
    
    /// Chat message text (GamalielChatView)
    var chatMessageSize: CGFloat {
        switch self {
        case .regular: return 17
        case .large: return 19
        }
    }
    
    /// Settings label text
    var settingsLabelSize: CGFloat {
        switch self {
        case .regular: return 16
        case .large: return 18
        }
    }
    
    /// Button label text (FAB, etc.)
    var buttonLabelSize: CGFloat {
        switch self {
        case .regular: return 14
        case .large: return 16
        }
    }
    
    // MARK: - Line Spacing (proportional)
    
    /// Line spacing for scroll mode verse text
    var scrollLineSpacing: CGFloat {
        switch self {
        case .regular: return 6
        case .large: return 7
        }
    }
    
    /// Line spacing for chat messages
    var chatLineSpacing: CGFloat {
        switch self {
        case .regular: return 4
        case .large: return 5
        }
    }
    
    // MARK: - Secondary Sizes (scaled proportionally)
    
    /// Verse number size in scroll mode
    var verseNumberSize: CGFloat {
        switch self {
        case .regular: return 12
        case .large: return 13
        }
    }
    
    /// Settings secondary text (like email, version)
    var settingsSecondarySize: CGFloat {
        switch self {
        case .regular: return 14
        case .large: return 16
        }
    }
    
    /// Section header size
    var sectionHeaderSize: CGFloat {
        switch self {
        case .regular: return 12
        case .large: return 13
        }
    }
}

// MARK: - Font Size Settings Manager
@MainActor
class FontSizeSettings: ObservableObject {
    static let shared = FontSizeSettings()
    
    @Published var mode: FontSizeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "fontSizeMode")
        }
    }
    
    private init() {
        if let savedMode = UserDefaults.standard.string(forKey: "fontSizeMode"),
           let mode = FontSizeMode(rawValue: savedMode) {
            self.mode = mode
        } else {
            self.mode = .regular
        }
    }
}

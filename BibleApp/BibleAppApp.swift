import SwiftUI

@main
struct BibleAppApp: App {
    
    init() {
        // Debug: print font status
        #if DEBUG
        FontManager.debugPrintFontStatus()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .preferredColorScheme(.dark)
        }
    }
}

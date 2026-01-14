import SwiftUI

@main
struct BibleAppApp: App {
    
    init() {
        // Uncomment to debug font loading issues:
        // FontManager.debugPrintFontStatus()
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .preferredColorScheme(.dark)
        }
    }
}

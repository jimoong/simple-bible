import SwiftUI
import UIKit

/// Font manager for multi-language typography
enum FontManager {
    
    // MARK: - Static Font Names (PostScript names match filename without extension)
    
    static let serifFonts: [Font.Weight: String] = [
        .ultraLight: "NotoSerifKR-ExtraLight",
        .thin: "NotoSerifKR-ExtraLight",
        .light: "NotoSerifKR-Light",
        .regular: "NotoSerifKR-Regular",
        .medium: "NotoSerifKR-Medium",
        .semibold: "NotoSerifKR-SemiBold",
        .bold: "NotoSerifKR-Bold",
        .heavy: "NotoSerifKR-ExtraBold",
        .black: "NotoSerifKR-Black"
    ]
    
    static let sansFonts: [Font.Weight: String] = [
        .ultraLight: "NotoSansKR-ExtraLight",
        .thin: "NotoSansKR-Thin",
        .light: "NotoSansKR-Light",
        .regular: "NotoSansKR-Regular",
        .medium: "NotoSansKR-Medium",
        .semibold: "NotoSansKR-SemiBold",
        .bold: "NotoSansKR-Bold",
        .heavy: "NotoSansKR-ExtraBold",
        .black: "NotoSansKR-Black"
    ]
    
    // MARK: - iOS Fallbacks
    
    static let appleMyungjo = "AppleMyungjo"
    
    // MARK: - Font Availability
    
    static var hasNotoSerifKR: Bool {
        UIFont(name: "NotoSerifKR-Regular", size: 12) != nil
    }
    
    static var hasNotoSansKR: Bool {
        UIFont(name: "NotoSansKR-Regular", size: 12) != nil
    }
    
    // MARK: - Korean Font Getters
    
    /// Get Korean font matching the specified design (serif or sans-serif)
    static func korean(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design) -> Font {
        switch design {
        case .serif:
            return koreanSerif(size: size, weight: weight)
        default:
            return koreanSans(size: size, weight: weight)
        }
    }
    
    /// Korean serif font using Noto Serif KR
    static func koreanSerif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Map to closest available weight
        let targetWeight = closestWeight(weight, in: serifFonts)
        
        if let fontName = serifFonts[targetWeight],
           UIFont(name: fontName, size: size) != nil {
            #if DEBUG
            print("🔤 Using serif: \(fontName)")
            #endif
            return .custom(fontName, size: size)
        }
        
        // Fallback to AppleMyungjo
        if UIFont(name: appleMyungjo, size: size) != nil {
            #if DEBUG
            print("🔤 Serif fallback: AppleMyungjo")
            #endif
            return .custom(appleMyungjo, size: size)
        }
        
        #if DEBUG
        print("🔤 Serif fallback: system serif")
        #endif
        return .system(size: size, weight: weight, design: .serif)
    }
    
    /// Korean sans-serif font using Noto Sans KR
    static func koreanSans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Map to closest available weight
        let targetWeight = closestWeight(weight, in: sansFonts)
        
        if let fontName = sansFonts[targetWeight],
           UIFont(name: fontName, size: size) != nil {
            #if DEBUG
            print("🔤 Using sans: \(fontName)")
            #endif
            return .custom(fontName, size: size)
        }
        
        // Fallback to Apple SD Gothic Neo
        let sdGothicName = appleSDGothicName(for: weight)
        if UIFont(name: sdGothicName, size: size) != nil {
            #if DEBUG
            print("🔤 Sans fallback: \(sdGothicName)")
            #endif
            return .custom(sdGothicName, size: size)
        }
        
        #if DEBUG
        print("🔤 Sans fallback: system default")
        #endif
        return .system(size: size, weight: weight, design: .default)
    }
    
    // MARK: - Helpers
    
    private static func closestWeight(_ weight: Font.Weight, in fonts: [Font.Weight: String]) -> Font.Weight {
        if fonts[weight] != nil { return weight }
        return .regular
    }
    
    private static func appleSDGothicName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin:
            return "AppleSDGothicNeo-Thin"
        case .light:
            return "AppleSDGothicNeo-Light"
        case .medium:
            return "AppleSDGothicNeo-Medium"
        case .semibold:
            return "AppleSDGothicNeo-SemiBold"
        case .bold, .heavy, .black:
            return "AppleSDGothicNeo-Bold"
        default:
            return "AppleSDGothicNeo-Regular"
        }
    }
    
    // MARK: - Debug
    
    static func debugPrintFontStatus() {
        print("")
        print("═══════════════════════════════════════════════════════")
        print("🔍 FONT STATUS")
        print("═══════════════════════════════════════════════════════")
        
        // Check Noto Serif KR
        print("\n📖 Noto Serif KR (checking each weight):")
        for (_, name) in serifFonts.sorted(by: { weightOrder($0.key) < weightOrder($1.key) }) {
            let available = UIFont(name: name, size: 12) != nil
            print("   \(available ? "✓" : "✗") \(name)")
        }
        
        // Check Noto Sans KR
        print("\n📝 Noto Sans KR (checking each weight):")
        for (_, name) in sansFonts.sorted(by: { weightOrder($0.key) < weightOrder($1.key) }) {
            let available = UIFont(name: name, size: 12) != nil
            print("   \(available ? "✓" : "✗") \(name)")
        }
        
        // Check fallbacks
        print("\n🔄 Fallbacks:")
        print("   \(UIFont(name: appleMyungjo, size: 12) != nil ? "✓" : "✗") AppleMyungjo (serif)")
        print("   \(UIFont(name: "AppleSDGothicNeo-Regular", size: 12) != nil ? "✓" : "✗") Apple SD Gothic Neo (sans)")
        
        // List ALL registered font families
        print("\n📋 ALL registered font families (looking for Noto):")
        var foundNoto = false
        for family in UIFont.familyNames.sorted() {
            let lower = family.lowercased()
            if lower.contains("noto") || lower.contains("serif") && lower.contains("kr") {
                foundNoto = true
                print("   Family: '\(family)'")
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("      → '\(name)'")
                }
            }
        }
        if !foundNoto {
            print("   ⚠️  NO Noto fonts found! Fonts may not be bundled.")
            print("   ℹ️  Make sure to:")
            print("      1. Add font files to Fonts/ folder")
            print("      2. Clean build (⇧⌘K)")
            print("      3. Build and run again")
        }
        
        print("═══════════════════════════════════════════════════════")
        print("")
    }
    
    private static func weightOrder(_ weight: Font.Weight) -> Int {
        switch weight {
        case .ultraLight: return 0
        case .thin: return 1
        case .light: return 2
        case .regular: return 3
        case .medium: return 4
        case .semibold: return 5
        case .bold: return 6
        case .heavy: return 7
        case .black: return 8
        default: return 3
        }
    }
}

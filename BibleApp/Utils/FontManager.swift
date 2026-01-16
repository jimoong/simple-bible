import SwiftUI
import UIKit

/// Font manager for multi-language typography using Variable Fonts
enum FontManager {
    
    // MARK: - Variable Font Names
    
    /// Noto Serif KR Variable font family name
    static let serifFontFamily = "Noto Serif KR"
    
    /// Noto Sans KR Variable font family name  
    static let sansFontFamily = "Noto Sans KR"
    
    /// Spectral font family name (English serif - optimized for screen reading)
    static let englishSerifFontFamily = "Spectral"
    
    // MARK: - iOS Fallbacks
    
    static let appleMyungjo = "AppleMyungjo"
    
    // MARK: - Font Availability
    
    static var hasNotoSerifKR: Bool {
        UIFont.familyNames.contains(serifFontFamily)
    }
    
    static var hasNotoSansKR: Bool {
        UIFont.familyNames.contains(sansFontFamily)
    }
    
    static var hasSpectral: Bool {
        UIFont.familyNames.contains(englishSerifFontFamily)
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
    
    /// Korean serif font using Noto Serif KR Variable Font
    static func koreanSerif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if hasNotoSerifKR,
           let uiFont = createVariableFont(family: serifFontFamily, size: size, weight: weight) {
            return Font(uiFont)
        }
        
        // Fallback to AppleMyungjo
        if UIFont(name: appleMyungjo, size: size) != nil {
            return .custom(appleMyungjo, size: size)
        }
        
        return .system(size: size, weight: weight, design: .serif)
    }
    
    /// English serif font using Spectral (optimized for screen reading)
    static func englishSerif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if hasSpectral {
            let fontName = spectralFontName(for: weight)
            if UIFont(name: fontName, size: size) != nil {
                return .custom(fontName, size: size)
            }
        }
        
        // Fallback to system serif
        return .system(size: size, weight: weight, design: .serif)
    }
    
    /// Korean sans-serif font using Noto Sans KR Variable Font
    static func koreanSans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if hasNotoSansKR,
           let uiFont = createVariableFont(family: sansFontFamily, size: size, weight: weight) {
            return Font(uiFont)
        }
        
        // Fallback to Apple SD Gothic Neo
        let sdGothicName = appleSDGothicName(for: weight)
        if UIFont(name: sdGothicName, size: size) != nil {
            return .custom(sdGothicName, size: size)
        }
        
        return .system(size: size, weight: weight, design: .default)
    }
    
    // MARK: - Variable Font Creation
    
    /// Create a UIFont from a variable font family with specific weight
    private static func createVariableFont(family: String, size: CGFloat, weight: Font.Weight) -> UIFont? {
        let uiWeight = uiFontWeight(from: weight)
        
        // Create font descriptor with family and weight traits
        let descriptor = UIFontDescriptor(fontAttributes: [
            .family: family,
            .traits: [
                UIFontDescriptor.TraitKey.weight: uiWeight
            ]
        ])
        
        return UIFont(descriptor: descriptor, size: size)
    }
    
    /// Convert SwiftUI Font.Weight to UIFont.Weight
    private static func uiFontWeight(from weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
    
    // MARK: - Helpers
    
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
    
    private static func spectralFontName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light:
            return "Spectral-Light"
        case .medium:
            return "Spectral-Medium"
        case .semibold:
            return "Spectral-SemiBold"
        case .bold, .heavy, .black:
            return "Spectral-Bold"
        default:
            return "Spectral-Regular"
        }
    }
    
    // MARK: - Debug
    
    static func debugPrintFontStatus() {
        print("")
        print("═══════════════════════════════════════════════════════")
        print("🔍 FONT STATUS (Variable Fonts)")
        print("═══════════════════════════════════════════════════════")
        
        // Check Variable Fonts
        print("\n📖 Noto Serif KR Variable:")
        print("   \(hasNotoSerifKR ? "✓" : "✗") Family available: \(serifFontFamily)")
        if hasNotoSerifKR {
            let weights: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
            for weight in weights {
                if let font = createVariableFont(family: serifFontFamily, size: 12, weight: weight) {
                    print("   ✓ \(weightName(weight)): \(font.fontName)")
                }
            }
        }
        
        print("\n📝 Noto Sans KR Variable:")
        print("   \(hasNotoSansKR ? "✓" : "✗") Family available: \(sansFontFamily)")
        if hasNotoSansKR {
            let weights: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
            for weight in weights {
                if let font = createVariableFont(family: sansFontFamily, size: 12, weight: weight) {
                    print("   ✓ \(weightName(weight)): \(font.fontName)")
                }
            }
        }
        
        // Check English Serif
        print("\n📜 Spectral (English Serif):")
        print("   \(hasSpectral ? "✓" : "✗") Family available: \(englishSerifFontFamily)")
        if hasSpectral {
            let weights: [Font.Weight] = [.light, .regular, .medium, .semibold, .bold]
            for weight in weights {
                let fontName = spectralFontName(for: weight)
                let available = UIFont(name: fontName, size: 12) != nil
                print("   \(available ? "✓" : "✗") \(weightName(weight)): \(fontName)")
            }
        }
        
        // Check fallbacks
        print("\n🔄 Fallbacks:")
        print("   \(UIFont(name: appleMyungjo, size: 12) != nil ? "✓" : "✗") AppleMyungjo (serif)")
        print("   \(UIFont(name: "AppleSDGothicNeo-Regular", size: 12) != nil ? "✓" : "✗") Apple SD Gothic Neo (sans)")
        
        // List ALL registered font families containing "Noto"
        print("\n📋 Registered Noto font families:")
        var foundNoto = false
        for family in UIFont.familyNames.sorted() {
            let lower = family.lowercased()
            if lower.contains("noto") {
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
    
    private static func weightName(_ weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight: return "UltraLight"
        case .thin: return "Thin"
        case .light: return "Light"
        case .regular: return "Regular"
        case .medium: return "Medium"
        case .semibold: return "SemiBold"
        case .bold: return "Bold"
        case .heavy: return "Heavy"
        case .black: return "Black"
        default: return "Unknown"
        }
    }
}

import SwiftUI

struct BookTheme {
    let background: Color
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let highlightAccent: Color  // Vibrant complementary color for text highlights
    
    // Typography style - applies to BOTH English and Korean
    let titleFont: Font.Design  // .serif, .default (sans), .rounded, .monospaced
    let bodyFont: Font.Design
    
    // MARK: - Font Methods
    
    /// Verse number font
    func verseNumber(_ size: CGFloat = 15, weight: Font.Weight = .regular, language: LanguageMode = .en) -> Font {
        fontFor(size: size, weight: weight, design: titleFont, language: language)
    }
    
    /// Main verse text font - respects theme's bodyFont design for both languages
    func verseText(_ size: CGFloat = 22, weight: Font.Weight = .regular, language: LanguageMode = .en) -> Font {
        fontFor(size: size, weight: weight, design: bodyFont, language: language)
    }
    
    /// Header/title font
    func header(_ size: CGFloat = 15, language: LanguageMode = .en) -> Font {
        fontFor(size: size, weight: .semibold, design: titleFont, language: language)
    }
    
    /// Display/large title font
    func display(_ size: CGFloat = 28, language: LanguageMode = .en) -> Font {
        fontFor(size: size, weight: .bold, design: titleFont, language: language)
    }
    
    /// Generic font getter that handles both languages
    private func fontFor(size: CGFloat, weight: Font.Weight, design: Font.Design, language: LanguageMode) -> Font {
        switch language {
        case .en:
            // English uses Spectral for serif, system fonts for others
            if design == .serif {
                return FontManager.englishSerif(size: size, weight: weight)
            }
            return .system(size: size, weight: weight, design: design)
        case .kr:
            // Korean uses FontManager to get appropriate Korean font
            return FontManager.korean(size: size, weight: weight, design: design)
        }
    }
}

// MARK: - Book Theme Catalog
enum BookThemes {
    
    // MARK: - Pentateuch (Deep, foundational colors)
    static let genesis = BookTheme(
        background: Color(red: 0.06, green: 0.04, blue: 0.12),
        surface: Color(red: 0.12, green: 0.08, blue: 0.20),
        textPrimary: Color(red: 0.95, green: 0.92, blue: 1.0),
        textSecondary: Color(red: 0.65, green: 0.58, blue: 0.78),
        accent: Color(red: 0.75, green: 0.65, blue: 1.0),
        highlightAccent: Color(red: 0.2, green: 1.0, blue: 0.5),  // Vivid mint
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let exodus = BookTheme(
        background: Color(red: 0.08, green: 0.04, blue: 0.02),
        surface: Color(red: 0.16, green: 0.08, blue: 0.04),
        textPrimary: Color(red: 1.0, green: 0.95, blue: 0.90),
        textSecondary: Color(red: 0.78, green: 0.58, blue: 0.45),
        accent: Color(red: 1.0, green: 0.72, blue: 0.45),
        highlightAccent: Color(red: 0.0, green: 0.9, blue: 1.0),  // Vivid cyan
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let leviticus = BookTheme(
        background: Color(red: 0.04, green: 0.06, blue: 0.08),
        surface: Color(red: 0.08, green: 0.12, blue: 0.16),
        textPrimary: Color(red: 0.92, green: 0.96, blue: 1.0),
        textSecondary: Color(red: 0.55, green: 0.68, blue: 0.82),
        accent: Color(red: 0.65, green: 0.82, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.85, blue: 0.0),  // Vivid gold
        titleFont: .default,
        bodyFont: .default  // Sans-serif
    )
    
    static let numbers = BookTheme(
        background: Color(red: 0.05, green: 0.07, blue: 0.05),
        surface: Color(red: 0.10, green: 0.14, blue: 0.10),
        textPrimary: Color(red: 0.94, green: 0.98, blue: 0.94),
        textSecondary: Color(red: 0.60, green: 0.75, blue: 0.60),
        accent: Color(red: 0.70, green: 0.92, blue: 0.70),
        highlightAccent: Color(red: 1.0, green: 0.3, blue: 0.6),  // Vivid pink
        titleFont: .rounded,
        bodyFont: .default  // Sans-serif
    )
    
    static let deuteronomy = BookTheme(
        background: Color(red: 0.07, green: 0.05, blue: 0.03),
        surface: Color(red: 0.14, green: 0.10, blue: 0.06),
        textPrimary: Color(red: 1.0, green: 0.97, blue: 0.92),
        textSecondary: Color(red: 0.75, green: 0.65, blue: 0.50),
        accent: Color(red: 0.95, green: 0.82, blue: 0.55),
        highlightAccent: Color(red: 0.2, green: 0.8, blue: 1.0),  // Vivid sky blue
        titleFont: .serif,
        bodyFont: .serif
    )
    
    // MARK: - Historical Books (Earthy, grounded tones)
    static let joshua = BookTheme(
        background: Color(red: 0.06, green: 0.05, blue: 0.02),
        surface: Color(red: 0.12, green: 0.10, blue: 0.04),
        textPrimary: Color(red: 1.0, green: 0.98, blue: 0.88),
        textSecondary: Color(red: 0.72, green: 0.68, blue: 0.48),
        accent: Color(red: 0.92, green: 0.85, blue: 0.50),
        highlightAccent: Color(red: 0.2, green: 0.6, blue: 1.0),  // Vivid blue
        titleFont: .default,
        bodyFont: .default
    )
    
    static let judges = BookTheme(
        background: Color(red: 0.08, green: 0.03, blue: 0.03),
        surface: Color(red: 0.16, green: 0.06, blue: 0.06),
        textPrimary: Color(red: 1.0, green: 0.94, blue: 0.94),
        textSecondary: Color(red: 0.82, green: 0.55, blue: 0.55),
        accent: Color(red: 1.0, green: 0.60, blue: 0.55),
        highlightAccent: Color(red: 0.0, green: 1.0, blue: 0.85),  // Vivid teal
        titleFont: .default,
        bodyFont: .default
    )
    
    static let ruth = BookTheme(
        background: Color(red: 0.08, green: 0.05, blue: 0.06),
        surface: Color(red: 0.16, green: 0.10, blue: 0.12),
        textPrimary: Color(red: 1.0, green: 0.96, blue: 0.97),
        textSecondary: Color(red: 0.85, green: 0.65, blue: 0.72),
        accent: Color(red: 1.0, green: 0.75, blue: 0.82),
        highlightAccent: Color(red: 0.2, green: 1.0, blue: 0.7),  // Vivid mint
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let samuel1 = BookTheme(
        background: Color(red: 0.04, green: 0.05, blue: 0.08),
        surface: Color(red: 0.08, green: 0.10, blue: 0.16),
        textPrimary: Color(red: 0.94, green: 0.96, blue: 1.0),
        textSecondary: Color(red: 0.58, green: 0.65, blue: 0.85),
        accent: Color(red: 0.68, green: 0.78, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.85, blue: 0.0),  // Vivid gold
        titleFont: .default,
        bodyFont: .default
    )
    
    static let samuel2 = BookTheme(
        background: Color(red: 0.05, green: 0.04, blue: 0.09),
        surface: Color(red: 0.10, green: 0.08, blue: 0.18),
        textPrimary: Color(red: 0.96, green: 0.94, blue: 1.0),
        textSecondary: Color(red: 0.68, green: 0.62, blue: 0.88),
        accent: Color(red: 0.78, green: 0.72, blue: 1.0),
        highlightAccent: Color(red: 0.8, green: 1.0, blue: 0.0),  // Vivid lime
        titleFont: .default,
        bodyFont: .default
    )
    
    static let kings1 = BookTheme(
        background: Color(red: 0.06, green: 0.06, blue: 0.04),
        surface: Color(red: 0.12, green: 0.12, blue: 0.08),
        textPrimary: Color(red: 0.98, green: 0.98, blue: 0.92),
        textSecondary: Color(red: 0.75, green: 0.75, blue: 0.58),
        accent: Color(red: 0.92, green: 0.90, blue: 0.65),
        highlightAccent: Color(red: 0.4, green: 0.5, blue: 1.0),  // Vivid periwinkle
        titleFont: .serif,
        bodyFont: .default
    )
    
    static let kings2 = BookTheme(
        background: Color(red: 0.05, green: 0.05, blue: 0.06),
        surface: Color(red: 0.10, green: 0.10, blue: 0.12),
        textPrimary: Color(red: 0.96, green: 0.96, blue: 0.98),
        textSecondary: Color(red: 0.68, green: 0.68, blue: 0.78),
        accent: Color(red: 0.82, green: 0.82, blue: 0.95),
        highlightAccent: Color(red: 1.0, green: 0.9, blue: 0.0),  // Vivid yellow
        titleFont: .serif,
        bodyFont: .default
    )
    
    static let chronicles1 = BookTheme(
        background: Color(red: 0.04, green: 0.06, blue: 0.06),
        surface: Color(red: 0.08, green: 0.12, blue: 0.12),
        textPrimary: Color(red: 0.94, green: 0.98, blue: 0.98),
        textSecondary: Color(red: 0.58, green: 0.75, blue: 0.75),
        accent: Color(red: 0.65, green: 0.90, blue: 0.88),
        highlightAccent: Color(red: 1.0, green: 0.4, blue: 0.5),  // Vivid coral
        titleFont: .default,
        bodyFont: .default
    )
    
    static let chronicles2 = BookTheme(
        background: Color(red: 0.05, green: 0.07, blue: 0.06),
        surface: Color(red: 0.10, green: 0.14, blue: 0.12),
        textPrimary: Color(red: 0.95, green: 0.98, blue: 0.97),
        textSecondary: Color(red: 0.62, green: 0.78, blue: 0.72),
        accent: Color(red: 0.70, green: 0.92, blue: 0.85),
        highlightAccent: Color(red: 1.0, green: 0.3, blue: 0.55),  // Vivid pink
        titleFont: .default,
        bodyFont: .default
    )
    
    static let ezra = BookTheme(
        background: Color(red: 0.06, green: 0.05, blue: 0.07),
        surface: Color(red: 0.12, green: 0.10, blue: 0.14),
        textPrimary: Color(red: 0.97, green: 0.95, blue: 0.98),
        textSecondary: Color(red: 0.72, green: 0.65, blue: 0.78),
        accent: Color(red: 0.85, green: 0.78, blue: 0.95),
        highlightAccent: Color(red: 0.7, green: 1.0, blue: 0.2),  // Vivid lime
        titleFont: .default,
        bodyFont: .serif
    )
    
    static let nehemiah = BookTheme(
        background: Color(red: 0.05, green: 0.05, blue: 0.07),
        surface: Color(red: 0.10, green: 0.10, blue: 0.14),
        textPrimary: Color(red: 0.95, green: 0.95, blue: 0.98),
        textSecondary: Color(red: 0.65, green: 0.65, blue: 0.78),
        accent: Color(red: 0.78, green: 0.78, blue: 0.95),
        highlightAccent: Color(red: 1.0, green: 0.85, blue: 0.0),  // Vivid gold
        titleFont: .default,
        bodyFont: .default
    )
    
    static let esther = BookTheme(
        background: Color(red: 0.09, green: 0.04, blue: 0.07),
        surface: Color(red: 0.18, green: 0.08, blue: 0.14),
        textPrimary: Color(red: 1.0, green: 0.94, blue: 0.97),
        textSecondary: Color(red: 0.88, green: 0.58, blue: 0.72),
        accent: Color(red: 1.0, green: 0.65, blue: 0.82),
        highlightAccent: Color(red: 0.0, green: 1.0, blue: 0.7),  // Vivid aqua
        titleFont: .serif,
        bodyFont: .serif
    )
    
    // MARK: - Poetry & Wisdom (Rich, contemplative)
    static let job = BookTheme(
        background: Color(red: 0.04, green: 0.04, blue: 0.06),
        surface: Color(red: 0.08, green: 0.08, blue: 0.12),
        textPrimary: Color(red: 0.94, green: 0.94, blue: 0.97),
        textSecondary: Color(red: 0.60, green: 0.60, blue: 0.72),
        accent: Color(red: 0.75, green: 0.75, blue: 0.92),
        highlightAccent: Color(red: 1.0, green: 0.85, blue: 0.0),  // Vivid gold
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let psalms = BookTheme(
        background: Color(red: 0.05, green: 0.03, blue: 0.10),
        surface: Color(red: 0.10, green: 0.06, blue: 0.20),
        textPrimary: Color(red: 0.96, green: 0.93, blue: 1.0),
        textSecondary: Color(red: 0.70, green: 0.58, blue: 0.88),
        accent: Color(red: 0.85, green: 0.70, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.95, blue: 0.0),  // Vivid bright yellow
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let proverbs = BookTheme(
        background: Color(red: 0.07, green: 0.06, blue: 0.02),
        surface: Color(red: 0.14, green: 0.12, blue: 0.04),
        textPrimary: Color(red: 1.0, green: 0.98, blue: 0.90),
        textSecondary: Color(red: 0.78, green: 0.72, blue: 0.48),
        accent: Color(red: 1.0, green: 0.90, blue: 0.55),
        highlightAccent: Color(red: 0.2, green: 0.6, blue: 1.0),  // Vivid sky blue
        titleFont: .rounded,
        bodyFont: .default
    )
    
    static let ecclesiastes = BookTheme(
        background: Color(red: 0.05, green: 0.05, blue: 0.05),
        surface: Color(red: 0.10, green: 0.10, blue: 0.10),
        textPrimary: Color(red: 0.95, green: 0.95, blue: 0.95),
        textSecondary: Color(red: 0.62, green: 0.62, blue: 0.62),
        accent: Color(red: 0.80, green: 0.80, blue: 0.80),
        highlightAccent: Color(red: 0.3, green: 0.9, blue: 1.0),  // Vivid cyan
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let songOfSolomon = BookTheme(
        background: Color(red: 0.10, green: 0.03, blue: 0.05),
        surface: Color(red: 0.20, green: 0.06, blue: 0.10),
        textPrimary: Color(red: 1.0, green: 0.93, blue: 0.95),
        textSecondary: Color(red: 0.92, green: 0.55, blue: 0.65),
        accent: Color(red: 1.0, green: 0.62, blue: 0.72),
        highlightAccent: Color(red: 0.0, green: 1.0, blue: 0.8),  // Vivid turquoise
        titleFont: .serif,
        bodyFont: .serif
    )
    
    // MARK: - Major Prophets (Bold, dramatic)
    static let isaiah = BookTheme(
        background: Color(red: 0.02, green: 0.05, blue: 0.10),
        surface: Color(red: 0.04, green: 0.10, blue: 0.20),
        textPrimary: Color(red: 0.92, green: 0.96, blue: 1.0),
        textSecondary: Color(red: 0.52, green: 0.68, blue: 0.90),
        accent: Color(red: 0.60, green: 0.80, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.7, blue: 0.0),  // Vivid amber
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let jeremiah = BookTheme(
        background: Color(red: 0.06, green: 0.04, blue: 0.08),
        surface: Color(red: 0.12, green: 0.08, blue: 0.16),
        textPrimary: Color(red: 0.97, green: 0.94, blue: 0.99),
        textSecondary: Color(red: 0.72, green: 0.62, blue: 0.82),
        accent: Color(red: 0.88, green: 0.75, blue: 1.0),
        highlightAccent: Color(red: 0.5, green: 1.0, blue: 0.2),  // Vivid lime
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let lamentations = BookTheme(
        background: Color(red: 0.04, green: 0.04, blue: 0.05),
        surface: Color(red: 0.08, green: 0.08, blue: 0.10),
        textPrimary: Color(red: 0.94, green: 0.94, blue: 0.96),
        textSecondary: Color(red: 0.58, green: 0.58, blue: 0.68),
        accent: Color(red: 0.72, green: 0.72, blue: 0.85),
        highlightAccent: Color(red: 1.0, green: 0.75, blue: 0.3),  // Vivid peach
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let ezekiel = BookTheme(
        background: Color(red: 0.03, green: 0.06, blue: 0.08),
        surface: Color(red: 0.06, green: 0.12, blue: 0.16),
        textPrimary: Color(red: 0.93, green: 0.97, blue: 0.99),
        textSecondary: Color(red: 0.55, green: 0.72, blue: 0.82),
        accent: Color(red: 0.62, green: 0.85, blue: 0.95),
        highlightAccent: Color(red: 1.0, green: 0.5, blue: 0.0),  // Vivid orange
        titleFont: .default,
        bodyFont: .default
    )
    
    static let daniel = BookTheme(
        background: Color(red: 0.04, green: 0.04, blue: 0.10),
        surface: Color(red: 0.08, green: 0.08, blue: 0.20),
        textPrimary: Color(red: 0.94, green: 0.94, blue: 1.0),
        textSecondary: Color(red: 0.60, green: 0.60, blue: 0.88),
        accent: Color(red: 0.72, green: 0.72, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.9, blue: 0.0),  // Vivid yellow
        titleFont: .default,
        bodyFont: .default
    )
    
    // MARK: - Minor Prophets (Varied, distinct voices)
    static let hosea = BookTheme(
        background: Color(red: 0.08, green: 0.04, blue: 0.06),
        surface: Color(red: 0.16, green: 0.08, blue: 0.12),
        textPrimary: Color(red: 1.0, green: 0.94, blue: 0.96),
        textSecondary: Color(red: 0.85, green: 0.60, blue: 0.70),
        accent: Color(red: 1.0, green: 0.70, blue: 0.80),
        highlightAccent: Color(red: 0.0, green: 1.0, blue: 0.75),  // Vivid seafoam
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let joel = BookTheme(
        background: Color(red: 0.04, green: 0.07, blue: 0.05),
        surface: Color(red: 0.08, green: 0.14, blue: 0.10),
        textPrimary: Color(red: 0.94, green: 0.98, blue: 0.95),
        textSecondary: Color(red: 0.58, green: 0.78, blue: 0.65),
        accent: Color(red: 0.68, green: 0.92, blue: 0.75),
        highlightAccent: Color(red: 1.0, green: 0.2, blue: 0.6),  // Vivid hot pink
        titleFont: .default,
        bodyFont: .default
    )
    
    static let amos = BookTheme(
        background: Color(red: 0.07, green: 0.05, blue: 0.03),
        surface: Color(red: 0.14, green: 0.10, blue: 0.06),
        textPrimary: Color(red: 0.98, green: 0.96, blue: 0.92),
        textSecondary: Color(red: 0.78, green: 0.68, blue: 0.52),
        accent: Color(red: 0.95, green: 0.82, blue: 0.58),
        highlightAccent: Color(red: 0.2, green: 0.65, blue: 1.0),  // Vivid cornflower
        titleFont: .default,
        bodyFont: .default
    )
    
    static let obadiah = BookTheme(
        background: Color(red: 0.06, green: 0.04, blue: 0.04),
        surface: Color(red: 0.12, green: 0.08, blue: 0.08),
        textPrimary: Color(red: 0.97, green: 0.94, blue: 0.94),
        textSecondary: Color(red: 0.75, green: 0.60, blue: 0.60),
        accent: Color(red: 0.92, green: 0.72, blue: 0.72),
        highlightAccent: Color(red: 0.0, green: 0.95, blue: 0.95),  // Vivid cyan
        titleFont: .default,
        bodyFont: .serif
    )
    
    static let jonah = BookTheme(
        background: Color(red: 0.03, green: 0.07, blue: 0.10),
        surface: Color(red: 0.06, green: 0.14, blue: 0.20),
        textPrimary: Color(red: 0.93, green: 0.98, blue: 1.0),
        textSecondary: Color(red: 0.55, green: 0.78, blue: 0.90),
        accent: Color(red: 0.62, green: 0.88, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.6, blue: 0.0),  // Vivid tangerine
        titleFont: .rounded,
        bodyFont: .default
    )
    
    static let micah = BookTheme(
        background: Color(red: 0.05, green: 0.05, blue: 0.07),
        surface: Color(red: 0.10, green: 0.10, blue: 0.14),
        textPrimary: Color(red: 0.95, green: 0.95, blue: 0.98),
        textSecondary: Color(red: 0.65, green: 0.65, blue: 0.78),
        accent: Color(red: 0.78, green: 0.78, blue: 0.95),
        highlightAccent: Color(red: 1.0, green: 0.85, blue: 0.0),  // Vivid gold
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let nahum = BookTheme(
        background: Color(red: 0.08, green: 0.04, blue: 0.02),
        surface: Color(red: 0.16, green: 0.08, blue: 0.04),
        textPrimary: Color(red: 1.0, green: 0.95, blue: 0.92),
        textSecondary: Color(red: 0.85, green: 0.62, blue: 0.50),
        accent: Color(red: 1.0, green: 0.75, blue: 0.58),
        highlightAccent: Color(red: 0.0, green: 0.85, blue: 1.0),  // Vivid azure
        titleFont: .default,
        bodyFont: .default
    )
    
    static let habakkuk = BookTheme(
        background: Color(red: 0.05, green: 0.06, blue: 0.08),
        surface: Color(red: 0.10, green: 0.12, blue: 0.16),
        textPrimary: Color(red: 0.95, green: 0.96, blue: 0.99),
        textSecondary: Color(red: 0.65, green: 0.70, blue: 0.85),
        accent: Color(red: 0.78, green: 0.82, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.75, blue: 0.0),  // Vivid honey
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let zephaniah = BookTheme(
        background: Color(red: 0.06, green: 0.05, blue: 0.08),
        surface: Color(red: 0.12, green: 0.10, blue: 0.16),
        textPrimary: Color(red: 0.97, green: 0.95, blue: 0.99),
        textSecondary: Color(red: 0.72, green: 0.65, blue: 0.82),
        accent: Color(red: 0.85, green: 0.78, blue: 0.98),
        highlightAccent: Color(red: 0.75, green: 1.0, blue: 0.0),  // Vivid chartreuse
        titleFont: .default,
        bodyFont: .serif
    )
    
    static let haggai = BookTheme(
        background: Color(red: 0.07, green: 0.06, blue: 0.04),
        surface: Color(red: 0.14, green: 0.12, blue: 0.08),
        textPrimary: Color(red: 0.98, green: 0.97, blue: 0.94),
        textSecondary: Color(red: 0.78, green: 0.72, blue: 0.58),
        accent: Color(red: 0.95, green: 0.88, blue: 0.68),
        highlightAccent: Color(red: 0.3, green: 0.6, blue: 1.0),  // Vivid periwinkle
        titleFont: .default,
        bodyFont: .default
    )
    
    static let zechariah = BookTheme(
        background: Color(red: 0.04, green: 0.05, blue: 0.08),
        surface: Color(red: 0.08, green: 0.10, blue: 0.16),
        textPrimary: Color(red: 0.94, green: 0.96, blue: 1.0),
        textSecondary: Color(red: 0.60, green: 0.68, blue: 0.88),
        accent: Color(red: 0.72, green: 0.80, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.8, blue: 0.0),  // Vivid gold
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let malachi = BookTheme(
        background: Color(red: 0.08, green: 0.05, blue: 0.03),
        surface: Color(red: 0.16, green: 0.10, blue: 0.06),
        textPrimary: Color(red: 1.0, green: 0.96, blue: 0.93),
        textSecondary: Color(red: 0.85, green: 0.68, blue: 0.55),
        accent: Color(red: 1.0, green: 0.80, blue: 0.62),
        highlightAccent: Color(red: 0.0, green: 0.8, blue: 1.0),  // Vivid sky blue
        titleFont: .serif,
        bodyFont: .serif
    )
    
    // MARK: - Gospels (Warm, inviting)
    static let matthew = BookTheme(
        background: Color(red: 0.02, green: 0.06, blue: 0.10),
        surface: Color(red: 0.04, green: 0.12, blue: 0.20),
        textPrimary: Color(red: 0.92, green: 0.97, blue: 1.0),
        textSecondary: Color(red: 0.52, green: 0.72, blue: 0.90),
        accent: Color(red: 0.58, green: 0.82, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.7, blue: 0.0),  // Vivid amber
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let mark = BookTheme(
        background: Color(red: 0.08, green: 0.05, blue: 0.02),
        surface: Color(red: 0.16, green: 0.10, blue: 0.04),
        textPrimary: Color(red: 1.0, green: 0.96, blue: 0.92),
        textSecondary: Color(red: 0.85, green: 0.70, blue: 0.52),
        accent: Color(red: 1.0, green: 0.82, blue: 0.58),
        highlightAccent: Color(red: 0.0, green: 0.85, blue: 1.0),  // Vivid azure
        titleFont: .default,
        bodyFont: .default
    )
    
    static let luke = BookTheme(
        background: Color(red: 0.03, green: 0.07, blue: 0.06),
        surface: Color(red: 0.06, green: 0.14, blue: 0.12),
        textPrimary: Color(red: 0.93, green: 0.98, blue: 0.97),
        textSecondary: Color(red: 0.55, green: 0.78, blue: 0.72),
        accent: Color(red: 0.62, green: 0.92, blue: 0.85),
        highlightAccent: Color(red: 1.0, green: 0.35, blue: 0.5),  // Vivid coral
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let john = BookTheme(
        background: Color(red: 0.04, green: 0.03, blue: 0.10),
        surface: Color(red: 0.08, green: 0.06, blue: 0.20),
        textPrimary: Color(red: 0.95, green: 0.93, blue: 1.0),
        textSecondary: Color(red: 0.68, green: 0.58, blue: 0.90),
        accent: Color(red: 0.80, green: 0.70, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.95, blue: 0.0),  // Vivid bright yellow
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let acts = BookTheme(
        background: Color(red: 0.07, green: 0.04, blue: 0.02),
        surface: Color(red: 0.14, green: 0.08, blue: 0.04),
        textPrimary: Color(red: 1.0, green: 0.95, blue: 0.92),
        textSecondary: Color(red: 0.82, green: 0.62, blue: 0.50),
        accent: Color(red: 1.0, green: 0.75, blue: 0.55),
        highlightAccent: Color(red: 0.0, green: 0.9, blue: 1.0),  // Vivid cyan
        titleFont: .default,
        bodyFont: .default
    )
    
    // MARK: - Pauline Epistles (Vibrant, varied)
    static let romans = BookTheme(
        background: Color(red: 0.08, green: 0.02, blue: 0.05),
        surface: Color(red: 0.16, green: 0.04, blue: 0.10),
        textPrimary: Color(red: 1.0, green: 0.92, blue: 0.95),
        textSecondary: Color(red: 0.88, green: 0.52, blue: 0.65),
        accent: Color(red: 1.0, green: 0.58, blue: 0.72),
        highlightAccent: Color(red: 0.0, green: 1.0, blue: 0.75),  // Vivid aqua
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let corinthians1 = BookTheme(
        background: Color(red: 0.06, green: 0.04, blue: 0.10),
        surface: Color(red: 0.12, green: 0.08, blue: 0.20),
        textPrimary: Color(red: 0.97, green: 0.95, blue: 1.0),
        textSecondary: Color(red: 0.72, green: 0.62, blue: 0.90),
        accent: Color(red: 0.85, green: 0.75, blue: 1.0),
        highlightAccent: Color(red: 0.75, green: 1.0, blue: 0.0),  // Vivid lime
        titleFont: .default,
        bodyFont: .default
    )
    
    static let corinthians2 = BookTheme(
        background: Color(red: 0.05, green: 0.05, blue: 0.10),
        surface: Color(red: 0.10, green: 0.10, blue: 0.20),
        textPrimary: Color(red: 0.96, green: 0.96, blue: 1.0),
        textSecondary: Color(red: 0.68, green: 0.68, blue: 0.90),
        accent: Color(red: 0.80, green: 0.80, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.95, blue: 0.0),  // Vivid yellow
        titleFont: .default,
        bodyFont: .default
    )
    
    static let galatians = BookTheme(
        background: Color(red: 0.05, green: 0.07, blue: 0.04),
        surface: Color(red: 0.10, green: 0.14, blue: 0.08),
        textPrimary: Color(red: 0.96, green: 0.98, blue: 0.94),
        textSecondary: Color(red: 0.68, green: 0.78, blue: 0.58),
        accent: Color(red: 0.80, green: 0.92, blue: 0.68),
        highlightAccent: Color(red: 1.0, green: 0.3, blue: 0.7),  // Vivid orchid
        titleFont: .default,
        bodyFont: .serif
    )
    
    static let ephesians = BookTheme(
        background: Color(red: 0.03, green: 0.05, blue: 0.10),
        surface: Color(red: 0.06, green: 0.10, blue: 0.20),
        textPrimary: Color(red: 0.93, green: 0.96, blue: 1.0),
        textSecondary: Color(red: 0.55, green: 0.68, blue: 0.92),
        accent: Color(red: 0.62, green: 0.78, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.7, blue: 0.0),  // Vivid amber
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let philippians = BookTheme(
        background: Color(red: 0.06, green: 0.08, blue: 0.04),
        surface: Color(red: 0.12, green: 0.16, blue: 0.08),
        textPrimary: Color(red: 0.97, green: 0.99, blue: 0.95),
        textSecondary: Color(red: 0.72, green: 0.82, blue: 0.62),
        accent: Color(red: 0.85, green: 0.95, blue: 0.72),
        highlightAccent: Color(red: 1.0, green: 0.2, blue: 0.6),  // Vivid hot pink
        titleFont: .rounded,
        bodyFont: .default
    )
    
    static let colossians = BookTheme(
        background: Color(red: 0.04, green: 0.06, blue: 0.08),
        surface: Color(red: 0.08, green: 0.12, blue: 0.16),
        textPrimary: Color(red: 0.94, green: 0.97, blue: 0.99),
        textSecondary: Color(red: 0.60, green: 0.72, blue: 0.82),
        accent: Color(red: 0.70, green: 0.85, blue: 0.95),
        highlightAccent: Color(red: 1.0, green: 0.6, blue: 0.0),  // Vivid peach/orange
        titleFont: .default,
        bodyFont: .serif
    )
    
    static let thessalonians1 = BookTheme(
        background: Color(red: 0.06, green: 0.05, blue: 0.08),
        surface: Color(red: 0.12, green: 0.10, blue: 0.16),
        textPrimary: Color(red: 0.97, green: 0.96, blue: 0.99),
        textSecondary: Color(red: 0.72, green: 0.68, blue: 0.82),
        accent: Color(red: 0.85, green: 0.80, blue: 0.98),
        highlightAccent: Color(red: 0.8, green: 1.0, blue: 0.0),  // Vivid chartreuse
        titleFont: .default,
        bodyFont: .default
    )
    
    static let thessalonians2 = BookTheme(
        background: Color(red: 0.05, green: 0.06, blue: 0.08),
        surface: Color(red: 0.10, green: 0.12, blue: 0.16),
        textPrimary: Color(red: 0.96, green: 0.97, blue: 0.99),
        textSecondary: Color(red: 0.68, green: 0.72, blue: 0.82),
        accent: Color(red: 0.80, green: 0.85, blue: 0.98),
        highlightAccent: Color(red: 1.0, green: 0.85, blue: 0.0),  // Vivid gold
        titleFont: .default,
        bodyFont: .default
    )
    
    static let timothy1 = BookTheme(
        background: Color(red: 0.07, green: 0.06, blue: 0.04),
        surface: Color(red: 0.14, green: 0.12, blue: 0.08),
        textPrimary: Color(red: 0.98, green: 0.97, blue: 0.94),
        textSecondary: Color(red: 0.78, green: 0.72, blue: 0.60),
        accent: Color(red: 0.95, green: 0.88, blue: 0.70),
        highlightAccent: Color(red: 0.2, green: 0.75, blue: 1.0),  // Vivid sky blue
        titleFont: .default,
        bodyFont: .default
    )
    
    static let timothy2 = BookTheme(
        background: Color(red: 0.06, green: 0.06, blue: 0.05),
        surface: Color(red: 0.12, green: 0.12, blue: 0.10),
        textPrimary: Color(red: 0.97, green: 0.97, blue: 0.96),
        textSecondary: Color(red: 0.72, green: 0.72, blue: 0.68),
        accent: Color(red: 0.88, green: 0.88, blue: 0.82),
        highlightAccent: Color(red: 0.3, green: 0.8, blue: 1.0),  // Vivid light blue
        titleFont: .default,
        bodyFont: .default
    )
    
    static let titus = BookTheme(
        background: Color(red: 0.04, green: 0.07, blue: 0.07),
        surface: Color(red: 0.08, green: 0.14, blue: 0.14),
        textPrimary: Color(red: 0.94, green: 0.98, blue: 0.98),
        textSecondary: Color(red: 0.60, green: 0.78, blue: 0.78),
        accent: Color(red: 0.70, green: 0.92, blue: 0.92),
        highlightAccent: Color(red: 1.0, green: 0.35, blue: 0.45),  // Vivid salmon
        titleFont: .default,
        bodyFont: .default
    )
    
    static let philemon = BookTheme(
        background: Color(red: 0.08, green: 0.06, blue: 0.04),
        surface: Color(red: 0.16, green: 0.12, blue: 0.08),
        textPrimary: Color(red: 1.0, green: 0.97, blue: 0.94),
        textSecondary: Color(red: 0.82, green: 0.72, blue: 0.60),
        accent: Color(red: 0.98, green: 0.85, blue: 0.70),
        highlightAccent: Color(red: 0.15, green: 0.75, blue: 1.0),  // Vivid azure
        titleFont: .serif,
        bodyFont: .serif
    )
    
    // MARK: - General Epistles
    static let hebrews = BookTheme(
        background: Color(red: 0.06, green: 0.04, blue: 0.08),
        surface: Color(red: 0.12, green: 0.08, blue: 0.16),
        textPrimary: Color(red: 0.97, green: 0.94, blue: 0.99),
        textSecondary: Color(red: 0.72, green: 0.62, blue: 0.82),
        accent: Color(red: 0.88, green: 0.75, blue: 0.98),
        highlightAccent: Color(red: 0.6, green: 1.0, blue: 0.2),  // Vivid lime
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let james = BookTheme(
        background: Color(red: 0.05, green: 0.06, blue: 0.04),
        surface: Color(red: 0.10, green: 0.12, blue: 0.08),
        textPrimary: Color(red: 0.96, green: 0.97, blue: 0.94),
        textSecondary: Color(red: 0.68, green: 0.72, blue: 0.60),
        accent: Color(red: 0.82, green: 0.88, blue: 0.72),
        highlightAccent: Color(red: 1.0, green: 0.3, blue: 0.7),  // Vivid magenta
        titleFont: .default,
        bodyFont: .default
    )
    
    static let peter1 = BookTheme(
        background: Color(red: 0.04, green: 0.05, blue: 0.08),
        surface: Color(red: 0.08, green: 0.10, blue: 0.16),
        textPrimary: Color(red: 0.94, green: 0.96, blue: 1.0),
        textSecondary: Color(red: 0.60, green: 0.68, blue: 0.88),
        accent: Color(red: 0.72, green: 0.80, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.8, blue: 0.0),  // Vivid gold
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let peter2 = BookTheme(
        background: Color(red: 0.05, green: 0.05, blue: 0.08),
        surface: Color(red: 0.10, green: 0.10, blue: 0.16),
        textPrimary: Color(red: 0.96, green: 0.96, blue: 1.0),
        textSecondary: Color(red: 0.68, green: 0.68, blue: 0.88),
        accent: Color(red: 0.80, green: 0.80, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.85, blue: 0.0),  // Vivid yellow
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let john1 = BookTheme(
        background: Color(red: 0.04, green: 0.04, blue: 0.10),
        surface: Color(red: 0.08, green: 0.08, blue: 0.20),
        textPrimary: Color(red: 0.95, green: 0.95, blue: 1.0),
        textSecondary: Color(red: 0.65, green: 0.65, blue: 0.92),
        accent: Color(red: 0.78, green: 0.78, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.95, blue: 0.0),  // Vivid bright yellow
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let john2 = BookTheme(
        background: Color(red: 0.05, green: 0.04, blue: 0.10),
        surface: Color(red: 0.10, green: 0.08, blue: 0.20),
        textPrimary: Color(red: 0.96, green: 0.95, blue: 1.0),
        textSecondary: Color(red: 0.70, green: 0.65, blue: 0.92),
        accent: Color(red: 0.82, green: 0.78, blue: 1.0),
        highlightAccent: Color(red: 0.85, green: 1.0, blue: 0.0),  // Vivid chartreuse
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let john3 = BookTheme(
        background: Color(red: 0.05, green: 0.05, blue: 0.10),
        surface: Color(red: 0.10, green: 0.10, blue: 0.20),
        textPrimary: Color(red: 0.96, green: 0.96, blue: 1.0),
        textSecondary: Color(red: 0.70, green: 0.70, blue: 0.92),
        accent: Color(red: 0.82, green: 0.82, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.9, blue: 0.0),  // Vivid gold
        titleFont: .serif,
        bodyFont: .serif
    )
    
    static let jude = BookTheme(
        background: Color(red: 0.07, green: 0.04, blue: 0.06),
        surface: Color(red: 0.14, green: 0.08, blue: 0.12),
        textPrimary: Color(red: 0.98, green: 0.94, blue: 0.97),
        textSecondary: Color(red: 0.80, green: 0.62, blue: 0.72),
        accent: Color(red: 0.95, green: 0.75, blue: 0.85),
        highlightAccent: Color(red: 0.0, green: 1.0, blue: 0.7),  // Vivid seafoam
        titleFont: .default,
        bodyFont: .serif
    )
    
    // MARK: - Revelation (Cosmic, otherworldly)
    static let revelation = BookTheme(
        background: Color(red: 0.02, green: 0.02, blue: 0.08),
        surface: Color(red: 0.04, green: 0.04, blue: 0.16),
        textPrimary: Color(red: 0.92, green: 0.92, blue: 1.0),
        textSecondary: Color(red: 0.55, green: 0.55, blue: 0.90),
        accent: Color(red: 0.68, green: 0.68, blue: 1.0),
        highlightAccent: Color(red: 1.0, green: 0.8, blue: 0.0),  // Vivid gold
        titleFont: .serif,
        bodyFont: .serif
    )
    
    // MARK: - Theme Lookup
    static func theme(for bookId: String) -> BookTheme {
        switch bookId {
        case "genesis": return genesis
        case "exodus": return exodus
        case "leviticus": return leviticus
        case "numbers": return numbers
        case "deuteronomy": return deuteronomy
        case "joshua": return joshua
        case "judges": return judges
        case "ruth": return ruth
        case "1samuel": return samuel1
        case "2samuel": return samuel2
        case "1kings": return kings1
        case "2kings": return kings2
        case "1chronicles": return chronicles1
        case "2chronicles": return chronicles2
        case "ezra": return ezra
        case "nehemiah": return nehemiah
        case "esther": return esther
        case "job": return job
        case "psalms": return psalms
        case "proverbs": return proverbs
        case "ecclesiastes": return ecclesiastes
        case "songofsolomon": return songOfSolomon
        case "isaiah": return isaiah
        case "jeremiah": return jeremiah
        case "lamentations": return lamentations
        case "ezekiel": return ezekiel
        case "daniel": return daniel
        case "hosea": return hosea
        case "joel": return joel
        case "amos": return amos
        case "obadiah": return obadiah
        case "jonah": return jonah
        case "micah": return micah
        case "nahum": return nahum
        case "habakkuk": return habakkuk
        case "zephaniah": return zephaniah
        case "haggai": return haggai
        case "zechariah": return zechariah
        case "malachi": return malachi
        case "matthew": return matthew
        case "mark": return mark
        case "luke": return luke
        case "john": return john
        case "acts": return acts
        case "romans": return romans
        case "1corinthians": return corinthians1
        case "2corinthians": return corinthians2
        case "galatians": return galatians
        case "ephesians": return ephesians
        case "philippians": return philippians
        case "colossians": return colossians
        case "1thessalonians": return thessalonians1
        case "2thessalonians": return thessalonians2
        case "1timothy": return timothy1
        case "2timothy": return timothy2
        case "titus": return titus
        case "philemon": return philemon
        case "hebrews": return hebrews
        case "james": return james
        case "1peter": return peter1
        case "2peter": return peter2
        case "1john": return john1
        case "2john": return john2
        case "3john": return john3
        case "jude": return jude
        case "revelation": return revelation
        default: return john
        }
    }
}

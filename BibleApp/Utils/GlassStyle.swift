import SwiftUI

// MARK: - Glass Style System
/// Unified liquid glass styling for all controls in the app

enum GlassStyle {
    
    // MARK: - Glass Background Modifier
    /// Creates the liquid glass background effect
    struct Background: ViewModifier {
        var shape: GlassShape = .capsule
        var intensity: GlassIntensity = .regular
        var isPressed: Bool = false
        
        func body(content: Content) -> some View {
            content
                .background(backgroundShape)
                .overlay(borderOverlay)
                .shadow(
                    color: .black.opacity(intensity.shadowOpacity),
                    radius: intensity.shadowRadius,
                    y: intensity.shadowY
                )
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .opacity(isPressed ? 0.9 : 1.0)
        }
        
        @ViewBuilder
        private var backgroundShape: some View {
            if intensity.hasMaterial {
                switch shape {
                case .capsule:
                    Capsule(style: .continuous)
                        .fill(materialForIntensity)
                        .environment(\.colorScheme, .dark)
                case .circle:
                    Circle()
                        .fill(materialForIntensity)
                        .environment(\.colorScheme, .dark)
                case .roundedRect(let radius):
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(materialForIntensity)
                        .environment(\.colorScheme, .dark)
                }
            } else {
                // Clear style - no blur, just subtle fill
                switch shape {
                case .capsule:
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(intensity.clearFillOpacity))
                case .circle:
                    Circle()
                        .fill(Color.white.opacity(intensity.clearFillOpacity))
                case .roundedRect(let radius):
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(Color.white.opacity(intensity.clearFillOpacity))
                }
            }
        }
        
        private var materialForIntensity: Material {
            switch intensity {
            case .ultraThin: return .ultraThinMaterial
            case .regular: return .regularMaterial
            case .thick: return .thickMaterial
            case .clear: return .ultraThinMaterial // fallback, won't be used
            }
        }
        
        @ViewBuilder
        private var borderOverlay: some View {
            switch shape {
            case .capsule:
                Capsule(style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(intensity.borderTopOpacity),
                                Color.white.opacity(intensity.borderBottomOpacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            case .circle:
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(intensity.borderTopOpacity),
                                Color.white.opacity(intensity.borderBottomOpacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            case .roundedRect(let radius):
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(intensity.borderTopOpacity),
                                Color.white.opacity(intensity.borderBottomOpacity)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
    }
    
    // MARK: - Glass Button Style
    struct ButtonStyle: SwiftUI.ButtonStyle {
        var shape: GlassShape = .capsule
        var intensity: GlassIntensity = .regular
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .modifier(Background(
                    shape: shape,
                    intensity: intensity,
                    isPressed: configuration.isPressed
                ))
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
    
    // MARK: - Shape Options
    enum GlassShape {
        case capsule
        case circle
        case roundedRect(radius: CGFloat)
    }
    
    // MARK: - Intensity Options
    enum GlassIntensity {
        case clear       // No blur, just border + shadow (transparent)
        case ultraThin   // More transparent, subtle blur
        case regular     // Standard glass look
        case thick       // More opaque, prominent
        
        var hasMaterial: Bool {
            self != .clear
        }
        
        var clearFillOpacity: Double {
            0.08 // Subtle tint for clear style
        }
        
        var borderTopOpacity: Double {
            switch self {
            case .clear: return 0.25
            case .ultraThin: return 0.20
            case .regular: return 0.18
            case .thick: return 0.15
            }
        }
        
        var borderBottomOpacity: Double {
            switch self {
            case .clear: return 0.08
            case .ultraThin: return 0.06
            case .regular: return 0.05
            case .thick: return 0.04
            }
        }
        
        var shadowOpacity: Double {
            switch self {
            case .clear: return 0.12
            case .ultraThin: return 0.15
            case .regular: return 0.20
            case .thick: return 0.25
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .clear: return 4
            case .ultraThin: return 6
            case .regular: return 10
            case .thick: return 14
            }
        }
        
        var shadowY: CGFloat {
            switch self {
            case .clear: return 2
            case .ultraThin: return 3
            case .regular: return 4
            case .thick: return 6
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply liquid glass background effect
    func glassBackground(
        _ shape: GlassStyle.GlassShape = .capsule,
        intensity: GlassStyle.GlassIntensity = .regular
    ) -> some View {
        self.modifier(GlassStyle.Background(shape: shape, intensity: intensity))
    }
    
    /// Apply glass button styling (for use with plain button style)
    func glassButton(
        _ shape: GlassStyle.GlassShape = .capsule,
        intensity: GlassStyle.GlassIntensity = .regular
    ) -> some View {
        self.modifier(GlassStyle.Background(shape: shape, intensity: intensity))
    }
}

// MARK: - Convenience Button Styles

extension ButtonStyle where Self == GlassStyle.ButtonStyle {
    /// Glass capsule button (pill shape) - regular blur
    static var glass: GlassStyle.ButtonStyle {
        GlassStyle.ButtonStyle(shape: .capsule, intensity: .regular)
    }
    
    /// Glass circle button - regular blur
    static var glassCircle: GlassStyle.ButtonStyle {
        GlassStyle.ButtonStyle(shape: .circle, intensity: .regular)
    }
    
    /// Glass rounded rectangle button
    static func glassRounded(_ radius: CGFloat = 12) -> GlassStyle.ButtonStyle {
        GlassStyle.ButtonStyle(shape: .roundedRect(radius: radius), intensity: .regular)
    }
    
    /// Ultra thin glass capsule (subtle blur)
    static var glassUltraThin: GlassStyle.ButtonStyle {
        GlassStyle.ButtonStyle(shape: .capsule, intensity: .ultraThin)
    }
    
    /// Ultra thin glass circle
    static var glassCircleUltraThin: GlassStyle.ButtonStyle {
        GlassStyle.ButtonStyle(shape: .circle, intensity: .ultraThin)
    }
    
    /// Clear glass capsule (no blur, just border + shadow)
    static var glassClear: GlassStyle.ButtonStyle {
        GlassStyle.ButtonStyle(shape: .capsule, intensity: .clear)
    }
    
    /// Clear glass circle (no blur)
    static var glassCircleClear: GlassStyle.ButtonStyle {
        GlassStyle.ButtonStyle(shape: .circle, intensity: .clear)
    }
    
    /// Thick glass capsule (more opaque blur)
    static var glassThick: GlassStyle.ButtonStyle {
        GlassStyle.ButtonStyle(shape: .capsule, intensity: .thick)
    }
    
    /// Thick glass circle
    static var glassCircleThick: GlassStyle.ButtonStyle {
        GlassStyle.ButtonStyle(shape: .circle, intensity: .thick)
    }
}

// MARK: - Preview

#Preview("Glass Buttons") {
    ZStack {
        LinearGradient(
            colors: [Color(red: 0.06, green: 0.04, blue: 0.12), Color(red: 0.04, green: 0.03, blue: 0.10)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 20) {
                // Section: Intensities
                Text("INTENSITIES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                
                // Clear (no blur)
                Button { } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "drop")
                        Text("Clear")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glassClear)
                
                // Ultra Thin
                Button { } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.halffull")
                        Text("Ultra Thin")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glassUltraThin)
                
                // Regular
                Button { } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                        Text("Regular")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glass)
                
                // Thick
                Button { } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.degreesign.fill")
                        Text("Thick")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.glassThick)
                
                // Section: Shapes
                Text("SHAPES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 40)
                    .padding(.top, 16)
                
                HStack(spacing: 16) {
                    // Circle
                    Button { } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                    }
                    .buttonStyle(.glassCircle)
                    
                    // Capsule
                    Button { } label: {
                        Text("Capsule")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.glass)
                }
                
                // Rounded rectangle
                Button { } label: {
                    Text("Rounded Rectangle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glassRounded(16))
                .padding(.horizontal, 40)
                
                Spacer(minLength: 40)
            }
        }
    }
}

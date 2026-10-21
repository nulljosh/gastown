import SwiftUI
import SpriteKit
import CoreText
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Theme resolution: an explicit player choice wins, otherwise follow the system.
/// Mirrors `web/js/theme.js` so both clients behave the same way.
enum ThemeChoice: String, CaseIterable, Sendable {
    case system, light, dark

    var label: String {
        switch self {
        case .system: "AUTO"
        case .light: "LIGHT"
        case .dark: "DARK"
        }
    }

    /// What `.preferredColorScheme` should be handed. `nil` means "follow the system".
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

extension Notification.Name {
    static let themeDidChange = Notification.Name("themeDidChange")
}

enum Theme {
    private static let choiceKey = "nyc-theme"

    static var choice: ThemeChoice {
        get {
            ThemeChoice(rawValue: UserDefaults.standard.string(forKey: choiceKey) ?? "") ?? .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: choiceKey)
            NotificationCenter.default.post(name: .themeDidChange, object: nil)
        }
    }

    /// SpriteKit resolves colors at assign time and does not re-resolve on a trait
    /// change, so scenes read this flag and repaint on `.themeDidChange` instead of
    /// holding dynamic colors.
    static var isDark: Bool {
        switch choice {
        case .light: false
        case .dark: true
        case .system: systemIsDark
        }
    }

    private static var systemIsDark: Bool {
        #if canImport(UIKit)
        UITraitCollection.current.userInterfaceStyle == .dark
        #elseif canImport(AppKit)
        NSApp?.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        #else
        true
        #endif
    }

    /// A colour that resolves per appearance, so SwiftUI repaints it on a theme flip.
    static func adaptive(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
        #elseif canImport(AppKit)
        return Color(NSColor(name: nil) {
            $0.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
        })
        #else
        return dark
        #endif
    }

    // Accents. Vivid hues stay put; the ones used as *text* get a darker light-mode
    // variant, because #ffd60a on white is unreadable.
    static let accent   = Color(red: 0.000, green: 0.443, blue: 0.890) // #0071e3
    static let green    = adaptive(light: Color(red: 0.10, green: 0.60, blue: 0.24),
                                   dark:  Color(red: 0.188, green: 0.820, blue: 0.345))
    static let yellow   = adaptive(light: Color(red: 0.60, green: 0.44, blue: 0.00),
                                   dark:  Color(red: 1.000, green: 0.839, blue: 0.039))
    static let orange   = adaptive(light: Color(red: 0.72, green: 0.40, blue: 0.00),
                                   dark:  Color(red: 1.000, green: 0.624, blue: 0.039))
    static let red      = adaptive(light: Color(red: 0.80, green: 0.13, blue: 0.10),
                                   dark:  Color(red: 1.000, green: 0.271, blue: 0.227))
    static let pink     = adaptive(light: Color(red: 0.82, green: 0.06, blue: 0.24),
                                   dark:  Color(red: 1.000, green: 0.216, blue: 0.373))
    static let cyan     = adaptive(light: Color(red: 0.00, green: 0.42, blue: 0.60),
                                   dark:  Color(red: 0.392, green: 0.820, blue: 1.000))

    // Structure.
    static let bg       = adaptive(light: Color(red: 0.949, green: 0.949, blue: 0.961),
                                   dark:  Color(red: 0.039, green: 0.039, blue: 0.047))
    static let text1    = adaptive(light: .black.opacity(0.90), dark: .white.opacity(0.92))
    static let text2    = adaptive(light: .black.opacity(0.58), dark: .white.opacity(0.55))
    static let text3    = adaptive(light: .black.opacity(0.38), dark: .white.opacity(0.35))
    static let glass    = adaptive(light: .black.opacity(0.05), dark: .white.opacity(0.08))
    static let border   = adaptive(light: .black.opacity(0.14), dark: .white.opacity(0.18))
    /// Scrim behind modal panels — black in dark, softer in light so it does not read as a hole.
    static let scrim    = adaptive(light: .black.opacity(0.18), dark: .black.opacity(0.35))

    static let radius: CGFloat = 8
    static let radiusLg: CGFloat = 12
    static let radiusPill: CGFloat = 100

    static func vitalColor(_ value: Double) -> Color {
        value > 60 ? green : value > 30 ? yellow : red
    }
}

/// The SpriteKit half of the palette. Scenes read these at paint time and repaint on
/// `.themeDidChange`; the tile artwork itself is night-styled in both themes.
enum ScenePalette {
    static var background: SKColor {
        Theme.isDark
            ? SKColor(red: 0.04, green: 0.04, blue: 0.05, alpha: 1)
            : SKColor(red: 0.90, green: 0.91, blue: 0.93, alpha: 1)
    }

    static var title: SKColor {
        Theme.isDark
            ? SKColor(red: 0.39, green: 0.82, blue: 1.00, alpha: 1)
            : SKColor(red: 0.00, green: 0.42, blue: 0.60, alpha: 1)
    }

    static var accentWarm: SKColor {
        Theme.isDark
            ? SKColor(red: 1.00, green: 0.84, blue: 0.04, alpha: 1)
            : SKColor(red: 0.60, green: 0.44, blue: 0.00, alpha: 1)
    }

    static var accentHot: SKColor {
        Theme.isDark
            ? SKColor(red: 1.00, green: 0.22, blue: 0.37, alpha: 1)
            : SKColor(red: 0.82, green: 0.06, blue: 0.24, alpha: 1)
    }

    static var muted: SKColor {
        Theme.isDark
            ? SKColor(red: 0.60, green: 0.60, blue: 0.65, alpha: 1)
            : SKColor(red: 0.36, green: 0.36, blue: 0.40, alpha: 1)
    }

    static var disabled: SKColor {
        Theme.isDark
            ? SKColor(red: 0.40, green: 0.40, blue: 0.45, alpha: 1)
            : SKColor(red: 0.58, green: 0.58, blue: 0.62, alpha: 1)
    }

    static var panelFill: SKColor {
        Theme.isDark
            ? SKColor(red: 0.10, green: 0.15, blue: 0.20, alpha: 0.90)
            : SKColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.92)
    }

    static var overlayScrim: SKColor {
        Theme.isDark
            ? SKColor(white: 0.0, alpha: 0.70)
            : SKColor(white: 0.0, alpha: 0.45)
    }
}

struct ResourceMeta {
    let icon: String
    let label: String
    let color: Color
}

let resourceMeta: [ResourceType: ResourceMeta] = [
    .food:      ResourceMeta(icon: "hexagon",    label: "FOOD", color: Theme.green),
    .power:     ResourceMeta(icon: "diamond",    label: "PWR",  color: Theme.yellow),
    .materials: ResourceMeta(icon: "square.fill",label: "MAT",  color: Theme.orange),
    .oxygen:    ResourceMeta(icon: "circle",     label: "O2",   color: Theme.cyan),
    .cash:      ResourceMeta(icon: "dollarsign", label: "CASH", color: Theme.pink),
]

struct GlassPanel<Content: View>: View {
    var cornerRadius: CGFloat = Theme.radius
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Theme.border, lineWidth: 1)
                    )
            )
    }
}

struct GlassButton: View {
    let label: String
    var isActive: Bool = false
    var isDestructive: Bool = false
    var isPrimary: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.nyc(size: 11, weight: .bold))
                .foregroundStyle(foreColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(minHeight: 36)
                .background(
                    Capsule()
                        .fill(bgColor)
                        .overlay(Capsule().stroke(strokeColor, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }

    private var foreColor: Color {
        if isPrimary { return .white }
        if isDestructive { return Theme.red }
        if isActive { return .white }
        return Theme.text2
    }

    private var bgColor: Color {
        if isPrimary { return Theme.accent }
        if isActive { return Theme.accent.opacity(0.35) }
        return Theme.glass
    }

    private var strokeColor: Color {
        if isPrimary { return .clear }
        if isDestructive { return Theme.red.opacity(0.3) }
        if isActive { return Theme.accent }
        return Theme.border
    }
}

/// NYC Sans (scripts/gen_font.py): Inter renamed, proportional figures. Bundled in Resources/Fonts and
/// registered for this process on first use, so there is no Info.plist font list to keep in step.
enum NYCFont {
    static let registered: Void = {
        let urls = (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
            + (Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? [])
        for url in urls where url.lastPathComponent.hasPrefix("NYCSans-") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    /// PostScript name for a weight; anything lighter than medium is Regular.
    static func name(_ weight: Font.Weight) -> String {
        _ = registered
        switch weight {
        case .bold, .heavy, .black: return "NYCSans-Bold"
        case .semibold: return "NYCSans-Semibold"
        case .medium: return "NYCSans-Medium"
        default: return "NYCSans-Regular"
        }
    }
}

extension Font {
    /// The game's face at a fixed size, the drop-in for SwiftUI's `.system(size:weight:)`.
    static func nyc(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(NYCFont.name(weight), fixedSize: size)
    }
}

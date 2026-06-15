import SwiftUI
import UIKit
import CoreText

/// Central design tokens. Colors live in the asset catalog so each
/// white-label target can override them without touching code.
enum Theme {
    static let primary = Color("BrandPrimary")
    static let secondary = Color("BrandSecondary")
    static let muted = Color("BrandMuted")
    static let background = Color("BrandBackground")

    // MARK: Typography (brand font with system fallback)

    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if brandFontAvailable {
            return Font.custom(BrandConfiguration.current.fontFamily, size: size).weight(weight)
        }
        return .system(size: size, weight: weight)
    }

    static var brandFontAvailable: Bool {
        UIFont(name: BrandConfiguration.current.fontFamily, size: 12) != nil
    }

    /// Registers every font bundled under Resources/Fonts at launch,
    /// so brands can ship fonts without Info.plist entries.
    static func registerBundledFonts() {
        let extensions = ["ttf", "otf"]
        for ext in extensions {
            for url in Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? [] {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}

// MARK: - Reusable styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(16, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Theme.primary.opacity(configuration.isPressed ? 0.85 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Theme.primary.opacity(0.06), radius: 8, y: 3)
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

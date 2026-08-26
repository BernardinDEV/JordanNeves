import SwiftUI
import UIKit
import CoreText

/// Central design tokens.
///
/// Brand colours live in the asset catalog so each white-label target overrides
/// them without touching code. Semantic colours (on track / attention / critical)
/// stay here on purpose: green means "nothing pending" for every firm, and
/// letting a brand repaint it would break the meaning the whole app depends on.
enum Theme {

    // MARK: Brand (overridable per target)

    static let primary = Color("BrandPrimary")
    static let secondary = Color("BrandSecondary")
    static let muted = Color("BrandMuted")
    static let background = Color("BrandBackground")
    static let body = Color("BrandBody")
    static let line = Color("BrandLine")
    static let fill = Color("BrandFill")
    /// Rare accent — priority marks and section labels only.
    static let brass = Color("BrandBrass")

    /// Superfície de cartão. Era `.white` cravado em catorze lugares — o que
    /// impedia uma marca de fundo creme ou off-white e travaria o tema escuro
    /// no dia em que ele for desenhado.
    static let card = Color("BrandCard")

    /// Tinta sobre superfície da marca (`primary` ou `brass`). Não é branco
    /// fixo de propósito: marca de cor clara precisa de tinta escura aqui, e
    /// contraste é acessibilidade, não gosto.
    static let onBrand = Color("BrandOnBrand")

    // MARK: Semantic (fixed)

    static let onTrack = Color(red: 30 / 255, green: 122 / 255, blue: 92 / 255)
    static let attention = Color(red: 181 / 255, green: 114 / 255, blue: 26 / 255)
    static let critical = Color(red: 180 / 255, green: 52 / 255, blue: 46 / 255)

    static func color(for urgency: Urgency) -> Color {
        switch urgency {
        case .critical: critical
        case .warning: attention
        case .normal: onTrack
        }
    }

    static func color(for state: CaseState) -> Color {
        switch state {
        case .requiresYou: critical
        case .deadlineNear: attention
        case .withCourt: muted
        case .onTrack: onTrack
        }
    }

    // MARK: Layout

    /// Base grid. Spacings are multiples of 4; screens use a 20pt side margin.
    enum Space {
        static let side: CGFloat = 20
        static let card: CGFloat = 16
        static let tight: CGFloat = 8
        static let row: CGFloat = 12
    }

    enum Radius {
        static let card: CGFloat = 14
        static let sheet: CGFloat = 20
        static let control: CGFloat = 12
        static let pill: CGFloat = 7
    }

    /// Every tappable element is at least this tall — the audience is business
    /// owners in a hurry, often using the app standing up.
    static let minTouchTarget: CGFloat = 44

    // MARK: Typography (brand font with system fallback)

    static func font(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if brandFontAvailable {
            return Font.custom(BrandConfiguration.current.fontFamily, size: size).weight(weight)
        }
        return .system(size: size, weight: weight)
    }

    /// Case numbers, money and dates. Tabular figures are not decoration here:
    /// a CNJ number is 20 digits and the client will compare it, character by
    /// character, against an e-mail from their accountant.
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
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

// MARK: - Button styles

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(16, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Theme.primary.opacity(configuration.isPressed ? 0.85 : 1))
            .foregroundStyle(Theme.onBrand)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .opacity(isEnabled ? 1 : 0.45)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(15, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Theme.fill.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundStyle(Theme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1))
    }
}

/// The one green thing in the app. It is deliberately not the primary style:
/// leaving for WhatsApp is an exit, never the main action on a screen.
struct WhatsAppButtonStyle: ButtonStyle {
    static let green = Color(red: 27 / 255, green: 140 / 255, blue: 90 / 255)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(15, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Self.green.opacity(configuration.isPressed ? 0.12 : 0.07))
            .foregroundStyle(Self.green)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Self.green.opacity(0.4), lineWidth: 1))
    }
}

// MARK: - Surfaces

struct CardBackground: ViewModifier {
    var padding: CGFloat = Theme.Space.card

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            .shadow(color: Theme.primary.opacity(0.06), radius: 8, y: 3)
    }
}

extension View {
    func card(padding: CGFloat = Theme.Space.card) -> some View {
        modifier(CardBackground(padding: padding))
    }

    func sideMargin() -> some View {
        padding(.horizontal, Theme.Space.side)
    }
}
